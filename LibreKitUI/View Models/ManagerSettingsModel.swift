//
//  ManagerSettingsModel.swift
//  LibreKitUI
//
//  Created by Julian Groen on 12/04/2021.
//  Copyright © 2021 Julian Groen. All rights reserved.
//

import LibreKit
import LoopKit
import LoopKitUI
import HealthKit


class ManagerSettingsModel: NSObject, ObservableObject {
    
    let cgmManager: LibreCGMManager
    let glucoseUnitObservable: DisplayGlucoseUnitObservable
    var hasCompleted: (() -> Void)?
    
    @Published var glucoseTargetRange: DoubleRange
    @Published var notificationAlerts: Bool
    
    var connectionState: ConnectionState {
        return cgmManager.transmitterState?.connectionState ?? .unknown
    }
    
    var lastBatteryLevel: Int {
        return cgmManager.transmitterState?.lastBatteryLevel ?? 100
    }
    
    var preferredUnit: HKUnit {
        return glucoseUnitObservable.displayGlucoseUnit
    }
    
    var latestReading: SensorReading? {
        return cgmManager.latestReading
    }
    
    lazy var unitFormatter: QuantityFormatter = {
        let formatter = QuantityFormatter()
        formatter.setPreferredNumberFormatter(for: preferredUnit)
        return formatter
    }()

    lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .long
        formatter.doesRelativeDateFormatting = true
        return formatter
    }()
    
    init(cgmManager: LibreCGMManager, for glucoseUnitObservable: DisplayGlucoseUnitObservable) {
        self.cgmManager = cgmManager
        self.glucoseUnitObservable = glucoseUnitObservable
        self.notificationAlerts = cgmManager.notificationAlerts
        self.glucoseTargetRange = cgmManager.glucoseTargetRange
    }
    
    func toggleNotifications() {
        cgmManager.notificationAlerts = !cgmManager.notificationAlerts
        self.notificationAlerts = cgmManager.notificationAlerts
    }
    
    func saveGlucoseTargetRange(_ glucoseTargetRange: DoubleRange) {
        cgmManager.glucoseTargetRange = glucoseTargetRange
        self.glucoseTargetRange = cgmManager.glucoseTargetRange
    }
    
    func notifyDeletion() {
        cgmManager.notifyDelegateOfDeletion {
            DispatchQueue.main.async { self.hasCompleted?() }
        }
    }
}

extension ManagerSettingsModel {
    
    var bloodglucoseDescription: String {
        return LocalizedString(
            "Specify the blood sugar level range that you want to aim for, based on this range notifications will be send when the glucose level reaches outside of the specified range.",
            comment: "Description describing target ranges"
        )
    }

    var notificationDescription: String {
        return LocalizedString(
            "When enabled notifications will be send on certain events. These events consist of blood sugar alerts, low battery warnings and sensor lifetime updates.",
            comment: "Description describing notifications and purpose"
        )
    }
}
