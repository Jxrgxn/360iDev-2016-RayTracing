//
//  Vector.swift
//  schimeren
//
//  Created by Jonathan Blocksom on 12/23/14.
//  Copyright (c) 2014 GollyGee Software, Inc. All rights reserved.
//

import Foundation

public struct Vector {
    let x, y, z: Double

    public init(_ x: Double, _ y: Double, _ z: Double) {
        self.x = x
        self.y = y
        self.z = z
    }
    
    func length () -> Double {
        let magSquared = x*x + y*y + z*z
        let length = sqrt(magSquared)
        return length
    }
}

public func normalize(v: Vector) -> Vector {
    let vLen = v.length()
    if vLen > 0.0 {
        return (1.0 / vLen) * v
    } else {
        return v
    }
}

public func +(v1: Vector, v2: Vector) -> Vector {
    return Vector(v1.x + v2.x, v1.y + v2.y, v1.z + v2.z)
}

public prefix func -(v1:Vector) -> Vector {
    return Vector(-v1.x, -v1.y, -v1.z)
}

public func -(v1: Vector, v2: Vector) -> Vector {
    return v1 + (-v2)
}

infix operator ⋅ { associativity left precedence 150 }
public func ⋅(v1: Vector, v2: Vector) -> Double {
    return (v1.x * v2.x + v1.y * v2.y + v1.z * v2.z)
}

public func *(a: Double, v: Vector) -> Vector {
    return Vector(a * v.x, a * v.y, a * v.z)
}

