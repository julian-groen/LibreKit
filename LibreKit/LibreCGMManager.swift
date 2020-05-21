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
    
    public static let localizedTitle = LocalizedString("FreeStyle Libre", comment: "Title for the CGMManager")
    
    public static var managerIdentifier = "LibreKit"
    
    public let appURL: URL? = nil
    
    public let providesBLEHeartbeat = true
    
    public private(set) var lastConnected: Date?

    public var managedDataInterval: TimeInterval? = nil
    
    private lazy var bluetoothManager: TransmitterManager? = TransmitterManager()
    
    private lazy var calibrationManager: RawGlucose = RawGlucose()
    
    public let delegate = WeakSynchronizedDelegate<CGMManagerDelegate>()
    
    public var shouldSyncToRemoteService: Bool {
        return UserDefaults.standard.glucoseSync
    }
    
    public var sensorState: SensorDisplayable? {
        return latestReading
    }
    
    public private(set) var latestReading: Glucose? {
        didSet {
            NotificationManager.sendGlucoseNotificationIfNeeded(current: latestReading, last: oldValue)
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
    
    public func fetchNewDataIfNeeded(_ completion: @escaping (CGMResult) -> Void) {
        completion(.noData)
    }
    
    // MARK: - TransmitterManagerDelegate
    
    public func transmitterManager(_ transmitter: Transmitter?, didChangeTransmitterState state: TransmitterState) {
        switch state {
        case .connected:
            lastConnected = Date()
        default:
            break
        }
    }
    
    public func transmitterManager(_ transmitter: Transmitter?, didUpdateSensorData data: SensorData) {
        NotificationManager.sendLowBatteryNotificationIfNeeded(transmitter)
        
        guard data.isValidSensor && data.hasValidCRCs else {
            cgmManagerDelegate?.cgmManager(self, didUpdateWith: .error(SensorError.invalid))
            return
        }
        
        guard data.state == .ready || data.state == .starting else {
            cgmManagerDelegate?.cgmManager(self, didUpdateWith: .error(SensorError.expired))
            return
        }
        
        NotificationManager.sendSensorExpireAlertIfNeeded(data)
        
        guard let glucose = readingToGlucose(data), glucose.count > 0 else {
            cgmManagerDelegate?.cgmManager(self, didUpdateWith: .noData)
            return
        }
    
        let startDate = latestReading?.startDate.addingTimeInterval(1)
        let glucoseSamples = glucose.filterDateRange(startDate, nil).filter({ $0.isStateValid }).map { glucose -> NewGlucoseSample in
            return NewGlucoseSample(date: glucose.startDate, quantity: glucose.quantity, isDisplayOnly: false, syncIdentifier: "\(Int(glucose.timestamp))", device: device)
        }
        
        latestReading = glucose.max { $0.startDate < $1.startDate }
        cgmManagerDelegate?.cgmManager(self, didUpdateWith: (glucoseSamples.isEmpty ? .noData : .newData(glucoseSamples)))
    }
    
    private func readingToGlucose(_ data: SensorData) -> [Glucose]? {
        var entries = [Glucose]()
        var i: Int = 0
        
        for measurement in data.trend(reversed: true) {
            if i % 5 == 0 {
                guard let output = try? calibrationManager.prediction(raw: Double(measurement.rawGlucose)) else {
                    break
                }
                var glucose = Glucose(glucose: output.glucose, trend: .flat, minutes: data.minutes, state: data.state, timestamp: measurement.timestamp)
                glucose.trend = TrendCalculation.calculateTrend(current: glucose, last: entries.last)
                entries.append(glucose)
            }
            i += 1
        }
 
        return entries
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
    
    public var name: String? {
        return bluetoothManager?.transmitter?.name
    }
    
    public var identifier: String? {
        return bluetoothManager?.transmitter?.identifier
    }
    
    public var manufacturer: String? {
        return bluetoothManager?.transmitter?.manufacturer
    }

    public var hardware: String? {
        return bluetoothManager?.transmitter?.hardware
    }
    
    public var firmware: String? {
        return bluetoothManager?.transmitter?.firmware
    }
    
    public var connection: String? {
        return bluetoothManager?.state.rawValue
    }
    
    public var battery: String? {
        if let percentage = bluetoothManager?.transmitter?.battery {
            return "\(percentage)%"
        }
        return nil
    }
    
    public var device: HKDevice? {
        return HKDevice(
            name: "LibreKit",
            manufacturer: manufacturer,
            model: nil,
            hardwareVersion: hardware,
            firmwareVersion: firmware,
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
