//
//  VectorTests.swift
//  schimeren
//
//  Created by Jonathan Blocksom on 12/23/14.
//  Copyright (c) 2014 GollyGee Software, Inc. All rights reserved.
//

import Foundation
import XCTest

class VectorTests: XCTestCase {
    
    let epsilon = 0.000000001
    
    func testLength() {
        let v = Vector(0.0, 3.0, 4.0)
        XCTAssertEqualWithAccuracy(
            Vector(0.0, 3.0, 4.0).length(), 5.0, accuracy: epsilon,
            "Length of y z vector not correct")
        XCTAssertEqualWithAccuracy(
            Vector(3.0, 0.0, 4.0).length(), 5.0, accuracy: epsilon,
            "Length of x z vector not correct")
        XCTAssertEqualWithAccuracy(
            Vector(3.0, 4.0, 0.0).length(), 5.0, accuracy: epsilon,
            "Length of x y vector not correct")
    }
}
