//
//  ManagerSettingsView.swift
//  LibreKitUI
//
//  Created by Julian Groen on 16/12/2020.
//  Copyright © 2020 Julian Groen. All rights reserved.
//

import SwiftUI
import LoopKit
import LoopKitUI
import HealthKit

struct ManagerSettingsView<Model>: View where Model: ManagerSettingsViewModel {
    
    @State var showingDeleteConfirmation = false
       
    @Environment(\.glucoseTintColor) var glucoseTintColor
    @Environment(\.guidanceColors) var guidanceColors
    
    @ObservedObject var viewModel: Model
 
    var body: some View {
        List {
            overviewSection
            activitySection
            deletionSection
        }
        .insetGroupedListStyle()
        .navigationBarTitle(Text("FreeStyle Libre", comment: "FreeStyle Libre"))
        .navigationBarItems(trailing: dismissButton)
    }
    
    // TODO: viewmodel variable
    private var overviewSection: some View {
        Section(header: Spacer()) {
            LazyVStack {
                VStack(alignment: .center) {
                    Image(uiImage: UIImage(named: "FreeStyle Libre") ?? UIImage())
                        .resizable()
                        .aspectRatio(contentMode: ContentMode.fit)
                        .frame(height: 85)
                        .padding([.top, .horizontal])
                }.frame(maxWidth: .infinity)

                VStack(spacing: 10) {
                    HStack(alignment: .lastTextBaseline, spacing: 3) {
                        Text("Sensor expires in")
                            .foregroundColor(.secondary)
                        Spacer()
                        UnitView(value: 13, unit: "days")
                    }
                    ProgressView(progress: CGFloat(0.1)).accentColor(.blue)
                }

                VStack(alignment: .leading, spacing: 0) {
                    HStack(alignment: .center) {
                        Image(systemName: "battery.100")
                            .foregroundColor(.blue)
                            .font(.system(size: 28))
                            .padding(.leading, -3)
                        UnitView(value: 94, unit: "%")
                        Spacer()
                        Image(systemName: "waveform.path.ecg")
                            .foregroundColor(.blue)
                            .font(.system(size: 28))
                        Text(viewModel.cgmManager.connection ?? "Unknown")
                            .font(.system(size: 20))
                            .fontWeight(.bold)
                    }
                }
            }.padding(.bottom, 8)
        }
    }
    
    private var activitySection: some View {
        Section(header: SectionHeader(label: "Activity")) {
            HStack {
                Text("Glucose", comment: "Title describing glucose value")
                Spacer()
//                GuardrailConstrainedQuantityView(
//                    value: nil,
//                    unit: .millimolesPerLiter,
//                    guardrail: .suspendThreshold,
//                    isEditing: false,
//                    // Workaround for strange animation behavior on appearance
//                    forceDisableAnimations: true
//                )
            }
            LabeledValueView(label: LocalizedString("Last reading", comment: "Title describing last reading"), value: nil)
            LabeledValueView(label: LocalizedString("Trend", comment: "Title describing glucose trend"), value: nil)
        }.lineLimit(1)
    }

    private var deletionSection: some View {
        Section(header: Spacer()) {
            Button(action: {
                showingDeleteConfirmation = true
            }, label: {
                HStack {
                    Spacer()
                    Text("Delete CGM", comment: "Title text for the button to remove a CGM from Loop")
                        .foregroundColor(guidanceColors.critical)
                    Spacer()
                }
            }).actionSheet(isPresented: $showingDeleteConfirmation) {
                deleteConfirmationActionSheet
            }
        }
    }
    
    private var deleteConfirmationActionSheet: ActionSheet {
        ActionSheet(title: Text("Are you sure you want to delete this CGM?", comment: "Confirmation message for deleting a CGM"), buttons: [
            .destructive(Text("Delete CGM", comment: "Title text for the button to remove a CGM from Loop")) { viewModel.notifyDeletion() },
            .cancel()
        ])
    }
    
    private var dismissButton: some View {
        Button(action: { viewModel.completion?() }) { Text("Done").bold() }
    }
}








