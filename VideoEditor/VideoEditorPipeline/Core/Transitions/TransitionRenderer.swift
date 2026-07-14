import CoreImage
import Foundation

protocol TransitionRenderer {
    func render(from fromImage: CIImage, to toImage: CIImage, progress: CGFloat, canvasSize: CGSize) -> CIImage
}
