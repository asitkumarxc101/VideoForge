import SwiftUI
import AVKit

public struct PlayerView: UIViewControllerRepresentable {
    public let player: AVPlayer
    
    public init(player: AVPlayer) {
        self.player = player
    }
    
    public func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.player = player
        controller.showsPlaybackControls = true
        controller.videoGravity = .resizeAspect
        return controller
    }
    
    public func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        uiViewController.player = player
    }
}
