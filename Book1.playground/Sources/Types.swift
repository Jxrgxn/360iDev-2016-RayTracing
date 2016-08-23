import Foundation
import CoreGraphics
import simd

public typealias Vector = float3
public typealias Color = float3
public typealias Degrees = Float
let π = Float(M_PI)

extension NSData {
	convenience init<T>(array: [T]) {
		let length = MemoryLayout<T>.size * array.count
		self.init(bytes: array, length: length)
	}
}

public enum SizeOptions {
	case tiny, medium, jumbo, square
	public func size() -> CGSize {
		switch self {
		case .tiny: return CGSize(width: 400, height: 200)
		case .medium: return CGSize(width: 800, height: 400)
		case .jumbo: return CGSize(width: 1600, height: 800)
		case .square: return CGSize(width: 512, height: 512)
		}
	}
}

public extension Color {
	public init(red: Float, green: Float, blue: Float) {
		self = float3(red, green, blue)
	}
	
	public static func white() -> Color {
		return Color(red: 1, green: 1, blue: 1)
	}
	public static func black() -> Color {
		return Color(red: 0, green: 0, blue: 0)
	}
}

public struct Ray {
	public var origin: Vector
	public var direction: Vector
	
	public init(origin: Vector, direction: Vector) {
		self.origin = origin
		self.direction = direction
	}
}

public typealias Coord2d = (x: Int, y: Int)

struct OrderedPairs: Collection {
	public func index(after i: Int) -> Int {
		if 0 < i && i < self.endIndex {
			return i+1
		}
		return self.endIndex
	}

	let max: Coord2d
	var pairs: [Coord2d]
	
	var startIndex: Int {
		return 0
	}
	var endIndex: Int {
		return max.x * max.y
	}
	
	init(max: Coord2d) {
		self.max = max
		
		pairs = [Coord2d](repeating: Coord2d(x:0, y:0), count: max.x * max.y)
		for i in 0 ..< max.x {
			for j in 0 ..< max.y {
				pairs[i + j*max.x] = Coord2d(x: i, y: j)
			}
		}
	}
	
	subscript(index: Int) -> Coord2d {
		let i = index % max.x
		let j = index / max.x
		
		return Coord2d(x: i, y: j)
	}
	
	func generate() -> OrderedPairGenerator {
		return OrderedPairGenerator(self)
	}
}

struct OrderedPairGenerator: IteratorProtocol {
	let pairs: OrderedPairs
	var current = Coord2d(-1, 0)
	
	init(_ pairsIn: OrderedPairs) {
		self.pairs = pairsIn
	}
	
	mutating func next() -> Coord2d? {
		current.x += 1
		if pairs.max.x <= current.x {
			current.x = 0
			current.y += 1
			if pairs.max.y <= current.y {
				return nil
			}
		}
		return current
	}
}

public struct FloatRange {
	var min: Float
	var max: Float
	
	func contains(_ test: Float) -> Bool {
		return (self.min <= test) && (test <= self.max)
	}
}
