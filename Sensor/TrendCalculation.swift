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
        if current.timestamp == last.timestamp {
            return 0.0
        }
        return (Double(last.glucose) - Double(current.glucose)) / (Double(last.timestamp * 1_000) - Double(current.timestamp * 1_000))
    }
    
    static func calculateSlopeByMinute(_ current: Glucose, _ last: Glucose) -> Double {
        return calculateSlope(current, last) * 60_000
    }

    static func calculateTrend(current: Glucose?, last: Glucose?) -> GlucoseTrend {
        guard let current = current, let last = last else {
            return  .flat
        }
        
        let slope = calculateSlopeByMinute(current, last)
        
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
