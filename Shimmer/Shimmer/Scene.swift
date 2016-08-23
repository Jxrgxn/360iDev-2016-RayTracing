//
//  Scene.swift
//  Shimmer
//
//  Created by Jonathan Blocksom on 1/9/15.
//  Copyright (c) 2015 GollyGee Software, Inc. All rights reserved.
//

import Foundation

public class Scene {
    public var objects: [Intersectable] = []
    
    public var lightDirection = normalize(Vector(-1.0, -1.0, -1.0))
    
    public func castRay(r: Ray) -> RaySurfaceIntersection? {
        
        var closestIntersection: RaySurfaceIntersection? = nil
        for object in objects {
            if let currentIntersection = object.intersect(r) {
                if closestIntersection == nil {
                    closestIntersection = currentIntersection
                } else {
                    if currentIntersection.closerThan(closestIntersection!) {
                        closestIntersection = currentIntersection
                    }
                }
            }
        }
        
        return closestIntersection
    }
}
