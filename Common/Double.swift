//
//  Double.swift
//  LibreKit
//
//  Created by Julian Groen on 18/05/2020.
//  Copyright © 2020 Julian Groen. All rights reserved.
//

import Foundation

extension Double {
    func roundTo(places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }

    var twoDecimals: String {
        return String(format: "%.2f", self)
    }
}
