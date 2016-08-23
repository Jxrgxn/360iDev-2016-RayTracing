//
//  RGBColor.swift
//  Shimmer
//
//  Created by Jonathan Blocksom on 1/17/15.
//  Copyright (c) 2015 GollyGee Software, Inc. All rights reserved.
//

import Foundation

public struct RGBColor {
    let r: UInt8
    let g: UInt8
    let b: UInt8
    
    init (_ r: UInt8, _ g: UInt8, _ b: UInt8) {
        self.r = r
        self.g = g
        self.b = b
    }
}

let black = RGBColor(0, 0, 0)
let red = RGBColor(255, 0, 0)
let green = RGBColor(0, 255, 0)
let blue = RGBColor(0, 0, 255)
let white = RGBColor(255, 255, 255)

func scaleTo255(w: Double) -> UInt8 {
    return UInt8(ceil(max(min(w, 1.0), 0.0) * 255.0))
}

func grayColorFromFloat(w: Double) -> RGBColor {
    let w255 = scaleTo255(w)
    return RGBColor(w255, w255, w255)
}

func rgbFromFloats(r: Double, _ g: Double, _ b: Double) -> RGBColor {
    let r255 = scaleTo255(r)
    let g255 = scaleTo255(g)
    let b255 = scaleTo255(b)
    return RGBColor(r255, g255, b255)
}
