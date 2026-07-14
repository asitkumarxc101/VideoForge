import CoreImage
import Foundation
import UIKit
import AVFoundation

class StickerOverlayProcessor: StickerOverlayProcessing {
    func render(_ sticker: StickerOverlay, over background: CIImage, canvasSize: CGSize) -> CIImage {
        guard let stickerImage = renderSticker(sticker, canvasSize: canvasSize) else {
            return background
        }
        let processedSticker = processOverlayTransform(
            stickerImage,
            rect: sticker.rect,
            scale: sticker.scale,
            rotation: sticker.rotation,
            opacity: sticker.opacity,
            canvasSize: canvasSize
        )
        return processedSticker.composited(over: background)
    }
    
    private func renderSticker(_ sticker: StickerOverlay, canvasSize: CGSize) -> CIImage? {
        let systemImageName = sticker.systemImageName
        let targetSize = CGSize(width: canvasSize.width * sticker.rect.width,
                                height: canvasSize.height * sticker.rect.height)
        
        let config = UIImage.SymbolConfiguration(pointSize: targetSize.height * 0.8, weight: .bold)
        guard let uiImage = UIImage(systemName: systemImageName, withConfiguration: config) else {
            return nil
        }
        
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        let img = renderer.image { context in
            let aspectRect = AVMakeRect(aspectRatio: uiImage.size, insideRect: CGRect(origin: .zero, size: targetSize))
            uiImage.withTintColor(.systemYellow, renderingMode: .alwaysOriginal).draw(in: aspectRect)
        }
        
        guard let cgImage = img.cgImage else { return nil }
        return CIImage(cgImage: cgImage)
    }
    
    private func processOverlayTransform(
        _ image: CIImage,
        rect: CGRect,
        scale: CGFloat,
        rotation: CGFloat,
        opacity: Float,
        canvasSize: CGSize
    ) -> CIImage {
        let w = image.extent.width
        let h = image.extent.height
        
        let overlayCenter = CGPoint(
            x: canvasSize.width * rect.origin.x + w / 2,
            y: canvasSize.height * rect.origin.y + h / 2
        )
        
        var t = CGAffineTransform.identity
        t = t.translatedBy(x: -w / 2, y: -h / 2)
        t = t.scaledBy(x: scale, y: scale)
        t = t.rotated(by: rotation)
        t = t.translatedBy(x: overlayCenter.x, y: overlayCenter.y)
        
        var processed = image.transformed(by: t)
        
        if opacity < 1.0 {
            let opacityFilter = CIFilter(name: "CIColorMatrix")
            opacityFilter?.setValue(processed, forKey: kCIInputImageKey)
            opacityFilter?.setValue(CIVector(x: 0, y: 0, z: 0, w: CGFloat(opacity)), forKey: "inputAVector")
            processed = opacityFilter?.outputImage ?? processed
        }
        
        return processed
    }
}
