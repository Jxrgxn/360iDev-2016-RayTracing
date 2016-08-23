let littleOrb = Sphere(center: Vector(x: 0, y:   0,   z:0), radius: 0.5, material: .lambertian, colorReflectivity: Color(red: 0.8, green: 0.3, blue: 0.3))
let giantOrb  = Sphere(center: Vector(x: 0, y:-100.5, z:0), radius: 100, material: .lambertian, colorReflectivity: Color(red: 0.8, green: 0.8, blue: 0))
//let righty    = Sphere(center: Vector(x: 1, y:   0,   z:0), radius: -0.5, material: .dialectric(indexOfRefraction: 1.4))
let righty    = Sphere(center: Vector(x: 1, y:   0,   z:0), radius: 0.5, material: .metal(fuzz: 0.2), colorReflectivity: Color(0.8,0.8,0))
let lefty     = Sphere(center: Vector(x:-1, y:   0,   z:0), radius: 0.5, material: .metal(fuzz: 0),   colorReflectivity: Color(0.8))
//let olYellow  = Sphere(center: Vector(x:-0.4, y:0.4,z:0.5), radius:0.05, material: .none, colorReflectivity: Color(red: 1, green:1, blue:0.6))


let world = World(objects: [lefty, littleOrb, righty, giantOrb])

let camera = Camera(world: world, location: Vector(0,0,2), aimedAt: Vector(0), widthAngle: 90, upVector: Vector(0,1,0), screenSize: SizeOptions.medium.size())

time {
	camera.scan()
}

camera.snapshot()

