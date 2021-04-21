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


public class LibreCGMManager: CGMManager {
    
    public static var managerIdentifier: String = "LibreKit"
    
    public static var localizedTitle: String = "Freestyle Libre"
    
    public var providesBLEHeartbeat: Bool = true
    
    public var shouldSyncToRemoteService: Bool = true
    
    public var managedDataInterval: TimeInterval? = nil
    
    public let delegate = WeakSynchronizedDelegate<CGMManagerDelegate>()
    
    public let transmitterManager: TransmitterManager
    
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
    
    private func set(_ changes: (_ state: inout LibreCGMManagerState) -> Void) {
        let oldValue: LibreCGMManagerState = state
        let newValue = lockedState.mutate { (state) in
            changes(&state)
        }
        
        if oldValue == newValue { return }
        
        delegate.notify { (delegate) in
            delegate?.cgmManagerDidUpdateState(self)
        }
        
        // validate data and send notification if necessary
    }
    
    
    
    
    public var device: HKDevice? {
        return HKDevice(
            name: localizedTitle,
            manufacturer: "Abbott",
            model: nil, // retrieve from lastSensorPacket
            hardwareVersion: nil,
            firmwareVersion: nil,
            softwareVersion: nil,
            localIdentifier: nil,
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
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    public var glucoseDisplay: GlucoseDisplayable?
    
    public var cgmStatus: CGMManagerStatus = CGMManagerStatus(hasValidSensorSession: true)
    
    public func fetchNewDataIfNeeded(_ completion: @escaping (CGMReadingResult) -> Void) {
        
    }
    
    public func acknowledgeAlert(alertIdentifier: Alert.AlertIdentifier) {
        
    }
    
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
