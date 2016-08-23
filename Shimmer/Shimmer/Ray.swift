//
//  Ray.swift
//  Shimmer
//
//  Created by Jonathan Blocksom on 12/24/14.
//  Copyright (c) 2014 GollyGee Software, Inc. All rights reserved.
//

import Foundation

public struct Ray {
    let origin: Point
    let direction: Vector
    
    init(origin: Point, direction: Vector) {
        self.origin = origin
        self.direction = normalize(direction)
    }

    func pointAlong(distance: Double) -> Point {
        return origin + distance * direction
    }
}

// Point along a ray
public struct RayPoint {
    let ray: Ray
    let distance: Double
    let point: Point
    
    init(_ r: Ray, _ distance: Double) {
        self.ray = r
        self.distance = distance
        self.point = r.pointAlong(distance)
    }
}

public struct SurfacePoint {
    let point: Point
    let normal: Vector
    
    // Add a reference to the object?
}

public struct RaySurfaceIntersection {
    let rayPoint: RayPoint
    let surfacePoint: SurfacePoint
    
    public func closerThan(otherIntersection: RaySurfaceIntersection) -> Bool {
        return self.rayPoint.distance < otherIntersection.rayPoint.distance
    }
    
    public func light(scene: Scene) -> RGBColor {
        let n = surfacePoint.normal
//        print("Normal is \(n.x) \(n.y) \(n.z)")
        
        let vecToEye = -rayPoint.ray.direction
        let vecToLight = scene.lightDirection
        let halfVec = normalize(vecToLight + vecToEye)
        
        let factor = n ⋅ halfVec
        print("Factor is \(factor)")
        
        return grayColorFromFloat(factor)
        
         return rgbFromFloats((n.x + 1.0) * 0.5, (n.y + 1.0) * 0.5, (n.z + 1.0) * 0.5)
    }
}

public protocol Intersectable {
    func intersect(_: Ray) -> RaySurfaceIntersection?
    
    var color: RGBColor { get }
}

public protocol Surface {
    func normal(_: Point) -> Vector
    
    
}

