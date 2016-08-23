var objects: [Sphere]!
time {
	objects = createObjects()
}
let world = World(objects: objects)

let camera = Camera(world: world,
                    location: Vector(x: 9, y: 1.5, z: 4),
                    aimedAt:  Vector(x: 0, y: 0,   z: 0),
                    widthAngle: 5,
                    upVector: Vector(x: 0, y: 1, z: 0),
                    screenSize: SizeOptions.square.size())

time {
	camera.scan(blendingIterations: 10, bounceLimit: 20)
}

camera.snapshot()
