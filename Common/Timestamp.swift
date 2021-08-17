//
//  Timestamp.swift
//  LibreKit
//
//  Created by Julian Groen on 17/08/2021.
//  Copyright © 2021 Julian Groen. All rights reserved.
//

import Foundation


extension Date {
    init?(timestamp: TimeInterval?) {
        guard let intervalSince1970 = timestamp else { return nil }
        self.init(timeIntervalSince1970: intervalSince1970)
    }
}
