import UIKit
import Accelerate
import simd

public class Camera {
	
	struct Screen { // this is a notion internal to the camera
		var width, height: Int
		var aspectRatio: Float
		init(width: Int, height: Int) {
			self.width = width
			self.height = height
			self.aspectRatio = Float(width) / Float(height)
		}
	}
	
	var location, upVector, aimedAt: Vector
	var world: World
	var s: Screen
	
	let width, height: Int
	var halfHeight: Float = 0
	var pixelPerUnitDistance: Float = 0
	var widthAngle: Float
	
	var θ: Float = 0
	var φ: Float = 0
	var v™ = Vector()
	var halfXYZ = Vector()
	var φRotationRequired: Bool = true
	
	var pixels: [Color] = []
	
	
	public init(world: World, location: Vector, aimedAt: Vector, widthAngle: Float, upVector: Vector, screenSize: CGSize) {
		
		self.world = world
		s = Screen(width: Int(screenSize.width), height: Int(screenSize.height))
		self.upVector = upVector
		self.location = location
		self.aimedAt = aimedAt
		
		self.widthAngle = widthAngle
		
		width = Int(s.width)
		height = Int(s.height)
		
		pixels = [Color](repeating: Color.black(), count: width * height)
		
		// seed the mahem that is drand48
		let x = Int((NSDate().timeIntervalSince1970 - 1_459_319_793) * 10)
		var seed = UInt16(65535 % x)
		seed48(&seed)

		setupScene()
	}
	
	func setupScene() {
		let lineToCenterOfScreen = aimedAt - location
		let direction = vector_normalize(lineToCenterOfScreen)
		
		let distanceToScreen = length(lineToCenterOfScreen)
		let h = distanceToScreen / cosf((widthAngle / 2)°)
		let halfWidth = h * sinf((widthAngle / 2)°)
		
		
		halfHeight = halfWidth * Float(s.height) / Float(s.width)
		pixelPerUnitDistance = Float(s.width) / (2 * halfWidth)
		halfXYZ = Vector(x: halfWidth, y: 0, z: 1)
		
		
		let vǁ = dot(direction, upVector) * upVector
		let v˻ = direction - vǁ
		θ = atanf(v˻.x/v˻.z)
		
		φ = acosf( length(v˻) / length(direction) )
		v™ = normalize(cross(v˻, direction))
		φRotationRequired = 0.0000001 < abs(φ)
	}
	
	public func moveLocation(by: Vector) {
		location += by
		setupScene()
	}
	
	func setPixelColor(coord: Coord2d, color: Color) {
		pixels[coord.x + (coord.y * self.width)] = color
	}
	
	func rayForPixel(x: Float, y: Float) -> Ray {
		let xIsh = (x + drand()) / pixelPerUnitDistance
		let yIsh = halfHeight - (y + drand()) / pixelPerUnitDistance
		let directionForPixelSimple = Vector(xIsh, yIsh, 0) - halfXYZ
		
		var vector = rotate(vector: directionForPixelSimple, about: upVector, byRadians: θ)
		
		if φRotationRequired {
			vector = rotate(vector: vector, about: v™, byRadians: φ)
		}
		
		return Ray(origin: location, direction: vector)
	}
	
	public func snapshot() -> UIImage {
		let bytesPerPixel = MemoryLayout<Color>.size
		let componentsPerPixel = 4
		
		let bytesPerComponents = bytesPerPixel / componentsPerPixel
		let bitsPerComponent = 8 * bytesPerComponents
		let bitsPerPixel = 8 * bytesPerPixel
		let bytesPerRow = width * bytesPerPixel
		
		let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
		let bitmapInfo = CGBitmapInfo(rawValue:
			CGImageAlphaInfo.noneSkipLast.rawValue |
			CGBitmapInfo.floatComponents.rawValue |
			CGBitmapInfo.byteOrder32Little.rawValue
		)
		
		let data = NSData(array: pixels)
		
		let providerRef = CGDataProvider(data: data)
		let cgImage = CGImage(
			width: width,
			height: height,
			bitsPerComponent: bitsPerComponent,
			bitsPerPixel: bitsPerPixel,
			bytesPerRow: bytesPerRow,
			space: rgbColorSpace,
			bitmapInfo: bitmapInfo,
			provider: providerRef!,
			decode: nil,
			shouldInterpolate: true,
			intent: CGColorRenderingIntent.defaultIntent)
		
		return UIImage(cgImage: cgImage!)
	}
	
	public func scan(blendingIterations: Int, bounceLimit: Int) {
		let background = Background()
		let limits = FloatRange(min: 0.001, max: .infinity)
		
		let pixelCoordinates = OrderedPairs(max: Coord2d(width, height))
		
		DispatchQueue.concurrentPerform(iterations: width * height) { i in
			let screenCoord = pixelCoordinates[i]
			let (x,y) = (Float(screenCoord.x), Float(screenCoord.y))
			
			var totalColor = Color.black()
			
			for _ in 0 ..< blendingIterations {
				var bounceDownCount = 0
				var rayIntercepted = false
				var bouncing = false
				var colorFactor = Color.white()
				var colorContribution = Color.black()
				
				var emittedRay = self.rayForPixel(x: x, y: y)
				
				repeat {
					bouncing = false
					
					var closestDistance = Float.infinity
					var closestResponse: HitResponse? = nil
					for object in self.world.objects {
						if let hit = object.hitTest(passingRay: emittedRay, limits: limits) {
							let thisDistance: Float
							switch hit {
							case .bounce(let d, _, _): thisDistance = d
							case .color(let d, _): thisDistance = d
							}
							if thisDistance < closestDistance {
								closestDistance = thisDistance
								closestResponse = hit
							}
						}
					}
					
					if let response = closestResponse {
						switch response {
						case let .color(_, newColor):
							colorContribution = newColor
							rayIntercepted = true
							bouncing = false
							
						case let .bounce(_, newRay, colorReflectivity):
							emittedRay = newRay
							colorFactor *= colorReflectivity
							bouncing = true
							bounceDownCount += 1
						}
					}
					
				} while bouncing && bounceDownCount < bounceLimit
				
				if !rayIntercepted && bounceDownCount < bounceLimit {
					if let backgroundHit = background.hitTest(passingRay: emittedRay, limits: limits) {
						switch backgroundHit {
						case let .color(_, newColor): colorContribution = newColor
						default: ()
						}
					}
				}
				
				totalColor += colorFactor * colorContribution
			}
			
			self.setPixelColor(coord: screenCoord, color: (1 / Float(blendingIterations)) * totalColor)
		}
	}
}

