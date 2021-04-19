//
//  GlucoseTargetRangeSetting.swift
//  LibreKitUI
//
//  Created by Julian Groen on 17/03/2021.
//  Copyright © 2021 Julian Groen. All rights reserved.
//

import SwiftUI
import LoopKit
import LoopKitUI
import HealthKit


struct GlucoseTargetRangeSetting<ExpandedContent: View>: View {
    
    @Binding var isEditing: Bool
    @Binding var value: DoubleRange
    let preferredUnit: HKUnit
    var expanded: () -> ExpandedContent
    
    var body: some View {
        ExpandableSetting(
            isEditing: $isEditing,
            leadingValueContent: {
                Text("Target Range", comment: "Title text for specifing target range")
            },
            trailingValueContent: {
                GuardrailConstrainedQuantityRangeView(
                    range: value.quantityRange(for: .milligramsPerDeciliter),
                    unit: preferredUnit,
                    guardrail: Guardrail.bloodglucoseGuardrail(),
                    isEditing: isEditing,
                    forceDisableAnimations: true
                )
            },
            expandedContent: expanded
        )
    }
}

struct GlucoseTargetRangeItem: View {
    
    let value: DoubleRange
    let preferredUnit: HKUnit
    
    var body: some View {
        GlucoseTargetRangeSetting(
            isEditing: .constant(false),
            value: .constant(value),
            preferredUnit: preferredUnit,
            expanded: { EmptyView() }
        )
    }
}
