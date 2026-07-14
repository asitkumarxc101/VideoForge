import Foundation
import AVFoundation
import CoreGraphics
import UIKit

class MockAssetGenerator {
    static let shared = MockAssetGenerator()
    
    private init() {}
    
    // Returns paths to the test/generated files: [video1, video2, overlayVideo, video4]
    func generateAllAssetsIfNeeded(completion: @escaping (Result<[URL], Error>) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            // Define clean descriptive names for test files
            let filenames = [
                "agent_4k.mp4",
                "woodland_woods.mp4",
                "vertical_content.mp4",
                "palm_trees.mp4"
            ]
            
            var assetURLs: [URL] = []
            
            // 1. Try finding files in the main bundle resource folder
            for name in filenames {
                let baseName = (name as NSString).deletingPathExtension
                let ext = (name as NSString).pathExtension
                if let bundleURL = Bundle.main.url(forResource: baseName, withExtension: ext) {
                    assetURLs.append(bundleURL)
                }
            }
            
            // 2. If bundle URLs not fully resolved, try loading from absolute workspace folder (robust sandbox bypass for simulator)
            if assetURLs.count < filenames.count {
                let workspaceDir = "/Users/amitkumardhal/Documents/VideoEditor/VideoEditor/VideoEditor"
                var workspaceURLs: [URL] = []
                let fileManager = FileManager.default
                
                for name in filenames {
                    let path = (workspaceDir as NSString).appendingPathComponent(name)
                    if fileManager.fileExists(atPath: path) {
                        workspaceURLs.append(URL(fileURLWithPath: path))
                    }
                }
                
                if workspaceURLs.count == filenames.count {
                    assetURLs = workspaceURLs
                }
            }
            
            // 3. Fallback to generating programmatic mock video files if the test assets are not present
            if assetURLs.count < 3 {
                print("Test video files not found. Generating programmatic mock assets...")
                do {
                    let fileManager = FileManager.default
                    let tempDir = fileManager.temporaryDirectory
                    
                    let v1URL = tempDir.appendingPathComponent("mock_video1.mp4")
                    let v2URL = tempDir.appendingPathComponent("mock_video2.mp4")
                    let v3URL = tempDir.appendingPathComponent("mock_overlay.mp4")
                    
                    if fileManager.fileExists(atPath: v1URL.path) &&
                       fileManager.fileExists(atPath: v2URL.path) &&
                       fileManager.fileExists(atPath: v3URL.path) {
                        completion(.success([v1URL, v2URL, v3URL]))
                        return
                    }
                    
                    try? fileManager.removeItem(at: v1URL)
                    try? fileManager.removeItem(at: v2URL)
                    try? fileManager.removeItem(at: v3URL)
                    
                    try self.generateVideo(
                        outputURL: v1URL,
                        duration: 5.0,
                        size: CGSize(width: 1280, height: 720),
                        bgColor: UIColor.systemRed,
                        shapeType: .rotatingSquare,
                        audioFreq: 440.0
                    )
                    
                    try self.generateVideo(
                        outputURL: v2URL,
                        duration: 5.0,
                        size: CGSize(width: 1280, height: 720),
                        bgColor: UIColor.systemBlue,
                        shapeType: .bouncingCircle,
                        audioFreq: 880.0
                    )
                    
                    try self.generateVideo(
                        outputURL: v3URL,
                        duration: 3.0,
                        size: CGSize(width: 640, height: 360),
                        bgColor: UIColor.systemGreen.withAlphaComponent(0.8),
                        shapeType: .pulsingTriangle,
                        audioFreq: 660.0
                    )
                    
                    completion(.success([v1URL, v2URL, v3URL]))
                } catch {
                    completion(.failure(error))
                }
            } else {
                completion(.success(assetURLs))
            }
        }
    }
    
    enum ShapeType {
        case rotatingSquare
        case bouncingCircle
        case pulsingTriangle
    }
    
    private func generateVideo(
        outputURL: URL,
        duration: Double,
        size: CGSize,
        bgColor: UIColor,
        shapeType: ShapeType,
        audioFreq: Float
    ) throws {
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: outputURL.path) {
            try fileManager.removeItem(at: outputURL)
        }
        
        let assetWriter = try AVAssetWriter(outputURL: outputURL, fileType: .mp4)
        
        // --- Video Setup ---
        let videoSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: size.width,
            AVVideoHeightKey: size.height
        ]
        let videoInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
        let pixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: videoInput,
            sourcePixelBufferAttributes: [
                kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
            ]
        )
        
        // --- Audio Setup ---
        var channelLayout = AudioChannelLayout()
        channelLayout.mChannelLayoutTag = kAudioChannelLayoutTag_Mono
        
        let audioSettings: [String: Any] = [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVChannelLayoutKey: Data(bytes: &channelLayout, count: MemoryLayout<AudioChannelLayout>.size)
        ]
        let audioInput = AVAssetWriterInput(mediaType: .audio, outputSettings: audioSettings)
        
        // Configure inputs
        videoInput.expectsMediaDataInRealTime = false
        audioInput.expectsMediaDataInRealTime = false
        
        assetWriter.add(videoInput)
        assetWriter.add(audioInput)
        
        // Start Writing
        assetWriter.startWriting()
        assetWriter.startSession(atSourceTime: .zero)
        
        // Render Video Frames
        let fps: Int32 = 30
        let totalFrames = Int(duration * Double(fps))
        var frameCount = 0
        
        while frameCount < totalFrames {
            if videoInput.isReadyForMoreMediaData {
                let frameTime = CMTimeMake(value: Int64(frameCount), timescale: fps)
                
                var pixelBuffer: CVPixelBuffer? = nil
                let status = CVPixelBufferCreate(
                    kCFAllocatorDefault,
                    Int(size.width),
                    Int(size.height),
                    kCVPixelFormatType_32BGRA,
                    [
                        kCVPixelBufferCGImageCompatibilityKey as String: true,
                        kCVPixelBufferCGBitmapContextCompatibilityKey as String: true
                    ] as CFDictionary,
                    &pixelBuffer
                )
                
                if status == kCVReturnSuccess, let buffer = pixelBuffer {
                    CVPixelBufferLockBaseAddress(buffer, CVPixelBufferLockFlags(rawValue: 0))
                    let context = CGContext(
                        data: CVPixelBufferGetBaseAddress(buffer),
                        width: Int(size.width),
                        height: Int(size.height),
                        bitsPerComponent: 8,
                        bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
                        space: CGColorSpaceCreateDeviceRGB(),
                        bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue
                    )
                    
                    if let ctx = context {
                        ctx.setFillColor(bgColor.cgColor)
                        ctx.fill(CGRect(origin: .zero, size: size))
                        
                        ctx.saveGState()
                        ctx.translateBy(x: size.width / 2.0, y: size.height / 2.0)
                        
                        let progress = Double(frameCount) / Double(totalFrames)
                        ctx.setFillColor(UIColor.white.cgColor)
                        
                        switch shapeType {
                        case .rotatingSquare:
                            ctx.rotate(by: CGFloat(progress * 2.0 * .pi))
                            ctx.fill(CGRect(x: -60, y: -60, width: 120, height: 120))
                        case .bouncingCircle:
                            let bounceOffset = CGFloat(sin(progress * .pi * 4.0)) * 120.0
                            ctx.fillEllipse(in: CGRect(x: -60, y: -60 + bounceOffset, width: 120, height: 120))
                        case .pulsingTriangle:
                            let scale = 0.5 + CGFloat(progress * 1.5)
                            ctx.scaleBy(x: scale, y: scale)
                            let path = CGMutablePath()
                            path.move(to: CGPoint(x: 0, y: -60))
                            path.addLine(to: CGPoint(x: -60, y: 60))
                            path.addLine(to: CGPoint(x: 60, y: 60))
                            path.closeSubpath()
                            ctx.addPath(path)
                            ctx.fillPath()
                        }
                        
                        ctx.restoreGState()
                    }
                    
                    CVPixelBufferUnlockBaseAddress(buffer, CVPixelBufferLockFlags(rawValue: 0))
                    pixelBufferAdaptor.append(buffer, withPresentationTime: frameTime)
                }
                frameCount += 1
            } else {
                Thread.sleep(forTimeInterval: 0.005)
            }
        }
        videoInput.markAsFinished()
        
        // Render Audio Waveform (AAC mono sine wave)
        let sampleRate: Double = 44100.0
        let totalSamples = Int(duration * sampleRate)
        var samplesWritten = 0
        let bufferSize = 1024
        
        while samplesWritten < totalSamples {
            if audioInput.isReadyForMoreMediaData {
                let samplesRemaining = totalSamples - samplesWritten
                let chunkSamples = min(bufferSize, samplesRemaining)
                
                var blockBuffer: CMBlockBuffer? = nil
                let bufferLength = chunkSamples * MemoryLayout<Int16>.size
                
                var status = CMBlockBufferCreateWithMemoryBlock(
                    allocator: kCFAllocatorDefault,
                    memoryBlock: nil,
                    blockLength: bufferLength,
                    blockAllocator: kCFAllocatorDefault,
                    customBlockSource: nil,
                    offsetToData: 0,
                    dataLength: bufferLength,
                    flags: 0,
                    blockBufferOut: &blockBuffer
                )
                
                if status == noErr, let buffer = blockBuffer {
                    status = CMBlockBufferAssureBlockMemory(buffer)
                    if status == noErr {
                        var dataPointer: UnsafeMutablePointer<Int8>? = nil
                        status = CMBlockBufferGetDataPointer(
                            buffer,
                            atOffset: 0,
                            lengthAtOffsetOut: nil,
                            totalLengthOut: nil,
                            dataPointerOut: &dataPointer
                        )
                        
                        if status == noErr, let pointer = dataPointer {
                            let samples = pointer.withMemoryRebound(to: Int16.self, capacity: chunkSamples) { $0 }
                            
                            for i in 0..<chunkSamples {
                                let time = Double(samplesWritten + i) / sampleRate
                                let sineVal = sin(2.0 * .pi * Double(audioFreq) * time)
                                samples[i] = Int16(sineVal * 32767.0)
                            }
                            
                            var asbd = AudioStreamBasicDescription(
                                mSampleRate: sampleRate,
                                mFormatID: kAudioFormatLinearPCM,
                                mFormatFlags: kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked,
                                mBytesPerPacket: 2,
                                mFramesPerPacket: 1,
                                mBytesPerFrame: 2,
                                mChannelsPerFrame: 1,
                                mBitsPerChannel: 16,
                                mReserved: 0
                            )
                            
                            var formatDescription: CMAudioFormatDescription? = nil
                            CMAudioFormatDescriptionCreate(
                                allocator: kCFAllocatorDefault,
                                asbd: &asbd,
                                layoutSize: 0,
                                layout: nil,
                                magicCookieSize: 0,
                                magicCookie: nil,
                                extensions: nil,
                                formatDescriptionOut: &formatDescription
                            )
                            
                            if let desc = formatDescription {
                                var sampleBuffer: CMSampleBuffer? = nil
                                let pts = CMTime(value: Int64(samplesWritten), timescale: CMTimeScale(sampleRate))
                                
                                status = CMSampleBufferCreateReady(
                                    allocator: kCFAllocatorDefault,
                                    dataBuffer: buffer,
                                    formatDescription: desc,
                                    sampleCount: chunkSamples,
                                    sampleTimingEntryCount: 1,
                                    sampleTimingArray: [CMSampleTimingInfo(duration: CMTime(value: 1, timescale: CMTimeScale(sampleRate)), presentationTimeStamp: pts, decodeTimeStamp: .invalid)],
                                    sampleSizeEntryCount: 0,
                                    sampleSizeArray: [],
                                    sampleBufferOut: &sampleBuffer
                                )
                                
                                if status == noErr, let sBuffer = sampleBuffer {
                                    audioInput.append(sBuffer)
                                }
                            }
                        }
                    }
                }
                
                samplesWritten += chunkSamples
            } else {
                Thread.sleep(forTimeInterval: 0.005)
            }
        }
        
        audioInput.markAsFinished()
        
        let dispatchGroup = DispatchGroup()
        dispatchGroup.enter()
        
        assetWriter.finishWriting {
            dispatchGroup.leave()
        }
        
        dispatchGroup.wait()
    }
}
