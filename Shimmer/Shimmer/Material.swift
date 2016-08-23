//
//  Material.swift
//  Shimmer
//
//  Created by Jonathan Blocksom on 8/22/16.
//  Copyright © 2016 GollyGee Software, Inc. All rights reserved.
//

import Foundation

public enum Material {
    case Emissive
    case Diffuse
    case Mirror
    
    // func colorAtPoint(intersection: RaySurfaceIntersection,
}

protocol Lightable {
    func surfaceColor(rs: RaySurfaceIntersection) -> RGBColor
}

// extension Object: Intersectable, Lightable
