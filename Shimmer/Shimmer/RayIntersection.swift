//
//  RayIntersection.swift
//  Shimmer
//
//  Created by Jonathan Blocksom on 1/17/15.
//  Copyright (c) 2015 GollyGee Software, Inc. All rights reserved.
//

import Foundation

//public protocol Intersectable {
//    func intersect(Ray) -> RayPoint?
//}

// Ray / object intersection
public struct RayIntersection: Comparable {
    let ray: Ray
    let object: Intersectable
    
    let distance: Double
    let point: Point
    
    init(_ r: Ray, _ object: Intersectable, _ distance: Double) {
        self.ray = r
        self.object = object

        self.distance = distance
        self.point = r.pointAlong(distance)
    }
}

public func ==(a: RayIntersection, b: RayIntersection) -> Bool {
//    return (a.ray == b.ray)
    return false
}

public func <(a: RayIntersection, b: RayIntersection) -> Bool {
    return a.distance < b.distance
}


