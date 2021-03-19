//
//  LocalizedString.swift
//  Libre2Client
//
//  Created by Julian Groen on 11/05/2020.
//  Copyright © 2020 Julian Groen. All rights reserved.
//

import Foundation

internal class FrameworkBundle {
    static let main = Bundle(for: FrameworkBundle.self)
}

func LocalizedString(_ key: String, tableName: String? = nil, value: String? = nil) -> String {
    if let value = value {
        return NSLocalizedString(key, tableName: tableName, bundle: FrameworkBundle.main, value: value, comment: "") //, comment: comment
    } else {
        return NSLocalizedString(key, tableName: tableName, bundle: FrameworkBundle.main, comment: "") //, comment: comment
    }
}

extension DefaultStringInterpolation {
    mutating func appendInterpolation<T>(_ optional: T?) {
        appendInterpolation(String(describing: optional))
    }
}
