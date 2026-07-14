import CoreImage
import Foundation

class SlideRightTransitionRenderer: TransitionRenderer {
    func render(from fromImage: CIImage, to toImage: CIImage, progress: CGFloat, canvasSize: CGSize) -> CIImage {
        let tA = CGAffineTransform(translationX: progress * canvasSize.width, y: 0)
        let tB = CGAffineTransform(translationX: (progress - 1.0) * canvasSize.width, y: 0)
        let slideA = fromImage.transformed(by: tA)
        let slideB = toImage.transformed(by: tB)
        return slideB.composited(over: slideA)
    }
}
