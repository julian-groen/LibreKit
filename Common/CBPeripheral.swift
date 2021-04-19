//
//  CBPeripheral.swift
//  LibreKit
//
//  Created by Julian Groen on 18/04/2021.
//  Copyright © 2021 Julian Groen. All rights reserved.
//

import CoreBluetooth


extension CBPeripheral {
    public func transmitterType() -> Transmitter.Type? {
        return allTransmitters.enumerated().compactMap { $0.element.supported(self) ? $0.element : nil }.first
    }
}
