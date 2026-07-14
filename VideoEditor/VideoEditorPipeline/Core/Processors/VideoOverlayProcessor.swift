import CoreImage
import Foundation

class VideoOverlayProcessor: VideoOverlayProcessing {
    func process(_ image: CIImage, overlay: VideoOverlay, canvasSize: CGSize) -> CIImage {
        var orientedImage = image
        if !overlay.preferredTransform.isIdentity {
            orientedImage = image.transformed(by: overlay.preferredTransform)
            let origin = orientedImage.extent.origin
            orientedImage = orientedImage.transformed(by: CGAffineTransform(translationX: -origin.x, y: -origin.y))
        }
        
        // Base resize to target size specified by normalized rect width/height
        let targetWidth = canvasSize.width * overlay.rect.width
        let targetHeight = canvasSize.height * overlay.rect.height
        
        let scaleX = targetWidth / orientedImage.extent.width
        let scaleY = targetHeight / orientedImage.extent.height
        let fitScale = min(scaleX, scaleY)
        
        let fittedWidth = orientedImage.extent.width * fitScale
        let fittedHeight = orientedImage.extent.height * fitScale
        
        let offsetX = (targetWidth - fittedWidth) / 2.0
        let offsetY = (targetHeight - fittedHeight) / 2.0
        
        var processed = orientedImage.transformed(by: CGAffineTransform(translationX: -orientedImage.extent.origin.x, y: -orientedImage.extent.origin.y))
        processed = processed.transformed(by: CGAffineTransform(scaleX: fitScale, y: fitScale))
        processed = processed.transformed(by: CGAffineTransform(translationX: offsetX, y: offsetY))
        
        // Position overlay center, scale, rotate about center of overlay
        let overlayCenter = CGPoint(
            x: canvasSize.width * overlay.rect.origin.x + targetWidth / 2,
            y: canvasSize.height * overlay.rect.origin.y + targetHeight / 2
        )
        
        var t = CGAffineTransform.identity
        t = t.translatedBy(x: -targetWidth / 2, y: -targetHeight / 2)
        t = t.scaledBy(x: overlay.scale, y: overlay.scale)
        t = t.rotated(by: overlay.rotation)
        t = t.translatedBy(x: overlayCenter.x, y: overlayCenter.y)
        
        processed = processed.transformed(by: t)
        
        // Opacity
        if overlay.opacity < 1.0 {
            let opacityFilter = CIFilter(name: "CIColorMatrix")
            opacityFilter?.setValue(processed, forKey: kCIInputImageKey)
            opacityFilter?.setValue(CIVector(x: 0, y: 0, z: 0, w: CGFloat(overlay.opacity)), forKey: "inputAVector")
            processed = opacityFilter?.outputImage ?? processed
        }
        
        return processed
    }
}
