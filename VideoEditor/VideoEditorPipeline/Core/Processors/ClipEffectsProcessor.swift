import CoreImage
import Foundation

class ClipEffectsProcessor: ClipFrameProcessing {
    func process(_ image: CIImage, clip: VideoClip, canvasSize: CGSize) -> CIImage {
        var orientedImage = image
        if !clip.preferredTransform.isIdentity {
            orientedImage = image.transformed(by: clip.preferredTransform)
            let origin = orientedImage.extent.origin
            orientedImage = orientedImage.transformed(by: CGAffineTransform(translationX: -origin.x, y: -origin.y))
        }
        
        let extent = orientedImage.extent
        
        // 1. Apply Crop
        let cropRect = CGRect(
            x: extent.origin.x + clip.crop.x * extent.width,
            y: extent.origin.y + clip.crop.y * extent.height,
            width: clip.crop.width * extent.width,
            height: clip.crop.height * extent.height
        )
        var processed = orientedImage.cropped(to: cropRect)
        
        // Move to origin (0,0) before scaling
        let moveOrigin = CGAffineTransform(translationX: -processed.extent.origin.x, y: -processed.extent.origin.y)
        processed = processed.transformed(by: moveOrigin)
        
        // Base scale: aspect fit to canvas size
        let scaleX = canvasSize.width / processed.extent.width
        let scaleY = canvasSize.height / processed.extent.height
        let fitScale = min(scaleX, scaleY)
        
        let fittedWidth = processed.extent.width * fitScale
        let fittedHeight = processed.extent.height * fitScale
        
        let offsetX = (canvasSize.width - fittedWidth) / 2.0
        let offsetY = (canvasSize.height - fittedHeight) / 2.0
        
        processed = processed.transformed(by: CGAffineTransform(scaleX: fitScale, y: fitScale))
        processed = processed.transformed(by: CGAffineTransform(translationX: offsetX, y: offsetY))
        
        // 2. Custom User Transforms (Scale, Rotate, Translate) centered on screen
        let canvasCenter = CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)
        var t = CGAffineTransform.identity
        t = t.translatedBy(x: -canvasCenter.x, y: -canvasCenter.y)
        t = t.scaledBy(x: clip.transform.scale, y: clip.transform.scale)
        t = t.rotated(by: clip.transform.rotation)
        t = t.translatedBy(x: canvasCenter.x + clip.transform.translateX, y: canvasCenter.y + clip.transform.translateY)
        
        processed = processed.transformed(by: t)
        
        // 3. Color Controls (Brightness, Contrast, Saturation)
        let colorFilter = CIFilter(name: "CIColorControls")
        colorFilter?.setValue(processed, forKey: kCIInputImageKey)
        colorFilter?.setValue(clip.colorAdjustments.brightness, forKey: kCIInputBrightnessKey)
        colorFilter?.setValue(clip.colorAdjustments.contrast, forKey: kCIInputContrastKey)
        colorFilter?.setValue(clip.colorAdjustments.saturation, forKey: kCIInputSaturationKey)
        if let colorOutput = colorFilter?.outputImage {
            processed = colorOutput
        }
        
        // 4. Exposure
        let exposureFilter = CIFilter(name: "CIExposureAdjust")
        exposureFilter?.setValue(processed, forKey: kCIInputImageKey)
        exposureFilter?.setValue(clip.colorAdjustments.exposure, forKey: kCIInputEVKey)
        if let exposureOutput = exposureFilter?.outputImage {
            processed = exposureOutput
        }
        
        // 5. Special Core Image Filters
        switch clip.activeFilter {
        case .sepia:
            let sepia = CIFilter(name: "CISepiaTone")
            sepia?.setValue(processed, forKey: kCIInputImageKey)
            sepia?.setValue(0.8, forKey: kCIInputIntensityKey)
            processed = sepia?.outputImage ?? processed
            
        case .gaussianBlur:
            let blur = CIFilter(name: "CIGaussianBlur")
            blur?.setValue(processed, forKey: kCIInputImageKey)
            blur?.setValue(12.0, forKey: kCIInputRadiusKey)
            // Gaussian blur extends boundaries; crop back to canvas size
            processed = blur?.outputImage?.cropped(to: CGRect(origin: .zero, size: canvasSize)) ?? processed
            
        case .vignette:
            let vignette = CIFilter(name: "CIVignette")
            vignette?.setValue(processed, forKey: kCIInputImageKey)
            vignette?.setValue(1.0, forKey: kCIInputIntensityKey)
            vignette?.setValue(15.0, forKey: kCIInputRadiusKey)
            processed = vignette?.outputImage ?? processed
            
        case .none:
            break
        }
        
        // 6. LUT (CIColorCube)
        if let lutFilter = LUTHelper.shared.makeColorCubeFilter(type: clip.activeLUT) {
            lutFilter.setValue(processed, forKey: kCIInputImageKey)
            processed = lutFilter.outputImage ?? processed
        }
        
        // 7. Opacity
        if clip.transform.opacity < 1.0 {
            let opacityFilter = CIFilter(name: "CIColorMatrix")
            opacityFilter?.setValue(processed, forKey: kCIInputImageKey)
            opacityFilter?.setValue(CIVector(x: 0, y: 0, z: 0, w: CGFloat(clip.transform.opacity)), forKey: "inputAVector")
            processed = opacityFilter?.outputImage ?? processed
        }
        
        return processed.cropped(to: CGRect(origin: .zero, size: canvasSize))
    }
}
