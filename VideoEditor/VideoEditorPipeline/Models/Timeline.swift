import Foundation
import CoreGraphics

public enum CanvasResolution: String, CaseIterable, Identifiable {
    case p4kLandscape = "4K Landscape (16:9)"
    case p4kPortrait = "4K Portrait (9:16)"
    case p1080Landscape = "1080p Landscape (16:9)"
    case p1080Portrait = "1080p Portrait (9:16)"
    case p720Landscape = "720p Landscape (16:9)"
    case p720Portrait = "720p Portrait (9:16)"
    case square = "1080x1080 Square (1:1)"
    
    public var id: String { self.rawValue }
    
    public var size: CGSize {
        switch self {
        case .p4kLandscape: return CGSize(width: 3840, height: 2160)
        case .p4kPortrait: return CGSize(width: 2160, height: 3840)
        case .p1080Landscape: return CGSize(width: 1920, height: 1080)
        case .p1080Portrait: return CGSize(width: 1080, height: 1920)
        case .p720Landscape: return CGSize(width: 1280, height: 720)
        case .p720Portrait: return CGSize(width: 720, height: 1280)
        case .square: return CGSize(width: 1080, height: 1080)
        }
    }
}

public struct Timeline: Equatable {
    public var canvasResolution: CanvasResolution = .p720Landscape
    public var size: CGSize { canvasResolution.size }
    public var fps: Int = 30
    public var videoClips: [VideoClip] = []
    public var audioClips: [AudioClip] = []
    public var videoOverlays: [VideoOverlay] = []
    public var stickerOverlays: [StickerOverlay] = []
    public var textOverlays: [TextOverlay] = []
    public var transitions: [Transition] = []
    
    public init(
        canvasResolution: CanvasResolution = .p720Landscape,
        fps: Int = 30,
        videoClips: [VideoClip] = [],
        audioClips: [AudioClip] = [],
        videoOverlays: [VideoOverlay] = [],
        stickerOverlays: [StickerOverlay] = [],
        textOverlays: [TextOverlay] = [],
        transitions: [Transition] = []
    ) {
        self.canvasResolution = canvasResolution
        self.fps = fps
        self.videoClips = videoClips
        self.audioClips = audioClips
        self.videoOverlays = videoOverlays
        self.stickerOverlays = stickerOverlays
        self.textOverlays = textOverlays
        self.transitions = transitions
    }
}
