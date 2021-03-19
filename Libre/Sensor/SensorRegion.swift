//
//  SensorRegion.swift
//  LibreKit
//
//  Created by Reimar Metzen on 18.03.21.
//  Copyright © 2021 Mark Wilson. All rights reserved.
//

import Foundation

public enum SensorRegion: String {
    case unknown = "Unknown"
    case european = "European"
    case usa = "USA"
    case australian = "Australian"
    case eastern = "Eastern"

    init() {
        self = .unknown
    }

    init(patchInfo: Data) {
        switch patchInfo[3] {
        case 0:
            self = .unknown
        case 1:
            self = .european
        case 2:
            self = .usa
        case 4:
            self = .australian
        case 8:
            self = .eastern
        default:
            self = .unknown
        }
    }
}
