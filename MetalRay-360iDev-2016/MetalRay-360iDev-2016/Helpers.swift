import MetalKit

public func drand() -> Float {
	return Float(drand48())
}

public func drand2() -> Float {
	return drand()*drand()
}

public func drands(_ count: Int) -> [Float] {
	var rands = [Float](repeating: 0, count: count)
	for i in 0 ..< count {
		rands[i] = drand()
	}
	return rands
}

public func time(_ ƒ: (Void) -> Void) {
	let t0 = CFAbsoluteTimeGetCurrent()
	ƒ()
	let t1 = CFAbsoluteTimeGetCurrent()
	print("⏱ time to execute: \(t1-t0) seconds")
}

public class MetalViewDelegate: NSObject, MTKViewDelegate {
	public var drawingBlock: (_ view: MTKView) -> Void = { _ in }
	
	public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) { }
	
	public func draw(in view: MTKView) {
		drawingBlock(view)
	}
}
