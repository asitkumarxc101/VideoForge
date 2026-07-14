import CoreImage
import Foundation
import UIKit

class TextOverlayProcessor: TextOverlayProcessing {
    func render(_ textOverlay: TextOverlay, over background: CIImage, canvasSize: CGSize) -> CIImage {
        guard let textImage = renderText(textOverlay, canvasSize: canvasSize) else {
            return background
        }
        let processedText = processOverlayTransform(
            textImage,
            rect: textOverlay.rect,
            scale: textOverlay.scale,
            rotation: textOverlay.rotation,
            opacity: textOverlay.opacity,
            canvasSize: canvasSize
        )
        return processedText.composited(over: background)
    }
    
    private func renderText(_ textOverlay: TextOverlay, canvasSize: CGSize) -> CIImage? {
        let text = textOverlay.text
        let color = textOverlay.color
        let targetSize = CGSize(width: canvasSize.width * textOverlay.rect.width,
                                height: canvasSize.height * textOverlay.rect.height)
        
        let fontSize = targetSize.height * 0.7
        
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        let img = renderer.image { context in
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .center
            
            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: fontSize),
                .foregroundColor: color,
                .paragraphStyle: paragraphStyle
            ]
            
            let rect = CGRect(origin: .zero, size: targetSize)
            text.draw(in: rect, withAttributes: attrs)
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
