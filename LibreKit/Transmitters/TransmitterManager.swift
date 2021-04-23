//
//  TransmitterManager.swift
//  LibreKit
//
//  Created by Julian Groen on 19/03/2021.
//  Copyright © 2021 Julian Groen. All rights reserved.
//

import Foundation
import CoreBluetooth
import os.log


public protocol TransmitterManagerDelegate: class {
    
    func transmitterManager(_ manager: TransmitterManager, recievedPacket packet: SensorPacket)
    
    func transmitterManager(_ manager: TransmitterManager, stateChange state: TransmitterState)
}

public class TransmitterManager: NSObject {
    
    private let log = OSLog(category: "TransmitterManager")

    // Isolated to centralQueue
    private var central: CBCentralManager!

    private let centralQueue = DispatchQueue(label: "com.librekit.central.queue", qos: .unspecified)
    
    public weak var delegate: TransmitterManagerDelegate?
    
    // Isolated to centralQueue
    private var transmitters: [Transmitter] = [] {
        didSet {
            NotificationCenter.default.post(name: .TransmittersDidChange, object: self)
        }
    }
    
    private var isScanningEnabled = false
    
    public init(_ state: TransmitterState?) {
        self.state = (state ?? TransmitterState(autoConnectID: nil))

        super.init()
        
        centralQueue.sync {
            central = CBCentralManager(
                delegate: self,
                queue: centralQueue,
                options: [CBCentralManagerOptionRestoreIdentifierKey: "com.librekit.central"]
            )
        }
    }
    
    // MARK: - State Management
    
    private var state: TransmitterState {
        didSet {
            delegate?.transmitterManager(self, stateChange: state)
        }
    }
    
    private var autoConnectID: UUID? {
        get {
            return state.autoConnectID
        }
        set {
            state.autoConnectID = newValue
        }
    }
    
    private var connectionState: ConnectionState {
        get {
            return state.connectionState
        }
        set {
            state.connectionState = newValue
        }
    }
    
    private var lastBatteryLevel: Int {
        get {
            return state.lastBatteryLevel
        }
        set {
            state.lastBatteryLevel = newValue
        }
    }
    
    // MARK: - Connection Management

    public func setScanningEnabled(_ enabled: Bool) {
        centralQueue.async {
            self.isScanningEnabled = enabled
            
            if case .poweredOn = self.central.state {
                if enabled {
                    self.central.scanForPeripherals()
                } else if self.central.isScanning {
                    self.central.stopScan()
                }
            }
        }
    }
    
    public func connect(_ transmitter: Transmitter) {
        centralQueue.async {
            self.autoConnectID = transmitter.peripheral.identifier

            guard let peripheral = self.reloadPeripheral(for: transmitter) else {
                return
            }

            self.central.connectIfNecessary(peripheral)
        }
    }

    public func disconnect(_ transmitter: Transmitter) {
        centralQueue.async {
            self.autoConnectID = nil

            guard let peripheral = self.reloadPeripheral(for: transmitter) else {
                return
            }

            self.central.cancelPeripheralConnectionIfNecessary(peripheral)
        }
    }

    /// Asks the central manager for its peripheral instance for a given transmitter.
    /// It seems to be possible that this reference changes across a bluetooth reset, and not updating the reference can result in API MISUSE warnings
    ///
    /// - Parameter transmitter: The transmitter to reload
    /// - Returns: The peripheral instance returned by the central manager
    private func reloadPeripheral(for transmitter: Transmitter) -> CBPeripheral? {
        dispatchPrecondition(condition: .onQueue(centralQueue))

        guard let peripheral = central.retrievePeripherals(withIdentifiers: [transmitter.peripheral.identifier]).first else {
            return nil
        }

        transmitter.peripheral = peripheral
        return peripheral
    }
    
    private var hasDiscoveredAutoConnectTransmitter: Bool {
        dispatchPrecondition(condition: .onQueue(centralQueue))
        return transmitters.contains(where: { $0.peripheral.identifier == autoConnectID })
    }
    
    private func autoConnectTransmitter() {
        dispatchPrecondition(condition: .onQueue(centralQueue))
        
        for transmitter in transmitters where transmitter.peripheral.identifier == autoConnectID {
            log.info("Attempting reconnect to %@", transmitter.peripheral)
            connect(transmitter)
        }
    }
    
    private func addPeripheral(_ peripheral: CBPeripheral) {
        dispatchPrecondition(condition: .onQueue(centralQueue))
        
        var transmitter = transmitters.first(where: { $0.peripheral.identifier == peripheral.identifier })
        
        if let transmitter = transmitter {
            transmitter.peripheral = peripheral
        } else {
            transmitter = TransmitterFromPeripheral(peripheral)
            transmitter?.delegate = self
            transmitters.append(transmitter!)
            log.info("Created transmitter for peripheral %@", peripheral)
        }

        if autoConnectID == peripheral.identifier {
            central.connectIfNecessary(peripheral)
        }
    }
    
    public func getTransmitters(_ completion: @escaping (_ transmitters: [Transmitter]) -> Void) {
        centralQueue.async { completion(self.transmitters) }
    }
}

// MARK: - Delegate methods called on `centralQueue`
extension TransmitterManager: CBCentralManagerDelegate {

    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if case .poweredOn = central.state {
            autoConnectTransmitter()
            
            if isScanningEnabled || !hasDiscoveredAutoConnectTransmitter {
                central.scanForPeripherals()
            } else if central.isScanning {
                central.stopScan()
            }
        }
    }
    
    public func centralManager(_ central: CBCentralManager, willRestoreState dict: [String : Any]) {
        log.default("%@", #function)

        guard let peripherals = dict[CBCentralManagerRestoredStatePeripheralsKey] as? [CBPeripheral] else {
            return
        }

        for peripheral in peripherals { addPeripheral(peripheral) }
    }
    
    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        guard peripheral.transmitterType() !== nil else { return }
        
        log.default("%@: %@: %@", #function, peripheral, String(describing: advertisementData))
        addPeripheral(peripheral)
        
        if !isScanningEnabled && central.isScanning && hasDiscoveredAutoConnectTransmitter {
            central.stopScan()
        }
    }
    
    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        for transmitter in transmitters where transmitter.peripheral.identifier == peripheral.identifier {
            log.default("%@: %@", #function, peripheral)
            transmitter.startConfiguration()
            connectionState = .connected
        }
    }
    
    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        log.default("%@: %@: %@", #function, peripheral, String(describing: error))
        autoConnectTransmitter()
        connectionState = .disconnected
    }
    
    public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        log.error("%@: %@: %@", #function, peripheral, String(describing: error))
        autoConnectTransmitter()
        connectionState = .disconnected
    }
}

extension TransmitterManager: TransmitterDelegate {
    
    public func transmitter(_ transmitter: Transmitter, changedBatteryLevel batteryLevel: Int) {
        if batteryLevel < 100 { self.lastBatteryLevel = batteryLevel }
    }
    
    public func transmitter(_ transmitter: Transmitter, didRecievePacket packet: SensorPacket) {
        delegate?.transmitterManager(self, recievedPacket: packet)
    }
}

extension CBCentralManager {
    func scanForPeripherals(withOptions options: [String: Any]? = nil) {
        scanForPeripherals(withServices: nil, options: options)
    }
}

extension Notification.Name {
    public static let TransmittersDidChange = Notification.Name("com.librekit.central.TransmittersDidChange")
}
