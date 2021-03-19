//
//  Transmitter+Abbot.swift
//  LibreKit
//
//  Created by Reimar Metzen on 05.03.21.
//  Copyright © 2021 Mark Wilson. All rights reserved.
//

import CoreBluetooth
import Foundation
import UIKit
import CoreNFC
import Combine

@available(iOS 14.0, *)
public class Libre2Direct: Transmitter & LibreNFCDelegate {
    private static let unknownOutput = "-"
    private static let expectedBufferSize = 46
    private static let maxWaitForpacketInSeconds = 60.0
    
    public var manufacturer: String = "Abbot"

    public var serviceCharacteristicsUuid: [CBUUID] = [CBUUID(string: "FDE3")]
    public var writeCharacteristicUuid: CBUUID = CBUUID(string: "F001")
    public var readCharacteristicUuid: CBUUID = CBUUID(string: "F002")

    var libreNFC: LibreNFC?

    required init(with identifier: String, name: String?) {
        super.init(with: identifier, name: name)

        let serial = String(name!.suffix(name!.count - 6))
        UserDefaults.standard.sensorSerial = serial
        
        if UserDefaults.standard.sensorUID == nil || UserDefaults.standard.sensorPatchInfo == nil || UserDefaults.standard.sensorCalibrationInfo == nil || UserDefaults.standard.sensorState == nil {
            self.scanNfc()
        }

        logger.log("init: \(serial)")
    }
    
    public func resetConnection() {
        UserDefaults.standard.sensorUID = nil
        UserDefaults.standard.sensorPatchInfo = nil
        UserDefaults.standard.sensorCalibrationInfo = nil
        UserDefaults.standard.sensorState = nil
    }
    
    public func received(sensorUID: Data, patchInfo: Data) {
        UserDefaults.standard.sensorUID = sensorUID
        UserDefaults.standard.sensorPatchInfo = patchInfo
        
        logger.log("sensorUID: \(sensorUID)")
        logger.log("patchInfo: \(patchInfo)")
    }

    public func received(fram: Data) {
        guard let sensorUID = UserDefaults.standard.sensorUID, let patchInfo = UserDefaults.standard.sensorPatchInfo else {
            return
        }
        
        let data = LibreUtility.decryptFRAM(sensorUID, patchInfo, fram)

        UserDefaults.standard.sensorCalibrationInfo = Libre2Utility.readCalibrationInfo(bytes: data)
        UserDefaults.standard.sensorState = SensorState(bytes: data)
        
        logger.log("calibrationInfo i1: \(UserDefaults.standard.sensorCalibrationInfo?.i1.description ?? Libre2Direct.unknownOutput)")
        logger.log("calibrationInfo i2: \(UserDefaults.standard.sensorCalibrationInfo?.i2.description ?? Libre2Direct.unknownOutput)")
        logger.log("calibrationInfo i3: \(UserDefaults.standard.sensorCalibrationInfo?.i3.description ?? Libre2Direct.unknownOutput)")
        logger.log("calibrationInfo i4: \(UserDefaults.standard.sensorCalibrationInfo?.i4.description ?? Libre2Direct.unknownOutput)")
        logger.log("calibrationInfo i5: \(UserDefaults.standard.sensorCalibrationInfo?.i5.description ?? Libre2Direct.unknownOutput)")
        logger.log("calibrationInfo i6: \(UserDefaults.standard.sensorCalibrationInfo?.i6.description ?? Libre2Direct.unknownOutput)")
        logger.log("sensorState: \(UserDefaults.standard.sensorState?.rawValue ?? Libre2Direct.unknownOutput)")
    }

    public func streamingEnabled(successful: Bool) {
        logger.log("streamingEnabled: \(successful)")
        
        if successful {
            UserDefaults.standard.sensorUnlockCount = 0
        }
    }

    public func canConnect() -> Bool {
        if let _ = UserDefaults.standard.sensorUID, let _ = UserDefaults.standard.sensorPatchInfo, let _ = UserDefaults.standard.sensorCalibrationInfo, let _ = UserDefaults.standard.sensorState {
            logger.log("canConnect: true")
            return true
        }
        
        logger.log("canConnect: false")
        return false
    }

    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        logger.log("didDiscoverServices")
        
        if let services = peripheral.services {
            for service in services {
                peripheral.discoverCharacteristics(nil, for: service)
            }
        }
    }

    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService) {
        logger.log("didDiscoverCharacteristicsFor")
        
        if let characteristics = service.characteristics {
            for characteristic in characteristics {
                if characteristic.uuid == readCharacteristicUuid {
                    readCharacteristic = characteristic
                }

                if characteristic.uuid == writeCharacteristicUuid {
                    writeCharacteristic = characteristic
                    unlock(peripheral)
                }
            }
        }
    }

    public func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        logger.log("didUpdateNotificationStateFor")
        
        reset()
    }

    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        logger.log("didUpdateValueFor")
        
        if let value = characteristic.value {
            // add new value to rxBuffer
            rxBuffer.append(value)
            
            if rxBuffer.count == Libre2Direct.expectedBufferSize {
                guard let sensorUID = UserDefaults.standard.sensorUID, let patchInfo = UserDefaults.standard.sensorPatchInfo, let calibrationInfo = UserDefaults.standard.sensorCalibrationInfo, let sensorType = UserDefaults.standard.sensorType else {
                    scanNfc()
                    return
                }
                
                guard sensorType == .libre2 else {
                    return
                }
                
                do {
                    let decryptedBLE = Data(try Libre2Utility.decryptBLE(sensorUID: sensorUID, data: rxBuffer))
                    let measurements = Libre2Utility.parseBLEData(decryptedBLE, calibrationInfo: calibrationInfo)
                    let sensorData = SensorData(bytes: decryptedBLE, sensorUID: sensorUID, patchInfo: patchInfo, calibrationInfo: calibrationInfo, wearTimeMinutes: measurements.wearTimeMinutes, trend: measurements.trend, history: measurements.history)

                    if let sensorData = sensorData {
                        delegate?.transmitterManager(self, didUpdateSensorData: sensorData)
                    }
                    
                    reset()
                } catch {
                    reset()
                }
            }
        }
    }

    public func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        logger.log("didWriteValueFor")
        
        if characteristic.uuid == writeCharacteristicUuid {
            peripheral.setNotifyValue(true, for: readCharacteristic!)
        }
    }

    public static func canSupportPeripheral(_ peripheral: CBPeripheral) -> Bool {
        peripheral.name?.lowercased().starts(with: "abbott") ?? false
    }
    
    private func scanNfc() {
        libreNFC = LibreNFC(libreNFCDelegate: self)
        libreNFC?.startSession()
    }
    
    private func unlock(_ peripheral: CBPeripheral) {
        logger.log("unlock")
        
        guard let sensorUID = UserDefaults.standard.sensorUID else {
            return
        }
        
        guard let patchInfo = UserDefaults.standard.sensorPatchInfo else {
            return
        }
        
        let unlockCount = (UserDefaults.standard.sensorUnlockCount ?? 0) + 1
        UserDefaults.standard.sensorUnlockCount = unlockCount
        logger.log("unlockCount: \(unlockCount)")
        
        let unlockPayLoad = Data(Libre2Utility.streamingUnlockPayload(sensorUID: sensorUID, info: patchInfo, enableTime: 42, unlockCount: unlockCount))
        logger.log("unlockPayLoad: \(unlockPayLoad)")
        
        _ = writeValueToPeripheral(peripheral, value: unlockPayLoad, type: .withResponse)
    }
}
