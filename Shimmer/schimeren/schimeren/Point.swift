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
}

func +(p: Point, v: Vector) -> Point {
    return Point(p.x + v.x, p.y + v.y, p.z + v.z)
}

