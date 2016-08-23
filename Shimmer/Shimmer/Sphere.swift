//
//  Sphere.swift
//  Shimmer
//
//  Created by Jonathan Blocksom on 1/6/15.
//  Copyright (c) 2015 GollyGee Software, Inc. All rights reserved.
//

import Foundation

public struct Sphere: Intersectable {
    public let center: Point
    public let radius: Double
    public let color: RGBColor
    
    init(_ center: Point,
        _ radius: Double,
        color: RGBColor = RGBColor(255, 255, 255))
    {
        self.center = center
        self.radius = radius
        self.color = color
    }
    
    public func intersect(r: Ray) -> RaySurfaceIntersection? {
        // Get origin relative to sphere center
        let rayOriginToSphere = r.origin ⟶ center
        
        // Calculate point along ray of closest approach to sphere center
        let closestDistance = rayOriginToSphere ⋅ r.direction
        if (closestDistance < 0) {
            // Sphere is behind the ray, no intersection
            return nil
        }
        let closestPoint = r.pointAlong(closestDistance)
        
        // Calculate distance of closest approach to center
        let closestPointToCenter = closestPoint.vectorTo(center)
        let distanceToCenter = closestPointToCenter.length()
        if (distanceToCenter > radius) {
            // Sphere does not hit the ray
            return nil
        }

        // Ray intersects sphere, figure out where
        // Calculate distance between intersection and closest approach
        let distanceToIntersection = sqrt(radius*radius - distanceToCenter*distanceToCenter)
        let directionSign = (distanceToIntersection > closestDistance) ? -1.0 : 1.0
        
        let intersectionDistance = closestDistance - directionSign * distanceToIntersection
        let intersectionPoint = RayPoint(r, intersectionDistance)

        let surfacePoint = SurfacePoint(point: intersectionPoint.point,
                                        normal: normalize(self.center ⟶ intersectionPoint.point))
        
        let rsIntersection = RaySurfaceIntersection(rayPoint: intersectionPoint,
                                                    surfacePoint: surfacePoint)
        return rsIntersection
    }
}

