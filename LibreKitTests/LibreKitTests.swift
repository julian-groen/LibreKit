//
//  LibreKitTests.swift
//  LibreKitTests
//
//  Created by Julian Groen on 23/08/2021.
//  Copyright © 2021 Julian Groen. All rights reserved.
//

import XCTest
@testable import LibreKit

class LibreKitTests: XCTestCase {

    func testSensorPacketParse() throws {
        let path = Bundle(for: LibreKitTests.self).path(forResource: "1587513080.0655909", ofType: "txt")!
        let sensorData = Data(hexadecimal: try String(contentsOf: URL(fileURLWithPath: path)))!
        if let packet = SensorPacket.parse(from: sensorData, serial: Data()) {
            let algorithm_parameters: AlgorithmParameters = AlgorithmParameters(bytes: packet.rawSensorData)
            
            var measurements: [LibreKit.Measurement] = [LibreKit.Measurement]()
            measurements.append(contentsOf: packet.trend(parameters: algorithm_parameters, reference: measurements.last))
            SavitzkyGolay.smooth(measurements: &measurements, iterations: 2) // trend smoothing
    
            dump(measurements)
        }
    }
}

extension Data {
    init?(hexadecimal: String) {
        self.init(capacity: hexadecimal.utf16.count / 2)

        // Convert 0 ... 9, a ... f, A ...F to their decimal value,
        // return nil for all other input characters
        func decodeNibble(u: UInt16) -> UInt8? {
            switch u {
            case 0x30 ... 0x39:  // '0'-'9'
                return UInt8(u - 0x30)
            case 0x41 ... 0x46:  // 'A'-'F'
                return UInt8(u - 0x41 + 10)  // 10 since 'A' is 10, not 0
            case 0x61 ... 0x66:  // 'a'-'f'
                return UInt8(u - 0x61 + 10)  // 10 since 'a' is 10, not 0
            default:
                return nil
            }
        }

        var even = true
        var byte: UInt8 = 0
        for c in hexadecimal.utf16 {
            guard let val = decodeNibble(u: c) else { return nil }
            if even {
                byte = val << 4
            } else {
                byte += val
                self.append(byte)
            }
            even = !even
        }
        guard even else { return nil }
    }
}
