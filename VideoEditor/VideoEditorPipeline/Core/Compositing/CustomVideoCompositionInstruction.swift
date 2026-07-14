import Foundation
import AVFoundation
import CoreMedia

public class CustomVideoCompositionInstruction: NSObject, AVVideoCompositionInstructionProtocol {
    public var timeRange: CMTimeRange
    public var enablePostProcessing: Bool = true
    public var containsTweening: Bool = true
    
    // Conformance requirements
    public var requiredSourceTrackIDs: [NSValue]?
    public var passthroughTrackID: CMPersistentTrackID = kCMPersistentTrackID_Invalid
    public var requiredSourceSampleDataTrackIDs: [NSNumber] = []
    
    // Payload for editing settings
    public var activeClips: [CMPersistentTrackID: VideoClip] = [:]
    public var activeOverlays: [CMPersistentTrackID: VideoOverlay] = [:]
    public var activeStickers: [StickerOverlay] = []
    public var activeTexts: [TextOverlay] = []
    
    public var transition: Transition?
    public var transitionFromTrackID: CMPersistentTrackID?
    public var transitionToTrackID: CMPersistentTrackID?
    
    public init(timeRange: CMTimeRange, requiredSourceTrackIDs: [CMPersistentTrackID]) {
        self.timeRange = timeRange
        self.requiredSourceTrackIDs = requiredSourceTrackIDs.map { NSNumber(value: $0) }
    }
}
