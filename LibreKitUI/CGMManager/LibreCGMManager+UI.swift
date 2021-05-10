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
    
    public var cgmStatusHighlight: DeviceStatusHighlight? {
        return nil
    }
    
    public var cgmLifecycleProgress: DeviceLifecycleProgress? {
        return nil
    }
    
    public var cgmStatusBadge: DeviceStatusBadge? {
        return nil
    }
    
    public static func setupViewController(bluetoothProvider: BluetoothProvider, colorPalette: LoopUIColorPalette)
            -> SetupUIResult<UIViewController & CGMManagerCreateNotifying & CGMManagerOnboardNotifying & CompletionNotifying, CGMManagerUI> {
        return .userInteractionRequired(UICoordinator(colorPalette: colorPalette))
    }
    
    public func settingsViewController(for displayGlucoseUnitObservable: DisplayGlucoseUnitObservable, bluetoothProvider: BluetoothProvider, colorPalette: LoopUIColorPalette)
            -> (UIViewController & CGMManagerOnboardNotifying & CompletionNotifying) {
        return UICoordinator(colorPalette: colorPalette)
    }
    
    
    
//    public var smallImage: UIImage? {
//        return UIImage(named: "FreeStyle Libre")
//    }
//
//    public func settingsViewController(for displayGlucoseUnitObservable: DisplayGlucoseUnitObservable, bluetoothProvider: BluetoothProvider, colorPalette: LoopUIColorPalette) -> (UIViewController & CGMManagerOnboardNotifying & CompletionNotifying) {
//        <#code#>
//    }
//
//    public var cgmStatusBadge: DeviceStatusBadge? {
//        <#code#>
//    }
//
//    public static func setupViewController(glucoseTintColor: Color, guidanceColors: GuidanceColors) -> (UIViewController & CGMManagerSetupViewController & CompletionNotifying)? {
//        return UICoordinator(glucoseTintColor: glucoseTintColor, guidanceColors: guidanceColors)
//    }
//
//    public static func setupViewController(bluetoothProvider: BluetoothProvider, colorPalette: LoopUIColorPalette) -> SetupUIResult<UIViewController & CGMManagerCreateNotifying & CGMManagerOnboardNotifying & CompletionNotifying, CGMManagerUI> {
//
//    }
//
//
//    public func settingsViewController(for glucoseUnit: HKUnit, glucoseTintColor: Color, guidanceColors: GuidanceColors) -> (UIViewController & CompletionNotifying) {
//        return UICoordinator(cgmManager: self.set(glucoseUnit), glucoseTintColor: glucoseTintColor, guidanceColors: guidanceColors)
//    }
//
//    public var cgmStatusHighlight: DeviceStatusHighlight? {
//        return ((self.cgmManagerStatus.hasValidSensorSession == false) ? self.latestReading : nil)
//    }
//
//    public var cgmLifecycleProgress: DeviceLifecycleProgress? {
//        return ((self.latestReading?.percentComplete ?? 1.0) <= 0.5 ? self.latestReading : nil)
//    }
}
