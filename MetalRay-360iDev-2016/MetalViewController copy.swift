import MetalKit
import simd

typealias Vector = float3
typealias Color = float3

struct Sphere {
	var materialType: Int32 = 0
	var color = Color()
	var center = Vector()
	var radius: Float = 0
	var fuzz: Float = 0
	var indexOfRefraction: Float = 1
	
	init() { }
}

struct ViewInfo {
	var objectCount: Int = 0
	
	var location = Vector()
	var halfXYZ = Vector()
	var upVector = Vector()
	var vTM = Vector()
	
	var pixelPerUnitDistance: Float = 0
	var halfHeight: Float = 0
	var theta: Float = 0
	var phi: Float = 0
	
	init() { }
}

class MetalViewController: NSViewController {
	
	let size = CGSize(width: 256 + 64, height: 256) // just needs to be divisible by 8
	
	let widthAngle: Float = 5
	let viewLooksAt  = Vector()
	let viewMovesAs  = Vector(-0.1, 0, -0.02)
	var viewLocation = Vector(9, 1.5, 4)
	let viewUpVector = Vector(0, 1, 0)
	
	var objects: [Sphere] = []
	var randoms: [Float] = []
	var viewInfo = ViewInfo()
	var direction = Vector()
	var halfWidth: Float = 0
	
	var setupComplete = false
	var updatingViews = false
	var updatingMetal = false
	
	let device = MTLCreateSystemDefaultDevice()!
	var commandQueue: MTLCommandQueue!
	var computePipelineState: MTLComputePipelineState!
	
	var rayShader: MTLFunction!
	var randomBuffer, objectsBuffer: MTLBuffer!
//	var drawable: CAMetalDrawable!
	var frame: NSRect!
//	var metalView: MetalView!
	var metalView: MTKView!
	let metalViewDelegate = MetalViewDelegate()
	
	var randomOffset: [Int32]!
	
	let includeTinyOrbs = false
	let tinyOrbMultiplier = 5 // # of tiny orbs: (tOM * 2 + 1)^2
	
	override func awakeFromNib() {
		if !setupComplete {
			frame = NSRect(x: 0, y: 0, width: size.width, height: size.height)
			view.frame = frame
			
//			metalView = MetalView(frame: frame, device: device)
//			metalView.metalLayer.framebufferOnly = false
			
			metalView = MTKView(frame: frame, device: device)
			metalView.preferredFramesPerSecond = 5
			metalView.framebufferOnly = false
			metalView.drawableSize = size
			
			metalView.delegate = metalViewDelegate
			
			randomOffset = [Int32(drand48() * 10_000)]
			
			(randoms, viewInfo, objects) = setupObjects(size: size, includeTinyOrbs: true)
			
			setupView()
			setUpFunctions()
			buildPipeline()
			makeBuffers()
//			updateViewSizeDependentStuff()
			
//			DispatchQueue.main.async {
//				self.update()
//			}
			
			view.addSubview(metalView)
//
//			drawable = metalView.metalLayer.nextDrawable()!
			
			setupComplete = true
			
			let m = 32
			let threadsPerGrid = MTLSize(width: Int(self.size.width) / m, height: Int(self.size.height) / m, depth: 1)
			let threadsPerThreadgroup = MTLSize(width: m, height: m, depth: 1)
			
			metalViewDelegate.drawingBlock = { view in
				
				guard let drawable = view.currentDrawable else { return }
				
				let commandBuffer = self.commandQueue.commandBuffer()
				let computeEncoder = commandBuffer.computeCommandEncoder()
				
				computeEncoder.setBuffer(self.objectsBuffer, offset: 0, at: 0)
				computeEncoder.setBytes([self.viewInfo], length: MemoryLayout<ViewInfo>.size, at: 1)
				
				computeEncoder.setBuffer(self.randomBuffer, offset: 0, at: 2)
				computeEncoder.setBytes([self.randomOffset], length: MemoryLayout<Int32>.size, at: 3)
				
				computeEncoder.setTexture(drawable.texture, at: 0)
				
				computeEncoder.setComputePipelineState(self.computePipelineState)
				computeEncoder.dispatchThreadgroups(threadsPerGrid, threadsPerThreadgroup: threadsPerThreadgroup)
				
				computeEncoder.endEncoding()
				
				commandBuffer.present(drawable)
				commandBuffer.commit()
				
				self.viewInfo.location += self.viewMovesAs
			}
		}
	}
	
