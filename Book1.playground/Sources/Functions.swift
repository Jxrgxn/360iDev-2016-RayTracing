import Foundation
import simd

public func time(ƒ: (Void) -> Void) -> String {
	let t0 = CFAbsoluteTimeGetCurrent()
	ƒ()
	let t1 = CFAbsoluteTimeGetCurrent()
	return "time to execute: \(t1-t0) seconds"
}

public func schlick(cosine: Float, indexOfRefraction: Float) -> Float {
	var r0 = (1 - indexOfRefraction) / (1 + indexOfRefraction)
	r0 *= r0
	return r0 + ((1 - r0) * powf(1 - cosine, 5))
}

func rotate(vector: Vector, about r: Vector, byRadians θ: Float) -> Vector {
	let Uǁ = dot(r, vector) * r
	let U˻ = vector - Uǁ
	return Uǁ + cos(θ) * U˻ + sin(θ) * cross(r, vector)
}

postfix operator °
postfix func °(value: Float) -> Float {
	return value * π / 180
}

public func drand() -> Float {
	return Float(drand48())
}

public func drand2() -> Float {
	return drand()*drand()
}
