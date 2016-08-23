//
//  Camera.swift
//  Shimmer
//
//  Created by Jonathan Blocksom on 12/24/14.
//  Copyright (c) 2014 GollyGee Software, Inc. All rights reserved.
//

import Foundation

public struct Camera {
    let fov: Double = 60.0
    let farClip: Double = 10.0
}

public func raysForCamera (
    camera: Camera,
    samplesPerSide: Int)
    -> [Ray]
{
    if (samplesPerSide < 2) { return [] }
    
    let fov_over_2 = camera.fov / 2.0
    
    // Calculate upper left corner
    let halfDist = sin(fov_over_2 * M_PI / 180.0)
    let dist: Double = 2.0 * halfDist
    
    let denom = Double(samplesPerSide - 1)
    let delta: Double = dist / denom

    let upperLeft = Point(-halfDist, -halfDist, -1.0)

    let hDelta = Vector(delta, 0.0, 0.0)
    let vDelta = Vector(0.0, delta, 0.0)

    var rays: [Ray] = []

    let xr = 0 ..< samplesPerSide
    let yr = 0 ..< samplesPerSide

    for y in yr {
        for x in xr {
            let xf = Double(x)
            let yf = Double(y)
            let offset = xf * hDelta + yf * vDelta
            let pt = upperLeft + offset
            let direction = Origin.vectorTo(pt)
            // println("Direction for \(x) \(y): \(direction.x) \(direction.y) \(direction.z)")
            let ray = Ray(origin: Origin, direction: direction)
            
            rays.append(ray)
        }
    }

    return rays
}