	func setupObjects(size: CGSize, includeTinyOrbs: Bool) -> ([Float], ViewInfo, [Sphere]) {
		let width = Int(size.width)
		let x = Int((Date().timeIntervalSince1970 - 1_459_319_793) * 10)
		var seed = UInt16(65535 % x)
		seed48(&seed)
		
		var viewInfo = ViewInfo()
		var objects: [Sphere] = []
		
		let randoms = drands(width * width * 3 * 2)
		
		var giantSphere = Sphere()
		giantSphere.center = Vector(0, -1000, 0)
		giantSphere.color = Color(0.7, 0.7, 0.7)
		giantSphere.radius = 1000
		giantSphere.materialType = 0
		objects.append(giantSphere)
		
		var middle = Sphere()
		middle.center = Vector(0, 1, 0)
		middle.color = Color(0.7, 0.7, 0.7)
		middle.radius = 1
		middle.materialType = 2
		middle.indexOfRefraction = 1.5
		objects.append(middle)
		
		var lefty = Sphere()
		lefty.center = Vector(-4, 1, 0)
		lefty.color = Color(0.8,0.4,0.2)
		lefty.radius = 1
		lefty.materialType = 0
		objects.append(lefty)
		
		var righty = Sphere()
		righty.center = Vector(4, 1, 0)
		righty.color = Color(0.7, 0.6, 0.5)
		righty.radius = 1
		righty.materialType = 1
		objects.append(righty)
		
		var righty2 = Sphere()
		righty2.center = Vector(0, 1, 3)
		righty2.color = Color(0.7, 0.6, 0.5)
		righty2.radius = 1
		righty2.materialType = 1
		objects.append(righty2)
		
		if includeTinyOrbs {
			for a in -tinyOrbMultiplier ..< tinyOrbMultiplier {
				for b in -tinyOrbMultiplier ..< tinyOrbMultiplier {
					
					let center = Vector(Float(a) + 0.9 * drand(), 0.2, Float(b) + 0.9 * drand())
					
					if 0.9 < length(center - Vector(4,0.2,0)) {
						var orb = Sphere()
						orb.center = center
						orb.radius = 0.2
						
						switch drand() {
						case 0..<0.8:
							orb.color = Color(drand2(), drand2(), drand2())
							orb.materialType = 0
							
						case 0.8..<0.95:
							orb.color = Color(1) + Color(drand(), drand(), drand())
							orb.materialType = 1
							orb.fuzz = 0.5 * drand()
							
						default:
							orb.materialType = 2
							orb.indexOfRefraction = 1.5
						}
						
						objects.append(orb)
					}
				}
			}
		}
		
		viewInfo.objectCount = objects.count + 1
		
		return (randoms, viewInfo, objects)
	}
	
	func setupView() {
		viewInfo.location = viewLocation
		viewInfo.upVector = viewUpVector
		
		let lineToCenterOfScreen = viewLooksAt - viewInfo.location
		direction = normalize(lineToCenterOfScreen)
		let distanceToScreen = length(lineToCenterOfScreen)
		let halfAngleDegrees = widthAngle * Float(M_PI) / 360
		let h = distanceToScreen / cos(halfAngleDegrees)
		halfWidth = h * sin(halfAngleDegrees)
		
		viewInfo.halfHeight = halfWidth * Float(size.height) / Float(size.width)
		viewInfo.pixelPerUnitDistance = Float(size.width) / (2 * halfWidth)
		viewInfo.halfXYZ = float3(halfWidth, 0, 1)
		
		let vParallel = dot(direction, viewInfo.upVector) * viewInfo.upVector
		let vPerpendicular = direction - vParallel
		
		viewInfo.theta = atan(vPerpendicular.x / vPerpendicular.z)
		viewInfo.phi = acos(length(vPerpendicular) / length(direction))
		viewInfo.vTM = normalize(cross(vPerpendicular, direction))
		
		viewLocation += viewMovesAs
		//	print("💚 View set up!")
	}
	
	func setUpFunctions() {
		guard
			let library = device.newDefaultLibrary(),
			let shader = library.newFunction(withName: "rayShader") else {
				print("💔 Kernel file not found."); abort()
		}
		
		rayShader = shader
		
		print("💚 Functions set up!")
	}
	
