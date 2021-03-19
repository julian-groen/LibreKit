//
//  SensorData.swift
//  LibreKit
//
//  Created by Julian Groen on 11/05/2020.
//  Copyright © 2020 Julian Groen. All rights reserved.
//

import Foundation

public struct SensorData {
    let bytes: Data
    let sensorUID: Data
    let patchInfo: Data
    let calibrationInfo: CalibrationInfo
    let wearTimeMinutes: Int
    let trend: [Measurement]
    let history: [Measurement]

    init?(bytes: Data, sensorUID: Data, patchInfo: Data, calibrationInfo: CalibrationInfo, wearTimeMinutes: Int, trend: [Measurement], history: [Measurement]) {
        self.bytes = bytes
        self.sensorUID = sensorUID
        self.patchInfo = patchInfo
        self.calibrationInfo = calibrationInfo
        self.wearTimeMinutes = wearTimeMinutes
        self.trend = trend
        self.history = history
    }

    func trend(reversed: Bool = false) -> [Measurement] {
        return (reversed ? trend.reversed() : trend)
    }

    func history(reversed: Bool = false) -> [Measurement] {
        return (reversed ? history.reversed() : history)
    }
}
