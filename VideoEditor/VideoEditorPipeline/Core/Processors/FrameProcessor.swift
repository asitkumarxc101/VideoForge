import CoreImage
import Foundation

// MARK: - Interface Segregation Protocols

protocol ClipFrameProcessing {
    func process(_ image: CIImage, clip: VideoClip, canvasSize: CGSize) -> CIImage
}

protocol VideoOverlayProcessing {
    func process(_ image: CIImage, overlay: VideoOverlay, canvasSize: CGSize) -> CIImage
}

protocol StickerOverlayProcessing {
    func render(_ sticker: StickerOverlay, over background: CIImage, canvasSize: CGSize) -> CIImage
}

protocol TextOverlayProcessing {
    func render(_ textOverlay: TextOverlay, over background: CIImage, canvasSize: CGSize) -> CIImage
}
