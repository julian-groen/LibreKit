//
//  SensorReading.swift
//  LibreKit
//
//  Created by Julian Groen on 05/01/2021.
//  Copyright © 2021 Julian Groen. All rights reserved.
//

import Foundation
import LoopKit
import HealthKit

public class SensorReading: GlucoseDisplayable, DeviceStatusHighlight, DeviceLifecycleProgress {
    
    public var isStateValid: Bool = true
    
    public var trendType: GlucoseTrend? = nil
    
    public var isLocal: Bool = true
    
    public var glucoseRangeCategory: GlucoseRangeCategory? = nil
    
    public var localizedMessage: String = "Battery Low"
    
    public var imageName: String = "exclamationmark.circle.fill"
    
    public var state: DeviceStatusHighlightState = .critical
    
    public var percentComplete: Double = 0.9
    
    public var progressState: DeviceLifecycleProgressState = .normalCGM
    
    init() {
        
    }
}

//extension SensorReading: GlucoseValue {
//
//    public var quantity: HKQuantity {
//        return HKQuantity(unit: HKUnit., doubleValue: <#T##Double#>)
//    }
//
//    public var startDate: Date {
//        <#code#>
//    }
//}
