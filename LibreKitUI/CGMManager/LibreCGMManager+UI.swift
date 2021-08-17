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
    
    public static var onboardingImage: UIImage? {
        return UIImage(named: "FreeStyle Libre")
    }
    
    public static func setupViewController(bluetoothProvider: BluetoothProvider, displayGlucoseUnitObservable: DisplayGlucoseUnitObservable, colorPalette: LoopUIColorPalette, allowDebugFeatures: Bool) -> SetupUIResult<CGMManagerViewController, CGMManagerUI> {
        return .userInteractionRequired(UICoordinator(colorPalette: colorPalette))
    }
    
    public var smallImage: UIImage? {
        return UIImage(named: "FreeStyle Libre")
    }
    
    public var cgmStatusHighlight: DeviceStatusHighlight? {
        return self.latestReading?.statusHighlight
    }
    
    public var cgmLifecycleProgress: DeviceLifecycleProgress? {
        return self.latestReading?.lifecycleProgress
    }
    
    public var cgmStatusBadge: DeviceStatusBadge? {
        return self.latestReading?.statusBadge
    }
    
    public func settingsViewController(bluetoothProvider: BluetoothProvider, displayGlucoseUnitObservable: DisplayGlucoseUnitObservable, colorPalette: LoopUIColorPalette, allowDebugFeatures: Bool) -> CGMManagerViewController {
        return UICoordinator(cgmManager: self, glucoseUnitObservable: displayGlucoseUnitObservable, colorPalette: colorPalette)
    }
    
    public func displayGlucoseUnitDidChange(to displayGlucoseUnit: HKUnit) {
        self.displayGlucoseUnit = displayGlucoseUnit
    }
}

// return .userInteractionRequired(UICoordinator(colorPalette: colorPalette))
// return .createdAndOnboarded(LibreCGMManager(state: LibreCGMManagerState()))