	func buildPipeline() {
		commandQueue = device.newCommandQueue()
		
		do {
			computePipelineState = try device.newComputePipelineState(with: rayShader)
		}
		catch {
			print("💔 Unable to create render pipeline state."); abort()
		}
		
		print("   maxTotalThreadsPerThreadgroup: \(computePipelineState.self.maxTotalThreadsPerThreadgroup)")
		print("   threadExecutionWidth: \(computePipelineState.self.threadExecutionWidth)")
		
		print("💚 Pipeline set up!")
	}
	
	func makeBuffers() {
		objectsBuffer = device.newBuffer(withBytes: &objects,
		                                 length: viewInfo.objectCount * MemoryLayout<Sphere>.size,
		                                 options: MTLResourceOptions())
		
		randomBuffer = device.newBuffer(withBytes: &randoms,
		                                length: randoms.count * MemoryLayout<Float>.size,
		                                options: MTLResourceOptions())
		
		print("💚 Buffers set up!")
	}
	
	func updateViewSizeDependentStuff() {
		repeat {
			usleep(150_000)
		} while updatingMetal == true
		
		updatingViews = true
		
		viewInfo.halfHeight = halfWidth * Float(view.frame.size.height) / Float(view.frame.size.width)
		viewInfo.pixelPerUnitDistance = Float(view.frame.size.width) / (2 * halfWidth)
		viewInfo.halfXYZ = float3(halfWidth, 0, 1)
		
		let vParallel = dot(direction, viewInfo.upVector) * viewInfo.upVector
		let vPerpendicular = direction - vParallel
		
		viewInfo.theta = atan(vPerpendicular.x / vPerpendicular.z)
		viewInfo.phi = acos(length(vPerpendicular) / length(direction))
		viewInfo.vTM = normalize(cross(vPerpendicular, direction))
		
//		for subview in view.subviews {
//			subview.removeFromSuperview()
//		}
		
//		metalView = MetalView(frame: frame, device: device)
//		metalView.metalLayer.framebufferOnly = false
//		metalView.metalLayer.drawableSize = size
		
//		self.view.addSubview(metalView)
//		drawable = metalView.metalLayer.nextDrawable()!
		
//		self.threadgroupSizes = self.pipeline.threadgroupSizesForDrawableSize(metalView.metalLayer.drawableSize)
		
		updatingViews = false
	}

//	func update() {
//		guard let drawable = metalView.metalLayer.nextDrawable() else {
//			return
//		}
//		
//		while true {
//			self.updatingMetal = true
//			
//			if !self.updatingViews {
//				
//				let commandBuffer = commandQueue.commandBuffer()
//				let computeEncoder = commandBuffer.computeCommandEncoder()
//
//				computeEncoder.setBuffer(objectsBuffer, offset: 0, at: 0)
//				computeEncoder.setBytes([viewInfo], length: MemoryLayout<ViewInfo>.size, at: 1)
//				
//				computeEncoder.setBuffer(randomBuffer, offset: 0, at: 2)
//				computeEncoder.setBytes([randomOffset], length: MemoryLayout<Int32>.size, at: 3)
//				
////				print("\(drawable.texture)")
//				computeEncoder.setTexture(drawable.texture, at: 0)
//				
//				computeEncoder.setComputePipelineState(computePipelineState)
//				
//				let m = 32
//				
//				computeEncoder.dispatchThreadgroups(
//					MTLSize(width: Int(self.size.width) / m, height: Int(self.size.height) / m, depth: 1),
//					threadsPerThreadgroup: MTLSize(width: m, height: m, depth: 1))
//
//				computeEncoder.endEncoding()
//				
//				commandBuffer.present(drawable)
//				commandBuffer.commit()
//				
//				self.updatingMetal = false
//				self.waitForBuffer(commandBuffer)
//				
//				DispatchQueue.main.async {
//					self.view.setNeedsDisplay(self.view.bounds)
//				}
//				
//				self.viewInfo.location += self.viewMovesAs
//			}
//		}
//	}
//	
//	func waitForBuffer(_ buffer: MTLCommandBuffer) {
//		var done = true
//		repeat {
//			usleep(100_000)
//			done = (MTLCommandBufferStatus.completed == buffer.status)
//		}
//			while !done
//	}

}
