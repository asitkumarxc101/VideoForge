import Foundation
import AVFoundation
import CoreImage
import Metal

public class CustomVideoCompositor: NSObject, AVVideoCompositing {
    
    // Required properties for AVVideoCompositing
    public var sourcePixelBufferAttributes: [String : any Sendable]? = [
        kCVPixelBufferPixelFormatTypeKey as String: [NSNumber(value: kCVPixelFormatType_32BGRA)],
        kCVPixelBufferIOSurfacePropertiesKey as String: [:] as [String: Any]
    ]
    
    public var requiredPixelBufferAttributesForRenderContext: [String : any Sendable] = [
        kCVPixelBufferPixelFormatTypeKey as String: [NSNumber(value: kCVPixelFormatType_32BGRA)],
        kCVPixelBufferIOSurfacePropertiesKey as String: [:] as [String: Any]
    ]
    
    public var supportsWideColorSourceFrames: Bool {
        return false
    }
    
    // Core Render Processors (SOLID: DIP - Rely on abstractions)
    private let clipProcessor: ClipFrameProcessing = ClipEffectsProcessor()
    private let overlayProcessor: VideoOverlayProcessing = VideoOverlayProcessor()
    private let stickerProcessor: StickerOverlayProcessing = StickerOverlayProcessor()
    private let textProcessor: TextOverlayProcessing = TextOverlayProcessor()
    
    // Render Queue
    private let renderingQueue = DispatchQueue(label: "com.videoeditor.compositor.rendering", qos: .userInteractive)
    
    // Metal-backed CIContext
    private let ciContext: CIContext = {
        if let device = MTLCreateSystemDefaultDevice() {
            return CIContext(mtlDevice: device, options: [
                .workingColorSpace: CGColorSpaceCreateDeviceRGB(),
                .useSoftwareRenderer: false
            ])
        }
        return CIContext(options: [
            .workingColorSpace: CGColorSpaceCreateDeviceRGB()
        ])
    }()
    
    public override init() {
        super.init()
    }
    
    public func renderContextChanged(_ newRenderContext: AVVideoCompositionRenderContext) {
        // Handle render context changes
    }
    
    public func cancelAllPendingVideoCompositionRequests() {
        // Cancel ongoing tasks if necessary
    }
    
    public func startRequest(_ request: AVAsynchronousVideoCompositionRequest) {
        renderingQueue.async {
            autoreleasepool {
                self.processRequest(request)
            }
        }
    }
    
    private func processRequest(_ request: AVAsynchronousVideoCompositionRequest) {
        guard let instruction = request.videoCompositionInstruction as? CustomVideoCompositionInstruction else {
            request.finish(with: NSError(domain: "CustomVideoCompositor", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid composition instruction"]))
            return
        }
        
        let canvasSize = request.renderContext.size
        
        // 1. Create transparent background image
        var finalImage = CIImage(color: CIColor.clear).cropped(to: CGRect(origin: .zero, size: canvasSize))
        
        // 2. Process primary clips (including transition if active)
        if let transition = instruction.transition,
           let fromTrackID = instruction.transitionFromTrackID,
           let toTrackID = instruction.transitionToTrackID {
            
            let fromPixelBuffer = request.sourceFrame(byTrackID: fromTrackID)
            let toPixelBuffer = request.sourceFrame(byTrackID: toTrackID)
            
            let fromClip = instruction.activeClips[fromTrackID]
            let toClip = instruction.activeClips[toTrackID]
            
            var fromImage: CIImage?
            if let fBuf = fromPixelBuffer, let fClip = fromClip {
                fromImage = clipProcessor.process(CIImage(cvPixelBuffer: fBuf), clip: fClip, canvasSize: canvasSize)
            }
            
            var toImage: CIImage?
            if let tBuf = toPixelBuffer, let tClip = toClip {
                toImage = clipProcessor.process(CIImage(cvPixelBuffer: tBuf), clip: tClip, canvasSize: canvasSize)
            }
            
            // Calculate progress of transition (0.0 to 1.0)
            let time = request.compositionTime
            let start = transition.atTime - CMTimeMultiplyByFloat64(transition.duration, multiplier: 0.5)
            let progress = CGFloat(max(0.0, min(1.0, (time - start).seconds / transition.duration.seconds)))
            
            if let fImg = fromImage, let tImg = toImage {
                // SOLID: OCP - Load the transition renderer dynamically from Factory
                if let renderer = TransitionRendererFactory.renderer(for: transition.type) {
                    finalImage = renderer.render(from: fImg, to: tImg, progress: progress, canvasSize: canvasSize)
                } else {
                    finalImage = progress < 0.5 ? fImg : tImg
                }
            } else if let fImg = fromImage {
                finalImage = fImg
            } else if let tImg = toImage {
                finalImage = tImg
            }
            
        } else {
            // Renders single clip (no transition)
            if let mainTrackID = instruction.activeClips.keys.first,
               let sourcePixelBuffer = request.sourceFrame(byTrackID: mainTrackID),
               let clip = instruction.activeClips[mainTrackID] {
                
                let sourceImage = CIImage(cvPixelBuffer: sourcePixelBuffer)
                finalImage = clipProcessor.process(sourceImage, clip: clip, canvasSize: canvasSize)
            }
        }
        
        // 3. Process video overlays
        for (trackID, overlay) in instruction.activeOverlays {
            if let overlayPixelBuffer = request.sourceFrame(byTrackID: trackID) {
                let overlayImage = CIImage(cvPixelBuffer: overlayPixelBuffer)
                let processedOverlay = overlayProcessor.process(overlayImage, overlay: overlay, canvasSize: canvasSize)
                finalImage = blendImage(processedOverlay, over: finalImage, mode: overlay.blendMode)
            }
        }
        
        // 4. Process stickers
        for sticker in instruction.activeStickers {
            finalImage = stickerProcessor.render(sticker, over: finalImage, canvasSize: canvasSize)
        }
        
        // 5. Process text
        for textOverlay in instruction.activeTexts {
            finalImage = textProcessor.render(textOverlay, over: finalImage, canvasSize: canvasSize)
        }
        
        // 6. Allocate and finish request
        guard let outputPixelBuffer = request.renderContext.newPixelBuffer() else {
            request.finish(with: NSError(domain: "CustomVideoCompositor", code: -2, userInfo: [NSLocalizedDescriptionKey: "Failed to allocate output buffer"]))
            return
        }
        
        ciContext.render(finalImage, to: outputPixelBuffer, bounds: CGRect(origin: .zero, size: canvasSize), colorSpace: CGColorSpaceCreateDeviceRGB())
        
        request.finish(withComposedPixelBuffer: CVReadOnlyPixelBuffer(unsafeBuffer: outputPixelBuffer))
    }
    
    private func blendImage(_ foreground: CIImage, over background: CIImage, mode: BlendMode) -> CIImage {
        let filterName: String
        switch mode {
        case .sourceOver:
            return foreground.composited(over: background)
        case .multiply:
            filterName = "CIMultiplyBlendMode"
        case .screen:
            filterName = "CIScreenBlendMode"
        case .overlay:
            filterName = "CIOverlayBlendMode"
        }
        
        let filter = CIFilter(name: filterName)
        filter?.setValue(foreground, forKey: kCIInputImageKey)
        filter?.setValue(background, forKey: kCIInputTargetImageKey)
        return filter?.outputImage ?? foreground.composited(over: background)
    }
}
