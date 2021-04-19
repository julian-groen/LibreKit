//
//  Guardrail.swift
//  LibreKit
//
//  Created by Julian Groen on 14/04/2021.
//  Copyright © 2021 Julian Groen. All rights reserved.
//

import LoopKit
import HealthKit


extension Guardrail where Value == HKQuantity {
    
    static func bloodglucoseGuardrail() -> Guardrail {
        return Guardrail(absoluteBounds: 50...290, recommendedBounds: 65...220, unit: .milligramsPerDeciliter, startingSuggestion: 70)
    }
}
