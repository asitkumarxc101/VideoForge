import Foundation
import CoreMedia
import CoreGraphics
import UIKit

public enum BlendMode: String, CaseIterable, Identifiable {
    case sourceOver = "Normal"
    case multiply = "Multiply"
    case screen = "Screen"
    case overlay = "Overlay"
    
    public var id: String { self.rawValue }
}

public struct VideoOverlay: Identifiable, Equatable {
    public let id: UUID
    public var sourceURL: URL
    public var timelineTimeRange: CMTimeRange
    public var sourceTimeRange: CMTimeRange
    public var rect: CGRect // normalized screen rect (0 to 1)
    public var opacity: Float = 1.0
    public var scale: CGFloat = 1.0
    public var rotation: CGFloat = 0.0
    public var blendMode: BlendMode = .sourceOver
    public var preferredTransform: CGAffineTransform = .identity
    
    public init(id: UUID = UUID(), sourceURL: URL, timelineTimeRange: CMTimeRange, sourceTimeRange: CMTimeRange, rect: CGRect, opacity: Float = 1.0, scale: CGFloat = 1.0, rotation: CGFloat = 0.0, blendMode: BlendMode = .sourceOver) {
        self.id = id
        self.sourceURL = sourceURL
        self.timelineTimeRange = timelineTimeRange
        self.sourceTimeRange = sourceTimeRange
        self.rect = rect
        self.opacity = opacity
        self.scale = scale
        self.rotation = rotation
        self.blendMode = blendMode
    }
}

public struct StickerOverlay: Identifiable, Equatable {
    public let id: UUID
    public var systemImageName: String // SF Symbol name
    public var timelineTimeRange: CMTimeRange
    public var rect: CGRect // normalized screen rect (0 to 1)
    public var opacity: Float = 1.0
    public var scale: CGFloat = 1.0
    public var rotation: CGFloat = 0.0
    
    public init(id: UUID = UUID(), systemImageName: String, timelineTimeRange: CMTimeRange, rect: CGRect, opacity: Float = 1.0, scale: CGFloat = 1.0, rotation: CGFloat = 0.0) {
        self.id = id
        self.systemImageName = systemImageName
        self.timelineTimeRange = timelineTimeRange
        self.rect = rect
        self.opacity = opacity
        self.scale = scale
        self.rotation = rotation
    }
}

public struct TextOverlay: Identifiable, Equatable {
    public let id: UUID
    public var text: String
    public var color: UIColor
    public var fontSize: CGFloat = 32.0
    public var timelineTimeRange: CMTimeRange
    public var rect: CGRect // normalized screen rect (0 to 1)
    public var opacity: Float = 1.0
    public var scale: CGFloat = 1.0
    public var rotation: CGFloat = 0.0
    
    public init(id: UUID = UUID(), text: String, color: UIColor, fontSize: CGFloat = 32.0, timelineTimeRange: CMTimeRange, rect: CGRect, opacity: Float = 1.0, scale: CGFloat = 1.0, rotation: CGFloat = 0.0) {
        self.id = id
        self.text = text
        self.color = color
        self.fontSize = fontSize
        self.timelineTimeRange = timelineTimeRange
        self.rect = rect
        self.opacity = opacity
        self.scale = scale
        self.rotation = rotation
    }
}
