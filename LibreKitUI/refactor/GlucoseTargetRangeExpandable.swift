//
//  GlucoseTargetRangeExpandable.swift
//  LibreKitUI
//
//  Created by Julian Groen on 15/03/2021.
//  Copyright © 2021 Julian Groen. All rights reserved.
//

import SwiftUI
import LoopKit
import LoopKitUI
import HealthKit

struct GlucoseTargetRangeExpandable<ExpandedContent: View>: View {
    
    @Binding var isEditing: Bool
    let selectedUnit: HKUnit
    var expandedContent: () -> ExpandedContent
    
    var body: some View {
        ExpandableSetting(
            isEditing: $isEditing,
            leadingValueContent: {
                Text("Target Range", comment: "Title text for specifing target range")
            },
            trailingValueContent: {
                GuardrailConstrainedQuantityRangeView(
                    range: nil,
                    unit: selectedUnit,
                    guardrail: defaultTargetRange,
                    isEditing: isEditing,
                    forceDisableAnimations: true
                )
            },
            expandedContent: expandedContent
        )
    }
    
    let defaultTargetRange = Guardrail(absoluteBounds: 54...270, recommendedBounds: 70...180, unit: .milligramsPerDeciliter, startingSuggestion: 70)
}