//public struct CGMSettingsView: View {
//
//    @Environment(\.dismiss) private var dismiss
//
//    public var body: some View {
//        List {
//            overviewSection
//           // activitySection
//            configurationSection
//            transmitterSection
//        }
//        .insetGroupedListStyle()
//        .navigationBarTitle(Text(LocalizedString("FreeStyle Libre", comment: "FreeStyle Libre")))
//        .navigationBarItems(trailing: dismissButton)
//    }
//}
//
//extension CGMSettingsView {
//
//    private var dismissButton: some View {
//        Button(action: dismiss) {
//            Text("Done").bold()
//        }
//    }
//
//    private var overviewSection: some View {
//        LazyVStack {
//            VStack(alignment: .center) {
//                Image(uiImage: UIImage(named: "libre") ?? UIImage())
//                    .resizable()
//                    .aspectRatio(contentMode: ContentMode.fit)
//                    .frame(height: 85)
//                    .padding([.top, .horizontal])
//            }.frame(maxWidth: .infinity)
//
//            VStack(spacing: 10) {
//                HStack(alignment: .lastTextBaseline, spacing: 3) {
//                    Text("Sensor expires in")
//                        .foregroundColor(.secondary)
//                    Spacer()
//                    UnitView(value: 13, unit: "days")
//                }
//                ProgressView(progress: CGFloat(0.1)).accentColor(.blue)
//            }
//
//            VStack(alignment: .leading, spacing: 0) {
//                HStack(alignment: .center) {
//                    Image(systemName: "battery.100")
//                        .foregroundColor(.blue)
//                        .font(.system(size: 28))
//                    UnitView(value: 94, unit: "%")
//                    Spacer()
//                    Image(systemName: "waveform.path.ecg")
//                        .foregroundColor(.blue)
//                        .font(.system(size: 28))
//                    Text("Ready")
//                        .font(.system(size: 20))
//                        .fontWeight(.bold)
//                }
//            }
//        }.padding(.bottom, 8)
//    }
//
//    private var activitySection: some View {
//        Section(header: SectionHeader(label: "Activity")) {
//            HStack {
//                Text(LocalizedString("Glucose", comment: "Title describing glucose value"))
//                Spacer()
//                GuardrailConstrainedQuantityView(
//                    value: nil,
//                    unit: .millimolesPerLiter,
//                    guardrail: .suspendThreshold,
//                    isEditing: false,
//                    // Workaround for strange animation behavior on appearance
//                    forceDisableAnimations: true
//                )
//            }
//            LabeledValueView(label: "Last reading", value: nil)
//                .lineLimit(1)
//            LabeledValueView(label: LocalizedString("Trend", comment: "Title describing glucose trend"), value: nil)
//                .lineLimit(1)
//        }
//    }
//
//    private var transmitterSection: some View {
//        Section(header: SectionHeader(label: LocalizedString("Transmitter", comment: "Transmitter"))) {
//            NavigationLink(destination: EmptyView()) {
//                LabeledValueView(label: LocalizedString("Transmitter", comment: "Transmitter"), value: nil)
//                    .lineLimit(1)
//            }
//        }
//    }
//
//    private var configurationSection: some View {
//        Section(header: SectionHeader(label: LocalizedString("Configuration", comment: "Section title for configuration"))) {
//            NavigationLink(destination: EmptyView()) {
//                LabeledValueView(label: LocalizedString("Transmitter", comment: "Transmitter"), value: nil)
//                    .lineLimit(1)
//            }
//        }
//    }
//
//    private func unit(value: Int, units: String) -> some View {
//        HStack(alignment: .lastTextBaseline) {
//            Text(String(value)).font(.system(size: 28)).fontWeight(.bold)
//            Text(units).foregroundColor(.secondary)
//        }
//    }
//}
//

struct UnitView: View {
    var value: Int
    var unit: String

    var body: some View {
        HStack(alignment: .lastTextBaseline) {
            Text(String(value)).font(.system(size: 28)).bold()
            Text(unit).foregroundColor(.secondary)
        }
    }
}

#if DEBUG
struct ManagerSettingsView_Previews: PreviewProvider {
    
    static var previews: some View {
        NavigationView {
            ManagerSettingsView(viewModel: ManagerSettingsViewModel())
        }.preferredColorScheme(.dark)
    }
}
#endif
