//
//  AnnotatedTableViewCell.swift
//  LibreKitUI
//
//  Created by Julian Groen on 13/05/2020.
//  Copyright © 2020 Julian Groen. All rights reserved.
//

import Foundation
import UIKit

class AnnotatedTableViewCell<T>: UITableViewCell {
    
    public var annotation: T?

    override init(style: UITableViewCellStyle = .subtitle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
    }
    
}
