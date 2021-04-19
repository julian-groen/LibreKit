//
//  LocalizedString.swift
//  LibreKit
//
//  Created by Julian Groen on 12/12/2020.
//  Copyright © 2020 Julian Groen. All rights reserved.
//

import Foundation
import SwiftUI


func LocalizedString(_ key: String, tableName: String? = nil, value: String? = nil, comment: String) -> String {
    if let value = value {
        return NSLocalizedString(key, tableName: tableName, bundle: FrameworkBundle.main, value: value, comment: comment)
    } else {
        return NSLocalizedString(key, tableName: tableName, bundle: FrameworkBundle.main, comment: comment)
    }
}

extension DefaultStringInterpolation {
    mutating func appendInterpolation<T>(_ optional: T?) {
        appendInterpolation(String(describing: optional))
    }
}

extension Text {
    init(_ key: String, comment: String) {
        self.init(LocalizedString(key, comment: comment))
    }
}
