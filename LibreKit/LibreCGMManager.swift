//
//  LibreCGMManager.swift
//  LibreKit
//
//  Created by Julian Groen on 11/05/2020.
//  Copyright © 2020 Julian Groen. All rights reserved.
//

import Foundation
import LoopKit
import LoopKitUI
import HealthKit

public class LibreCGMManager: CGMManager, TransmitterManagerDelegate {
    private lazy var bluetoothManager: TransmitterManager? = TransmitterManager()
    
    public static let localizedTitle = LocalizedString("FreeStyle Libre 2")
    public static var managerIdentifier = "LibreKit"
    public let appURL: URL? = nil
    public let providesBLEHeartbeat = true
    public private(set) var lastConnected: Date?
    public var managedDataInterval: TimeInterval? = nil
    public let delegate = WeakSynchronizedDelegate<CGMManagerDelegate>()
    
    public var shouldSyncToRemoteService: Bool {
        return UserDefaults.standard.glucoseSync
    }
    
    public var sensorState: SensorDisplayable? {
        return latestReading
    }
    
    public private(set) var latestReading: Glucose? {
        didSet {
            if let currentGlucose = latestReading {
                DispatchQueue.main.async(execute: {
                    UIApplication.shared.applicationIconBadgeNumber = Int(currentGlucose.glucose)
                })
            }
        }
    }

    public var cgmManagerDelegate: CGMManagerDelegate? {
        get {
            return delegate.delegate
        }
        set {
            delegate.delegate = newValue
        }
    }

    public var delegateQueue: DispatchQueue! {
        get {
            return delegate.queue
        }
        set {
            delegate.queue = newValue
        }
    }

    public var rawState: CGMManager.RawStateValue {
        return [:]
    }
    
    public init() {
        if UserDefaults.standard.debugModeActivated {
            UserDefaults.standard.transmitterID = "Developer Mode 0x1908"
        }
        lastConnected = nil
        bluetoothManager?.delegate = self
    }
    
    public required convenience init?(rawState: RawStateValue) {
        self.init()
    }
    
    deinit {
        bluetoothManager?.disconnect()
        bluetoothManager?.delegate = nil
    }
    
    public func resetConnection() {
        bluetoothManager?.transmitter?.resetConnection()
    }
    
    public func fetchNewDataIfNeeded(_ completion: @escaping (CGMResult) -> Void) {
        completion(.noData)
    }
    
    // MARK: - TransmitterManagerDelegate
       
    public func transmitterManager(_ transmitter: Transmitter?, didChangeTransmitterState state: TransmitterState) {
        switch state {
        case .connected:
            lastConnected = Date()
        case .notifying:
            lastConnected = Date()
        default:
            break
        }
    }
    
    public func transmitterManager(_ transmitter: Transmitter?, didUpdateSensorData data: SensorData) {
        NotificationManager.sendSensorExpireNotificationIfNeeded(data)
        
        guard let glucose = readingToGlucose(data), glucose.count > 0 else {
            delegateQueue.async {
                self.cgmManagerDelegate?.cgmManager(self, didUpdateWith: .noData)
            }
            
            return
        }
    
        let startDate = latestReading?.startDate.addingTimeInterval(1)
        let glucoseSamples = glucose.filterDateRange(startDate, nil).filter({ $0.isStateValid }).map { glucose -> NewGlucoseSample in
            return NewGlucoseSample(date: glucose.startDate, quantity: glucose.quantity, isDisplayOnly: false, syncIdentifier: glucose.date.timeIntervalSince1970.description, device: device)
        }
        
        delegateQueue.async {
            self.cgmManagerDelegate?.cgmManager(self, didUpdateWith: (glucoseSamples.isEmpty ? .noData : .newData(glucoseSamples)))
        }
        
        latestReading = glucose.first //glucose.filter({ $0.isStateValid }).max { $0.startDate < $1.startDate }
        lastConnected = Date()
    }
    
    private func readingToGlucose(_ data: SensorData) -> [Glucose]? {
        var entries = [Glucose]()

        var lastGlucose: Glucose? = nil
        for measurement in data.trend {
            var glucose = Glucose(glucose: Double(measurement.value), trend: .flat, wearTimeMinutes: data.wearTimeMinutes, state: UserDefaults.standard.sensorState ?? .unknown, date: measurement.date)
            glucose.trend = TrendCalculation.calculateTrend(current: glucose, last: lastGlucose)
            
            entries.append(glucose)
            lastGlucose = glucose
        }
 
        return entries.reversed()
    }
    
    public var debugDescription: String {
        return [
            "## \(String(describing: type(of: self)))",
            "lastConnected: \(String(describing: lastConnected))",
            "latestReading: \(String(describing: latestReading))",
            "connectionState: \(String(describing: connection))",
            "shouldSyncToRemoteService: \(String(describing: shouldSyncToRemoteService))",
            "providesBLEHeartbeat: \(String(describing: providesBLEHeartbeat))",
            ""
        ].joined(separator: "\n")
    }
}

extension LibreCGMManager {
    public var identifier: String? {
        return bluetoothManager?.transmitter?.identifier
    }
    
    public var manufacturer: String? {
        return bluetoothManager?.transmitter?.manufacturer
    }
    
    public var connection: String? {
        return bluetoothManager?.state.rawValue
    }
    
    public var device: HKDevice? {
        return HKDevice(
            name: "LibreKit",
            manufacturer: manufacturer,
            model: nil,
            hardwareVersion: nil,
            firmwareVersion: nil,
            softwareVersion: nil,
            localIdentifier: identifier,
            udiDeviceIdentifier: nil
        )
    }
}

extension UserDefaults {
    public var debugModeActivated: Bool {
        return false
    }
}
