import Foundation
import CoreMedia
import CoreGraphics

public struct CropArea: Equatable {
    public var x: CGFloat = 0.0      // 0.0 to 1.0
    public var y: CGFloat = 0.0      // 0.0 to 1.0
    public var width: CGFloat = 1.0  // 0.0 to 1.0
    public var height: CGFloat = 1.0 // 0.0 to 1.0
    
    public init(x: CGFloat = 0.0, y: CGFloat = 0.0, width: CGFloat = 1.0, height: CGFloat = 1.0) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
    }
}

public struct ColorAdjustments: Equatable {
    public var brightness: Float = 0.0   // -1.0 to 1.0
    public var contrast: Float = 1.0     // 0.5 to 2.0
    public var saturation: Float = 1.0   // 0.0 to 2.0
    public var exposure: Float = 0.0     // -2.0 to 2.0
    
    public init(brightness: Float = 0.0, contrast: Float = 1.0, saturation: Float = 1.0, exposure: Float = 0.0) {
        self.brightness = brightness
        self.contrast = contrast
        self.saturation = saturation
        self.exposure = exposure
    }
}

public struct ClipTransform: Equatable {
    public var scale: CGFloat = 1.0
    public var rotation: CGFloat = 0.0 // in radians
    public var translateX: CGFloat = 0.0
    public var translateY: CGFloat = 0.0
    public var opacity: Float = 1.0    // 0.0 to 1.0
    
    public init(scale: CGFloat = 1.0, rotation: CGFloat = 0.0, translateX: CGFloat = 0.0, translateY: CGFloat = 0.0, opacity: Float = 1.0) {
        self.scale = scale
        self.rotation = rotation
        self.translateX = translateX
        self.translateY = translateY
        self.opacity = opacity
    }
}

public enum CIFilterType: String, CaseIterable, Identifiable {
    case none = "None"
    case sepia = "Sepia"
    case gaussianBlur = "Gaussian Blur"
    case vignette = "Vignette"
    
    public var id: String { self.rawValue }
}

public enum LUTType: String, CaseIterable, Identifiable {
    case none = "None"
    case tealAndOrange = "Teal & Orange"
    case vibrant = "Vibrant"
    
    public var id: String { self.rawValue }
}

public struct VideoClip: Identifiable, Equatable {
    public let id: UUID
    public var sourceURL: URL
    public var timelineTimeRange: CMTimeRange
    public var sourceTimeRange: CMTimeRange
    public var preferredTransform: CGAffineTransform = .identity
    
    // Effects & Adjustments
    public var crop: CropArea = CropArea()
    public var transform: ClipTransform = ClipTransform()
    public var colorAdjustments: ColorAdjustments = ColorAdjustments()
    public var activeFilter: CIFilterType = .none
    public var activeLUT: LUTType = .none
    
    public init(id: UUID = UUID(), sourceURL: URL, timelineTimeRange: CMTimeRange, sourceTimeRange: CMTimeRange) {
        self.id = id
        self.sourceURL = sourceURL
        self.timelineTimeRange = timelineTimeRange
        self.sourceTimeRange = sourceTimeRange
    }
}

public struct AudioClip: Identifiable, Equatable {
    public let id: UUID
    public var sourceURL: URL
    public var timelineTimeRange: CMTimeRange
    public var sourceTimeRange: CMTimeRange
    public var volume: Float = 1.0 // 0.0 to 1.0
    
    public init(id: UUID = UUID(), sourceURL: URL, timelineTimeRange: CMTimeRange, sourceTimeRange: CMTimeRange, volume: Float = 1.0) {
        self.id = id
        self.sourceURL = sourceURL
        self.timelineTimeRange = timelineTimeRange
        self.sourceTimeRange = sourceTimeRange
        self.volume = volume
    }
}
