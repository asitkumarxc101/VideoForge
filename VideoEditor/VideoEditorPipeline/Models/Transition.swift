import Foundation
import CoreMedia

public enum TransitionType: String, CaseIterable, Identifiable {
    case none = "None"
    case crossfade = "Cross Dissolve"
    case wipeLeft = "Wipe Left"
    case slideRight = "Slide Right"
    
    public var id: String { self.rawValue }
}

public struct Transition: Identifiable, Equatable {
    public let id: UUID
    public var type: TransitionType
    public var duration: CMTime
    public var atTime: CMTime // Anchor point on the timeline (transition centered around this time)
    
    public init(id: UUID = UUID(), type: TransitionType, duration: CMTime, atTime: CMTime) {
        self.id = id
        self.type = type
        self.duration = duration
        self.atTime = atTime
    }
}
