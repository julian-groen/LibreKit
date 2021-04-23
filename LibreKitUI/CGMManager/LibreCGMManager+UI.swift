//
//  LibreCGMManager+UI.swift
//  LibreKitUI
//
//  Created by Julian Groen on 10/12/2020.
//  Copyright © 2020 Julian Groen. All rights reserved.
//

import SwiftUI
import HealthKit
import LoopKit
import LoopKitUI
import LibreKit


extension LibreCGMManager: CGMManagerUI {
    
    public var smallImage: UIImage? {
        return UIImage(named: "FreeStyle Libre")
    }
    
    public static func setupViewController(glucoseTintColor: Color, guidanceColors: GuidanceColors) -> (UIViewController & CGMManagerSetupViewController & CompletionNotifying)? {
        return UICoordinator(glucoseTintColor: glucoseTintColor, guidanceColors: guidanceColors)
    }
    
    public func settingsViewController(for glucoseUnit: HKUnit, glucoseTintColor: Color, guidanceColors: GuidanceColors) -> (UIViewController & CompletionNotifying) {
        return UICoordinator(cgmManager: self.set(glucoseUnit), glucoseTintColor: glucoseTintColor, guidanceColors: guidanceColors)
    }
    
    public var cgmStatusHighlight: DeviceStatusHighlight? {
        return ((self.cgmStatus.hasValidSensorSession == false) ? self.latestReading : nil)
    }
    
    public var cgmLifecycleProgress: DeviceLifecycleProgress? {
        return ((self.latestReading?.percentComplete ?? 1.0) <= 0.5 ? self.latestReading : nil)
    }
}
