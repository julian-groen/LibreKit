//
//  UITableView.swift
//  LibreKitUI
//
//  Created by Julian Groen on 13/05/2020.
//  Copyright © 2020 Julian Groen. All rights reserved.
//

import Foundation
import UIKit
import LoopKitUI

extension UITableView {
    func dequeueIdentifiableCell<T: UITableViewCell>(cell: T.Type, for indexPath: IndexPath) -> T {
        return self.dequeueReusableCell(withIdentifier: T.className, for: indexPath) as! T
    }
}
