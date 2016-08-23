//
//  Point.swift
//  schimeren
//
//  Created by Jonathan Blocksom on 12/23/14.
//  Copyright (c) 2014 GollyGee Software, Inc. All rights reserved.
//

import Foundation

public struct Point {
    let x, y, z: Double
    
    public init(_ x: Double, _ y: Double, _ z: Double) {
        self.x = x
        self.y = y
        self.z = z
    }
    
    func relativeTo(origin: Point) -> Point {
        return Point(x - origin.x, y - origin.y, z - origin.z)
    }
    
    func vectorTo(p: Point) -> Vector {
        return Vector(p.x - x, p.y - y, p.z - z)
    }
    
    func distanceBetween(p: Point) -> Double {
        return self.vectorTo(p).length()
    }
}

let Origin = Point(0, 0, 0)

public func +(p: Point, v: Vector) -> Point {
    return Point(p.x + v.x, p.y + v.y, p.z + v.z)
}

// a ⊷ b  a₀ a₁ b₂⦁
infix operator ⟶ { associativity left precedence 150 }
func ⟶(p1: Point, p2: Point) -> Vector {
    return Vector(p2.x - p1.x, p2.y - p1.y, p2.z - p1.z)
}

