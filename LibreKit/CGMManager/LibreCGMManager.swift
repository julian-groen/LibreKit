//
//  LibreCGMManager.swift
//  LibreKit
//
//  Created by Julian Groen on 10/12/2020.
//  Copyright © 2020 Julian Groen. All rights reserved.
//

import LoopKit
import LoopKitUI
import CoreBluetooth
import HealthKit
import CoreML


public class LibreCGMManager: CGMManager {
    
    public static var managerIdentifier: String = "LibreKit"
    
    public static var localizedTitle: String = "Freestyle Libre"
    
    public var providesBLEHeartbeat: Bool = true
    
    public var preferredUnit: HKUnit = .milligramsPerDeciliter
    
    public var shouldSyncToRemoteService: Bool = true
    
    public var managedDataInterval: TimeInterval? = nil
    
    public let delegate = WeakSynchronizedDelegate<CGMManagerDelegate>()
    
    public let transmitterManager: TransmitterManager
    
    public private(set) var latestReading: SensorReading?
    
    public var glucoseDisplay: GlucoseDisplayable? {
        return self.latestReading
    }
    
    public var cgmStatus: CGMManagerStatus {
        let valid = (lastSensorPacket?.sensorState.isValidState)
        return CGMManagerStatus(hasValidSensorSession: valid ?? true)
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
    
    private let lockedState: Locked<LibreCGMManagerState>
    
    public var state: LibreCGMManagerState {
        return lockedState.value
    }
    
    public var rawState: PumpManager.RawStateValue {
        return state.rawValue
    }
    
    public init(state: LibreCGMManagerState) {
        self.lockedState = Locked(state)
        self.transmitterManager = TransmitterManager(state.transmitterState)
        self.transmitterManager.delegate = self
    }
    
    public required convenience init?(rawState: RawStateValue) {
        guard let state = LibreCGMManagerState(rawValue: rawState) else {
            return nil
        }
        self.init(state: state)
    }
    
    public func set(_ unit: HKUnit) -> LibreCGMManager {
        self.preferredUnit = unit; return self
    }
    
    public func set(_ changes: (_ state: inout LibreCGMManagerState) -> Void) {
        let oldValue: LibreCGMManagerState = state
        let newValue = lockedState.mutate { (state) in
            changes(&state)
        }
        
        if oldValue == newValue { return }
        
        delegate.notify { (delegate) in
            delegate?.cgmManagerDidUpdateState(self)
        }
    }
    
    public func fetchNewDataIfNeeded(_ completion: @escaping (CGMReadingResult) -> Void) {
        completion(.noData)
    }
    
    // TODO: TARGET TO CHANGE -> NEW ALGORITHM
    private var calibration: Calibration {
        return try! Calibration(configuration: MLModelConfiguration())
    }
    
    private func transformPacket(_ data: SensorPacket) -> [SensorReading]? {
        return nil
    }
    
    public var device: HKDevice? {
        return HKDevice(
            name: type(of: self).localizedTitle,
            manufacturer: "Abbott",
            model: lastSensorPacket?.sensorType.description,
            hardwareVersion: nil,
            firmwareVersion: nil,
            softwareVersion: nil,
            localIdentifier:
                transmitterState?.autoConnectID?.uuidString,
            udiDeviceIdentifier: nil
        )
    }
    
    public var debugDescription: String {
        return [
            "## \(String(describing: type(of: self)))",
            "state: \(String(reflecting: state))",
            ""
        ].joined(separator: "\n")
    }
    
    // TODO: ADDING NOTIFICATIONS
    public func acknowledgeAlert(alertIdentifier: Alert.AlertIdentifier) { }
    
    public func getSoundBaseURL() -> URL? {
        return nil
    }
    
    public func getSounds() -> [Alert.Sound] {
        return []
    }
}

// MARK: - TransmitterManagerDelegate
extension LibreCGMManager: TransmitterManagerDelegate {
    
    public func transmitterManager(_ manager: TransmitterManager, recievedPacket packet: SensorPacket) {
        self.lastSensorPacket = packet

        guard packet.isValidSensor else {
            delegate.notify { (delegate) in
                delegate?.cgmManager(self, hasNew: .error(SensorError.invalid))
            }
            return
        }
        
        guard packet.sensorState == .ready else {
            delegate.notify { (delegate) in
                delegate?.cgmManager(self, hasNew: .error(SensorError.expired))
            }
            return
        }
        
        guard let readings = transformPacket(packet), readings.count > 0 else {
            delegate.notify { (delegate) in
                delegate?.cgmManager(self, hasNew: .noData)
            }
            return
        }
        
        let startDate = latestReading?.startDate.addingTimeInterval(1)
        let newGlucoseSamples = readings.filterDateRange(startDate, nil).filter({ $0.isStateValid }).map {
            glucose -> NewGlucoseSample in return NewGlucoseSample(
                date: glucose.startDate, quantity: glucose.quantity, isDisplayOnly: false,
                wasUserEntered: false, syncIdentifier: "\(Int(glucose.timestamp))", device: device
            )
        }
        
        delegate.notify { (delegate) in
            delegate?.cgmManager(self, hasNew: newGlucoseSamples.isEmpty ? .noData : .newData(newGlucoseSamples))
        }
        
        latestReading = readings.filter({ $0.isStateValid }).max(by: { $0.startDate < $1.startDate })
    }
    
    public func transmitterManager(_ manager: TransmitterManager, stateChange state: TransmitterState) {
        self.transmitterState = state
    }
}

// MARK: - Wrapped Variable
extension LibreCGMManager {
    
    public var alarmNotifications: Bool {
        get {
            return state.alarmNotifications
        }
        set {
            set { (state) in
                state.alarmNotifications = newValue
            }
        }
    }
    
    public var glucoseTargetRange: DoubleRange {
        get {
            return state.glucoseTargetRange
        }
        set {
            set { (state) in
                state.glucoseTargetRange = newValue
            }
        }
    }
    
    public var transmitterState: TransmitterState? {
        get {
            return state.transmitterState
        }
        set {
            set { (state) in
                state.transmitterState = newValue
            }
        }
    }
    
    public var lastSensorPacket: SensorPacket? {
        get {
            return state.lastSensorPacket
        }
        set {
            set { (state) in
                state.lastSensorPacket = newValue
            }
        }
    }
}
