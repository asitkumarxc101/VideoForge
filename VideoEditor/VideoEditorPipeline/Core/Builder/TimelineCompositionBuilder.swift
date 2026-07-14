import Foundation
import AVFoundation
import CoreMedia
import CoreGraphics

public class TimelineCompositionBuilder {
    public static let shared = TimelineCompositionBuilder()
    
    private init() {}
    
    public struct CompositionResult {
        public let composition: AVComposition
        public let videoComposition: AVVideoComposition
        public let audioMix: AVAudioMix?
    }
    
    public func buildComposition(from timeline: Timeline) async throws -> CompositionResult {
        let composition = AVMutableComposition()
        var mutableTimeline = timeline // Local mutable copy to store loaded transforms
        
        // 1. Create primary alternating video tracks for main timeline clips (audio created on-demand)
        guard let compVideoTrack1 = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid),
              let compVideoTrack2 = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid) else {
            throw NSError(domain: "TimelineCompositionBuilder", code: 101, userInfo: [NSLocalizedDescriptionKey: "Failed to create main video tracks in AVComposition"])
        }
        
        var compAudioTrack1: AVMutableCompositionTrack?
        var compAudioTrack2: AVMutableCompositionTrack?
        
        var audioParametersList: [AVMutableAudioMixInputParameters] = []
        
        // Insert main video clips into composition using alternating track layout to support overlaps
        for (index, clip) in mutableTimeline.videoClips.enumerated() {
            let asset = AVURLAsset(url: clip.sourceURL)
            // Modern Async API to load tracks
            guard let sourceVideoTrack = try await asset.loadTracks(withMediaType: .video).first else { continue }
            
            // Load and cache track preferredTransform to resolve rotation matrix issues
            let preferredTransform = try await sourceVideoTrack.load(.preferredTransform)
            mutableTimeline.videoClips[index].preferredTransform = preferredTransform
            
            // Calculate adjusted timeline and source time ranges to account for transition overlaps
            var adjustedTimelineStart = clip.timelineTimeRange.start
            var adjustedTimelineDuration = clip.timelineTimeRange.duration
            var adjustedSourceStart = clip.sourceTimeRange.start
            var adjustedSourceDuration = clip.sourceTimeRange.duration
            
            // Check transition at clip start
            if let trans = mutableTimeline.transitions.first(where: { CMTimeCompare($0.atTime, clip.timelineTimeRange.start) == 0 }) {
                let halfD = CMTimeMultiplyByFloat64(trans.duration, multiplier: 0.5)
                adjustedTimelineStart = clip.timelineTimeRange.start - halfD
                adjustedTimelineDuration = clip.timelineTimeRange.duration + halfD
                
                let newSrcStart = clip.sourceTimeRange.start - halfD
                if newSrcStart.seconds >= 0 {
                    adjustedSourceStart = newSrcStart
                    adjustedSourceDuration = clip.sourceTimeRange.duration + halfD
                }
            }
            
            // Check transition at clip end
            if let trans = mutableTimeline.transitions.first(where: { CMTimeCompare($0.atTime, clip.timelineTimeRange.end) == 0 }) {
                let halfD = CMTimeMultiplyByFloat64(trans.duration, multiplier: 0.5)
                adjustedTimelineDuration = adjustedTimelineDuration + halfD
                adjustedSourceDuration = adjustedSourceDuration + halfD
            }
            
            let adjustedTimelineRange = CMTimeRange(start: adjustedTimelineStart, duration: adjustedTimelineDuration)
            let adjustedSourceRange = CMTimeRange(start: adjustedSourceStart, duration: adjustedSourceDuration)
            
            // Alternate tracks
            let trackIndex = index % 2
            let activeVideoTrack = (trackIndex == 0) ? compVideoTrack1 : compVideoTrack2
            
            // Insert video segment
            do {
                try activeVideoTrack.insertTimeRange(adjustedSourceRange, of: sourceVideoTrack, at: adjustedTimelineRange.start)
            } catch {
                print("Error inserting video track at clip \(index): \(error)")
            }
            
            // Insert audio segment if present
            if let sourceAudioTrack = try await asset.loadTracks(withMediaType: .audio).first {
                let activeAudioTrack: AVMutableCompositionTrack
                if trackIndex == 0 {
                    if compAudioTrack1 == nil {
                        compAudioTrack1 = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
                    }
                    activeAudioTrack = compAudioTrack1!
                } else {
                    if compAudioTrack2 == nil {
                        compAudioTrack2 = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
                    }
                    activeAudioTrack = compAudioTrack2!
                }
                
                do {
                    try activeAudioTrack.insertTimeRange(adjustedSourceRange, of: sourceAudioTrack, at: adjustedTimelineRange.start)
                } catch {
                    print("Error inserting audio track at clip \(index): \(error)")
                }
            }
        }
        
        // 2. Setup Video Overlays (each gets its own composition track)
        var overlayTrackIDs: [UUID: CMPersistentTrackID] = [:]
        for (overlayIndex, overlay) in mutableTimeline.videoOverlays.enumerated() {
            let asset = AVURLAsset(url: overlay.sourceURL)
            // Modern Async API to load tracks
            guard let sourceVideoTrack = try await asset.loadTracks(withMediaType: .video).first else { continue }
            
            // Load and cache track preferredTransform to resolve PIP rotation matrix issues
            let preferredTransform = try await sourceVideoTrack.load(.preferredTransform)
            mutableTimeline.videoOverlays[overlayIndex].preferredTransform = preferredTransform
            
            if let compOverlayVideoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid) {
                do {
                    try compOverlayVideoTrack.insertTimeRange(overlay.sourceTimeRange, of: sourceVideoTrack, at: overlay.timelineTimeRange.start)
                    overlayTrackIDs[overlay.id] = compOverlayVideoTrack.trackID
                } catch {
                    print("Error inserting overlay video track: \(error)")
                }
                
                // Add overlay audio to composition if present
                if let sourceAudioTrack = try await asset.loadTracks(withMediaType: .audio).first {
                    if let compOverlayAudioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) {
                        do {
                            try compOverlayAudioTrack.insertTimeRange(overlay.sourceTimeRange, of: sourceAudioTrack, at: overlay.timelineTimeRange.start)
                            
                            // Audio mixing parameters for overlay audio
                            let audioParams = AVMutableAudioMixInputParameters(track: compOverlayAudioTrack)
                            audioParams.setVolume(1.0, at: .zero)
                            audioParametersList.append(audioParams)
                        } catch {
                            print("Error inserting overlay audio track: \(error)")
                        }
                    }
                }
            }
        }
        
        // 3. Setup Secondary Audio Tracks
        for audioClip in mutableTimeline.audioClips {
            let asset = AVURLAsset(url: audioClip.sourceURL)
            // Modern Async API to load tracks
            guard let sourceAudioTrack = try await asset.loadTracks(withMediaType: .audio).first else { continue }
            
            if let compAudioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) {
                do {
                    try compAudioTrack.insertTimeRange(audioClip.sourceTimeRange, of: sourceAudioTrack, at: audioClip.timelineTimeRange.start)
                    
                    let audioParams = AVMutableAudioMixInputParameters(track: compAudioTrack)
                    audioParams.setVolume(audioClip.volume, at: .zero)
                    audioParametersList.append(audioParams)
                } catch {
                    print("Error inserting background audio track: \(error)")
                }
            }
        }
        
        // Add main track audio mixing parameters
        if let audioTrack1 = compAudioTrack1 {
            let audioParams1 = AVMutableAudioMixInputParameters(track: audioTrack1)
            audioParams1.setVolume(1.0, at: .zero)
            audioParametersList.append(audioParams1)
        }
        
        if let audioTrack2 = compAudioTrack2 {
            let audioParams2 = AVMutableAudioMixInputParameters(track: audioTrack2)
            audioParams2.setVolume(1.0, at: .zero)
            audioParametersList.append(audioParams2)
        }
        
        var audioMix: AVAudioMix? = nil
        if !audioParametersList.isEmpty {
            let mutableAudioMix = AVMutableAudioMix()
            mutableAudioMix.inputParameters = audioParametersList
            audioMix = mutableAudioMix
        }
        
        // 4. Build Custom Video Composition instructions by slicing timeline at boundaries
        var boundaryTimes = Set<Double>()
        boundaryTimes.insert(0.0)
        
        var maxTime: Double = 0.0
        for clip in mutableTimeline.videoClips {
            boundaryTimes.insert(clip.timelineTimeRange.start.seconds)
            boundaryTimes.insert(clip.timelineTimeRange.end.seconds)
            maxTime = max(maxTime, clip.timelineTimeRange.end.seconds)
        }
        
        for trans in mutableTimeline.transitions {
            let halfD = trans.duration.seconds / 2.0
            boundaryTimes.insert(max(0.0, trans.atTime.seconds - halfD))
            boundaryTimes.insert(trans.atTime.seconds + halfD)
        }
        
        for overlay in mutableTimeline.videoOverlays {
            boundaryTimes.insert(overlay.timelineTimeRange.start.seconds)
            boundaryTimes.insert(overlay.timelineTimeRange.end.seconds)
            maxTime = max(maxTime, overlay.timelineTimeRange.end.seconds)
        }
        
        for sticker in mutableTimeline.stickerOverlays {
            boundaryTimes.insert(sticker.timelineTimeRange.start.seconds)
            boundaryTimes.insert(sticker.timelineTimeRange.end.seconds)
        }
        
        for text in mutableTimeline.textOverlays {
            boundaryTimes.insert(text.timelineTimeRange.start.seconds)
            boundaryTimes.insert(text.timelineTimeRange.end.seconds)
        }
        
        let sortedTimes = boundaryTimes.filter { $0 <= maxTime }.sorted()
        var videoInstructions: [AVVideoCompositionInstructionProtocol] = []
        
        for i in 0..<(sortedTimes.count - 1) {
            let startSec = sortedTimes[i]
            let endSec = sortedTimes[i+1]
            
            if endSec - startSec < 0.01 { continue }
            
            let sliceRange = CMTimeRange(
                start: CMTime(seconds: startSec, preferredTimescale: 600),
                end: CMTime(seconds: endSec, preferredTimescale: 600)
            )
            
            let midTime = CMTime(seconds: (startSec + endSec) / 2.0, preferredTimescale: 600)
            
            var activeClips: [CMPersistentTrackID: VideoClip] = [:]
            var requiredTrackIDs: [CMPersistentTrackID] = []
            
            var transition: Transition? = nil
            var fromTrackID: CMPersistentTrackID? = nil
            var toTrackID: CMPersistentTrackID? = nil
            
            // Check if transition is active at this slice midTime
            let activeTransition = mutableTimeline.transitions.first { trans in
                let halfD = trans.duration.seconds / 2.0
                let start = trans.atTime.seconds - halfD
                let end = trans.atTime.seconds + halfD
                return midTime.seconds >= start && midTime.seconds < end
            }
            
            if let trans = activeTransition {
                transition = trans
                
                // Find clip indices adjacent to transition anchor time
                let clipAIndex = mutableTimeline.videoClips.firstIndex(where: { CMTimeCompare($0.timelineTimeRange.end, trans.atTime) == 0 })
                let clipBIndex = mutableTimeline.videoClips.firstIndex(where: { CMTimeCompare($0.timelineTimeRange.start, trans.atTime) == 0 })
                
                if let idxA = clipAIndex, let idxB = clipBIndex {
                    let clipA = mutableTimeline.videoClips[idxA]
                    let clipB = mutableTimeline.videoClips[idxB]
                    
                    let trackIDA = (idxA % 2 == 0) ? compVideoTrack1.trackID : compVideoTrack2.trackID
                    let trackIDB = (idxB % 2 == 0) ? compVideoTrack1.trackID : compVideoTrack2.trackID
                    
                    activeClips[trackIDA] = clipA
                    activeClips[trackIDB] = clipB
                    
                    fromTrackID = trackIDA
                    toTrackID = trackIDB
                    
                    requiredTrackIDs.append(trackIDA)
                    requiredTrackIDs.append(trackIDB)
                }
            } else {
                // No transition, find single active clip
                let activeClipIndex = mutableTimeline.videoClips.firstIndex { clip in
                    midTime.seconds >= clip.timelineTimeRange.start.seconds &&
                    midTime.seconds < clip.timelineTimeRange.end.seconds
                }
                
                if let idx = activeClipIndex {
                    let clip = mutableTimeline.videoClips[idx]
                    let trackID = (idx % 2 == 0) ? compVideoTrack1.trackID : compVideoTrack2.trackID
                    
                    activeClips[trackID] = clip
                    requiredTrackIDs.append(trackID)
                }
            }
            
            // Video Overlays
            var activeOverlays: [CMPersistentTrackID: VideoOverlay] = [:]
            for overlay in mutableTimeline.videoOverlays {
                if midTime.seconds >= overlay.timelineTimeRange.start.seconds &&
                   midTime.seconds < overlay.timelineTimeRange.end.seconds {
                    if let trackID = overlayTrackIDs[overlay.id] {
                        activeOverlays[trackID] = overlay
                        requiredTrackIDs.append(trackID)
                    }
                }
            }
            
            // Stickers
            let activeStickers = mutableTimeline.stickerOverlays.filter { sticker in
                midTime.seconds >= sticker.timelineTimeRange.start.seconds &&
                midTime.seconds < sticker.timelineTimeRange.end.seconds
            }
            
            // Texts
            let activeTexts = mutableTimeline.textOverlays.filter { text in
                midTime.seconds >= text.timelineTimeRange.start.seconds &&
                midTime.seconds < text.timelineTimeRange.end.seconds
            }
            
            if !requiredTrackIDs.isEmpty || !activeStickers.isEmpty || !activeTexts.isEmpty {
                let instruction = CustomVideoCompositionInstruction(timeRange: sliceRange, requiredSourceTrackIDs: requiredTrackIDs)
                instruction.activeClips = activeClips
                instruction.activeOverlays = activeOverlays
                instruction.activeStickers = activeStickers
                instruction.activeTexts = activeTexts
                instruction.transition = transition
                instruction.transitionFromTrackID = fromTrackID
                instruction.transitionToTrackID = toTrackID
                
                videoInstructions.append(instruction)
            }
        }
        
        // 5. Build Video Composition (Modern iOS 26+ Configuration-based initializer)
        var config = AVVideoComposition.Configuration()
        config.customVideoCompositorClass = CustomVideoCompositor.self
        config.instructions = videoInstructions
        config.frameDuration = CMTime(value: 1, timescale: CMTimeScale(mutableTimeline.fps)) // Target user-defined frame rate
        config.renderSize = mutableTimeline.size
        
        let videoComposition = AVVideoComposition(configuration: config)
        
        return CompositionResult(
            composition: composition,
            videoComposition: videoComposition,
            audioMix: audioMix
        )
    }
}
