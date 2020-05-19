//
//  IdentifiableClass.swift
//  LibreKitUI
//
//  Created by Julian Groen on 13/05/2020.
//  Copyright © 2020 Julian Groen. All rights reserved.
//

import Foundation
import UIKit

protocol IdentifiableClass: class {
    static var className: String { get }
}

extension IdentifiableClass {
    static var className: String {
        String(describing: Self.self)
    }
}

protocol NibLoadable: IdentifiableClass {
    static func nib() -> UINib
}

extension NibLoadable {
    static func nib() -> UINib {
        return UINib(nibName: className, bundle: Bundle(for: self))
    }
}

extension UITableViewCell: IdentifiableClass { }
