//
//  AppDelegate.swift
//  TestApp
//
//  Created by Julian Groen on 30/11/2019.
//  Copyright © 2020 Julian Groen. All rights reserved.
//

import UIKit
import LibreKitUI
import LibreKit
import LoopKitUI
import LoopKit
import HealthKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        let manager = LibreCGMManager()
        
        // let nav = UINavigationController(rootViewController: AlarmSettingsTableViewController(glucoseUnit: HKUnit.moleUnit(with: .milli, molarMass: HKUnitMolarMassBloodGlucose).unitDivided(by: .liter())))
        // let nav = UINavigationController(rootViewController: CalibrationEditTableViewController(cgmManager: nil))
        // let nav = UINavigationController(rootViewController: NotificationsSettingsTableViewController())
        // let nav = UINavigationController(rootViewController: BridgeSetupViewController())
        let nav = manager.settingsViewController(for: HKUnit.moleUnit(with: .milli, molarMass: HKUnitMolarMassBloodGlucose).unitDivided(by: .liter()))
        // let nav = LibreCGMManager.setupViewController()
        
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = nav
        window?.makeKeyAndVisible()
        
        return true
    }
    
}
