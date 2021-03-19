//
//  CBPeripheral.swift
//  Libre2Client
//
//  Created by Julian Groen on 13/05/2020.
//  Copyright © 2020 Julian Groen. All rights reserved.
//

import Foundation
import CoreBluetooth
import Libre2Client

extension CBPeripheral {
    var type: Transmitter.Type? {
        let result = allTransmitters.enumerated().compactMap { $0.element.canSupportPeripheral(self) ? $0.element : nil }
        return (result.isEmpty ? nil : result.first)
    }
    
    var compatible: Bool {
        return (self.type != nil)
    }
}
