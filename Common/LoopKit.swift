//
//  LoopKit.swift
//  LibreKit
//
//  Created by Julian Groen on 14/04/2021.
//  Copyright © 2021 Julian Groen. All rights reserved.
//

import LoopKit
import LoopKitUI
import HealthKit


extension Guardrail where Value == HKQuantity {
    static func bloodglucoseGuardrail() -> Guardrail {
        return Guardrail(absoluteBounds: 50...290, recommendedBounds: 65...220, unit: .milligramsPerDeciliter, startingSuggestion: 70)
    }
}

extension Array where Element: Hashable {
    func unique() -> Array<Element> {
        var set = Set<Element>()
        return filter { set.insert($0).inserted }
    }
}

// MARK: - Helper Classes
public struct CGMStatusHighlight: DeviceStatusHighlight {
    
    public var localizedMessage: String
    
    public var imageName: String
    
    public var state: DeviceStatusHighlightState {
        return .critical
    }
}
    
public struct CGMLifecycleProgress: DeviceLifecycleProgress {
    
    public var percentComplete: Double
    
    public var progressState: DeviceLifecycleProgressState {
        switch percentComplete {
        case let x where x >= 0.9: return .critical
        case let x where x >= 0.7: return .warning
        default: return .normalCGM
        }
    }
}

public struct CGMStatusBadge: DeviceStatusBadge {
    
    public var imageName: String
    
    public var image: UIImage? {
        return UIImage(systemName: imageName)
    }
    
    public var state: DeviceStatusBadgeState {
        return .warning
    }
}
