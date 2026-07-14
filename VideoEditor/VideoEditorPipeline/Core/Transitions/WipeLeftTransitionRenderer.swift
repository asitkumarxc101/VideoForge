import CoreImage
import Foundation

class WipeLeftTransitionRenderer: TransitionRenderer {
    func render(from fromImage: CIImage, to toImage: CIImage, progress: CGFloat, canvasSize: CGSize) -> CIImage {
        let filter = CIFilter(name: "CIWipeTransition")
        filter?.setValue(fromImage, forKey: kCIInputImageKey)
        filter?.setValue(toImage, forKey: kCIInputTargetImageKey)
        filter?.setValue(progress, forKey: kCIInputTimeKey)
        filter?.setValue(3.14159, forKey: "inputAngle") // leftwards wipe direction
        return filter?.outputImage ?? toImage.composited(over: fromImage)
    }
}
