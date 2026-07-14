import Foundation

class TransitionRendererFactory {
    static func renderer(for type: TransitionType) -> TransitionRenderer? {
        switch type {
        case .crossfade:
            return CrossfadeTransitionRenderer()
        case .wipeLeft:
            return WipeLeftTransitionRenderer()
        case .slideRight:
            return SlideRightTransitionRenderer()
        case .none:
            return nil
        }
    }
}
