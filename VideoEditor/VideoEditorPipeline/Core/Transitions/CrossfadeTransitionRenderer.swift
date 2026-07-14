import CoreImage
import Foundation

class CrossfadeTransitionRenderer: TransitionRenderer {
    func render(from fromImage: CIImage, to toImage: CIImage, progress: CGFloat, canvasSize: CGSize) -> CIImage {
        let filter = CIFilter(name: "CIDissolveTransition")
        filter?.setValue(fromImage, forKey: kCIInputImageKey)
        filter?.setValue(toImage, forKey: kCIInputTargetImageKey)
        filter?.setValue(progress, forKey: kCIInputTimeKey)
        return filter?.outputImage ?? toImage.composited(over: fromImage)
    }
}
