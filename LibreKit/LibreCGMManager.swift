//
//  LibreCGMManager.swift
//  LibreKit
//
//  Created by Julian Groen on 10/12/2020.
//  Copyright © 2020 Julian Groen. All rights reserved.
//

import LoopKit
import LoopKitUI
import HealthKit
import CoreML
import os.log

public class LibreCGMManager: CGMManager, TransmitterManagerDelegate {
    
    public static var managerIdentifier: String = "LibreKit"
    
    public static var localizedTitle: String = LocalizedString("FreeStyle Libre", comment: "Title for the CGMManager")
    
    public var providesBLEHeartbeat: Bool = true
    
    public var shouldSyncToRemoteService: Bool = true
    
    public var managedDataInterval: TimeInterval? = nil
    
    public let delegate = WeakSynchronizedDelegate<CGMManagerDelegate>()
    
    public lazy var transmitterManager: TransmitterManager = TransmitterManager()
    
    private lazy var calibration = try! Calibration(configuration: MLModelConfiguration())
    
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
        transmitterManager.delegate = self
    }
    
    public required convenience init?(rawState: RawStateValue) {
        self.init()
    }
    
    deinit {
        transmitterManager.disconnect()
        transmitterManager.delegate = nil
    }

    public func transmitterManager(_ transmitter: Transmitter, recievedSensorData data: SensorData) {
        
    }
    
    
    
    
    
    
//    public func test() {
//        
//        let 
//        
//        delegate.notifyDelayed(by: 15) { delegate in
//            delegate?.issueAlert(<#T##alert: Alert##Alert#>)
//        }
//    }
//    
    
    
    
    
    
    
    
    
    
    
    public var glucoseDisplay: GlucoseDisplayable?
    
    public var cgmStatus: CGMManagerStatus {
        return CGMManagerStatus(hasValidSensorSession: true)
    }
    
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

extension LibreCGMManager {
    
    public var name: String? {
        return transmitterManager.transmitter?.name
    }

    public var identifier: String? {
        return transmitterManager.transmitter?.identifier.uuidString
    }

    public var manufacturer: String? {
        return transmitterManager.transmitter?.manufacturer
    }

    public var connection: String? {
        return transmitterManager.state.rawValue
    }

    public var battery: Int? {
        return transmitterManager.transmitter?.battery
    }

    public var device: HKDevice? {
        return HKDevice(
            name: managerIdentifier,
            manufacturer: manufacturer,
            
            model: name,
            hardwareVersion: nil,
            firmwareVersion: nil,
            softwareVersion: nil,
            localIdentifier: identifier,
            udiDeviceIdentifier: nil
        )
    }
    
    public var debugDescription: String {
        return [
            "## \(String(describing: type(of: self)))",
            "connectionState: \(String(describing: connection))",
            // "latestReading: \(String(describing: latestReading))",
            "identifier: \(String(describing: identifier))",
            ""
        ].joined(separator: "\n")
    }
}
