//
//  CalibrationInfo.swift
//  LibreKit
//
//  Created by Reimar Metzen on 24.02.21.
//  Copyright © 2021 Mark Wilson. All rights reserved.
//

import Foundation

public struct CalibrationInfo: Equatable, Codable {
    var i1: Int
    var i2: Int
    var i3: Double
    var i4: Double
    var i5: Double
    var i6: Double

    init(i1: Int, i2: Int, i3: Double, i4: Double, i5: Double, i6: Double) {
        self.i1 = i1
        self.i2 = i2
        self.i3 = i3
        self.i4 = i4
        self.i5 = i5
        self.i6 = i6
    }
}
