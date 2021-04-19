//
//  UIImage.swift
//  LibreKit
//
//  Created by Julian Groen on 08/12/2020.
//  Copyright © 2020 Mark Wilson. All rights reserved.
//

import Foundation
import SwiftUI


extension UIImage {
    convenience init?(named name: String) {
        self.init(named: name, in: FrameworkBundle.main, compatibleWith: nil)
    }
}
