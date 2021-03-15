//
//  CBPeripheral.swift
//  LibreKit
//
//  Created by Julian Groen on 28/12/2020.
//  Copyright © 2020 Julian Groen. All rights reserved.
//

import Foundation
import CoreBluetooth

extension CBPeripheral {
    
    var compatible: Bool { type() != nil }
    
    func type() -> Transmitter.Type? {
        let result = allTransmitters.enumerated().compactMap { $0.element.supported(self) ? $0.element : nil }
        return (result.isEmpty ? nil : result.first)
    }
}
