//
//  TrendCalculation.swift
//  LibreKit
//
//  Created by Julian Groen on 13/05/2020.
//  Copyright © 2020 Julian Groen. All rights reserved.
//

import Foundation
import LoopKit

class TrendCalculation {
    static func calculateSlope(_ current: Glucose, _ last: Glucose) -> Double {
        if current.date == last.date {
            return 0.0
        }

        let glucoseDiff = Double(current.glucose) - Double(last.glucose)
        let minutesDiff = calculateDiffInMinutes(last: last.date, current: current.date)

        return glucoseDiff / minutesDiff
    }

    static func calculateDiffInMinutes(last: Date, current: Date) -> Double {
        let diff = current.timeIntervalSince(last)
        return diff / 60
    }

    static func calculateTrend(current: Glucose?, last: Glucose?) -> GlucoseTrend {
        guard let current = current, let last = last else {
            return .flat
        }

        let slope = calculateSlope(current, last)

        switch slope {
        case _ where slope <= (-3.5):
            return .downDownDown
        case _ where slope <= (-2):
            return .downDown
        case _ where slope <= (-1):
            return .down
        case _ where slope <= (1):
            return .flat
        case _ where slope <= (2):
            return .up
        case _ where slope <= (3.5):
            return .upUp
        case _ where slope <= (40):
            return .upUpUp
        default:
            return .flat
        }
    }
}
