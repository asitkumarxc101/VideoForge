import CoreImage
import Foundation

class LUTHelper {
    static let shared = LUTHelper()
    
    private var tealAndOrangeData: Data?
    private var vibrantData: Data?
    private let dimension = 16
    
    private init() {
        tealAndOrangeData = generateTealAndOrangeLUT(dimension: dimension)
        vibrantData = generateVibrantLUT(dimension: dimension)
    }
    
    func makeColorCubeFilter(type: LUTType) -> CIFilter? {
        guard type != .none else { return nil }
        
        let data: Data
        switch type {
        case .tealAndOrange:
            guard let d = tealAndOrangeData else { return nil }
            data = d
        case .vibrant:
            guard let d = vibrantData else { return nil }
            data = d
        default:
            return nil
        }
        
        let filter = CIFilter(name: "CIColorCube")
        filter?.setValue(dimension, forKey: "inputCubeDimension")
        filter?.setValue(data, forKey: "inputCubeData")
        return filter
    }
    
    private func generateTealAndOrangeLUT(dimension: Int) -> Data {
        let size = dimension * dimension * dimension * 4 * MemoryLayout<Float>.size
        var cubeData = [Float](repeating: 0, count: dimension * dimension * dimension * 4)
        
        var offset = 0
        for z in 0..<dimension { // Blue
            let b = Float(z) / Float(dimension - 1)
            for y in 0..<dimension { // Green
                let g = Float(y) / Float(dimension - 1)
                for x in 0..<dimension { // Red
                    let r = Float(x) / Float(dimension - 1)
                    
                    var newR = r
                    var newG = g
                    var newB = b
                    
                    // Simple Teal & Orange formula
                    if r > 0.4 {
                        newR = r * 1.08 + 0.04
                        newG = g * 0.96 + 0.01
                        newB = b * 0.72
                    } else {
                        newR = r * 0.72
                        newG = g * 0.96 + 0.01
                        newB = b * 1.08 + 0.04
                    }
                    
                    cubeData[offset] = max(0.0, min(1.0, newR))
                    cubeData[offset + 1] = max(0.0, min(1.0, newG))
                    cubeData[offset + 2] = max(0.0, min(1.0, newB))
                    cubeData[offset + 3] = 1.0 // Alpha
                    offset += 4
                }
            }
        }
        
        return Data(bytes: &cubeData, count: size)
    }
    
    private func generateVibrantLUT(dimension: Int) -> Data {
        let size = dimension * dimension * dimension * 4 * MemoryLayout<Float>.size
        var cubeData = [Float](repeating: 0, count: dimension * dimension * dimension * 4)
        
        var offset = 0
        for z in 0..<dimension { // Blue
            let b = Float(z) / Float(dimension - 1)
            for y in 0..<dimension { // Green
                let g = Float(y) / Float(dimension - 1)
                for x in 0..<dimension { // Red
                    let r = Float(x) / Float(dimension - 1)
                    
                    let luma = 0.2126 * r + 0.7152 * g + 0.0722 * b
                    
                    let satFactor: Float = 1.4
                    var satR = luma + (r - luma) * satFactor
                    var satG = luma + (g - luma) * satFactor
                    var satB = luma + (b - luma) * satFactor
                    
                    let contrast: Float = 1.15
                    satR = 0.5 + (satR - 0.5) * contrast
                    satG = 0.5 + (satG - 0.5) * contrast
                    satB = 0.5 + (satB - 0.5) * contrast
                    
                    cubeData[offset] = max(0.0, min(1.0, satR))
                    cubeData[offset + 1] = max(0.0, min(1.0, satG))
                    cubeData[offset + 2] = max(0.0, min(1.0, satB))
                    cubeData[offset + 3] = 1.0
                    offset += 4
                }
            }
        }
        
        return Data(bytes: &cubeData, count: size)
    }
}
