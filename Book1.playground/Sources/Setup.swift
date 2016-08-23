import Darwin
import simd

public func createObjects() -> [Sphere] {
	var objects: [Sphere] = []
	
	objects.append(Sphere(center: Vector( 0,-1000, 0), radius: 1000, material: .lambertian,     colorReflectivity: Color(0.7, 0.7, 0.7)))
	objects.append(Sphere(center: Vector(-4,    1, 0), radius:    1, material: .lambertian,     colorReflectivity: Color(0.8, 0.4, 0.2)))
	objects.append(Sphere(center: Vector( 4,    1, 0), radius:    1, material: .metal(fuzz: 0), colorReflectivity: Color(0.7, 0.6, 0.5)))
	objects.append(Sphere(center: Vector( 0,    1, 0), radius:    1, material: .dialectric(indexOfRefraction: 1.5)))
	
	// change this to "true" to get all the little orbs also
	if true {
		for a in -11 ..< 11 {
			for b in -11 ..< 11 {
				
				let center = Vector(Float(a) + 0.9 * drand(), 0.2, Float(b) + 0.9 * drand())
				
				if 0.9 < length(center - Vector(4,0.2,0)) {
					switch drand() {
					case 0..<0.8:
						objects.append(Sphere(center: center, radius: 0.2, material: .lambertian,
											  colorReflectivity: Color(drand2(), drand2(), drand2())))
					case 0.8..<0.95:
						objects.append(Sphere(center: center, radius: 0.2, material: .metal(fuzz: 0.5 * drand()),
											  colorReflectivity: 0.5 * (Color.white() + Color(drand(), drand(), drand()))))
					default:
						objects.append(Sphere(center: center, radius: 0.2, material: .dialectric(indexOfRefraction: 1.5)))
					}
				}
			}
		}
	}
	
	return objects
}
