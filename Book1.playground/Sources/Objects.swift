import simd

public enum Material {
	case lambertian
	case metal(fuzz: Float)
	case dialectric(indexOfRefraction: Float)
	
	func lightResponse(passingRay: Ray, normal: Vector, surfaceIntersection: Vector, colorReflectivity: Color, randomInteriorPoint: Vector) -> HitResponse? {
		
		let length = distance(passingRay.origin, surfaceIntersection)
		let reflected = vector_reflect(passingRay.direction, normal)
		
		switch self {
			
		case .lambertian:
			let nextDirection = normal + randomInteriorPoint
			
			return .bounce(distance: length,
			               ray: Ray(origin: surfaceIntersection, direction: nextDirection),
			               colorReflectivity: colorReflectivity)
			
		case let .metal(fuzz):
			let nextDirection = reflected + min(fuzz, 1) * randomInteriorPoint
			
			guard 0 < dot(nextDirection, normal) else { return nil }
				
			return .bounce(distance: length,
						   ray: Ray(origin: surfaceIntersection, direction: nextDirection),
						   colorReflectivity: colorReflectivity)
			
		case let .dialectric(indexOfRefraction):
			let attenuation = Color.white()
			var outwardNormal = normal
			var nRatio = indexOfRefraction
			var cosine: Float
			
			if 0 < dot(passingRay.direction, normal) {
				cosine = indexOfRefraction * dot(passingRay.direction, normal) / vector_length(passingRay.direction)
			}
			else {
				outwardNormal = -1 * normal
				nRatio = 1 / indexOfRefraction
				cosine = -1 * dot(passingRay.direction, normal) / vector_length(passingRay.direction)
			}
			
			let uv = vector_fast_normalize(passingRay.direction)
			let dt = dot(uv, outwardNormal)
			let discriminant = 1 - (nRatio * nRatio * (1 - dt * dt))
			
			if 0 < discriminant {
				let reflectionProbability = schlick(cosine: cosine, indexOfRefraction: indexOfRefraction)
				
				if (reflectionProbability < drand()) {
					let refracted = (nRatio * (passingRay.direction - normal * dt)) - (normal * sqrt(discriminant))
					
					return .bounce(distance: length,
					               ray: Ray(origin: surfaceIntersection, direction: refracted),
					               colorReflectivity: attenuation)
				}
			}
			
			return .bounce(distance: length,
			               ray: Ray(origin: surfaceIntersection, direction: reflected),
			               colorReflectivity: attenuation)
		}
	}
}

public enum HitResponse {
	case bounce(distance: Float, ray: Ray, colorReflectivity: Color)
	case color(distance: Float, value: Color)
}

public class Hittable {
	public var material: Material = .lambertian
	
	func hitTest(passingRay: Ray, limits: FloatRange) -> HitResponse? {
		return nil
	}
	
	func randomInteriorPoint() -> Vector {
		return Vector(0)
	}
}

class Background: Hittable {
	
	let gradientDirection = Vector(x: 0, y: -1, z: 0)
	let startColor = Color(red: 0.5, green: 0.7, blue: 1)
	let endColor = Color.white()
	
	override func hitTest(passingRay: Ray, limits: FloatRange) -> HitResponse? {
		let t = (passingRay.direction.y + 1) / 2
		return .color(distance: Float.infinity, value: (t * startColor) + ((1 - t) * endColor))
	}
}

public class Sphere: Hittable {
	
	var center = Vector()
	var radius = Float()
	var colorReflectivity = Color.black()
	var randoms = [Float32](repeating: 0, count: 240_000)
	
	public convenience init(center: Vector, radius: Float, material: Material) {
		self.init(center: center, radius: radius, material: material, colorReflectivity: Color.white())
	}
	
	public init(center: Vector, radius: Float, material: Material, colorReflectivity: Color) {
		super.init()
		self.center = center
		self.radius = radius
		self.material = material
		self.colorReflectivity = colorReflectivity
		
		for i in 0 ..< 400 * 200 * 3 {
			randoms[i] = Float32(drand48())
		}
	}
	
	public override func hitTest(passingRay: Ray, limits: FloatRange) -> HitResponse? {
		
		let centerToRayOrigin = passingRay.origin - center
		
		let c = vector_length_squared(centerToRayOrigin) - radius * radius
		
		let rayOriginWithinSphere = 0 < c
		let rayDirectionTowardSphere = 0 < dot(passingRay.direction, centerToRayOrigin)
		
		guard rayOriginWithinSphere || rayDirectionTowardSphere else { return nil }
		
		let a = vector_length_squared(passingRay.direction)
		let b = dot(centerToRayOrigin, passingRay.direction)
		
		let discriminant = b * b - a * c
		
		guard 0 <= discriminant else { return nil }
		
		let partA = -1 * b / a
		let partB = sqrt(discriminant) / a
		var solution = partA - partB
		
		if !limits.contains(solution) {
			solution = partA + partB
		}
		
		guard limits.contains(solution) else { return nil }
			
		let surfaceIntersection = passingRay.origin + passingRay.direction * solution
		let normal = vector_fast_normalize(surfaceIntersection - center)

		return material.lightResponse(passingRay: passingRay,
									  normal: normal,
									  surfaceIntersection: surfaceIntersection,
									  colorReflectivity: colorReflectivity,
									  randomInteriorPoint: randomInteriorPoint())
	}
	
	override func randomInteriorPoint() -> Vector {
		var p = Vector()
		repeat {
			p = 2 * Vector(x: drand(), y: drand(), z: drand()) - Vector(1)
		} while vector_length_squared(p) >= 1
		
		return p
	}
}

public class World {
	public var objects: [Hittable] = []
	
	public init(objects objectsIn: [Hittable]) {
		objects = objectsIn
	}
}

