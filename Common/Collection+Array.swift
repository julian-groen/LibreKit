//
//  Collection+Array.swift
//  LibreKit
//
//  Created by Julian Groen on 13/05/2020.
//  Copyright © 2020 Julian Groen. All rights reserved.
//

import Foundation


extension Collection {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

extension Array where Element: Hashable {
    func removingDuplicates() -> [Element] {
        var addedDict = [Element: Bool]()
        return filter { addedDict.updateValue(true, forKey: $0) == nil }
    }

    mutating func removeDuplicates() {
        self = self.removingDuplicates()
    }
}
