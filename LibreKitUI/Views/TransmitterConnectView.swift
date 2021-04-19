//
//  TransmitterConnectView.swift
//  LibreKitUI
//
//  Created by Julian Groen on 08/04/2021.
//  Copyright © 2021 Julian Groen. All rights reserved.
//

import SwiftUI
import LibreKit
import LoopKit
import LoopKitUI


struct TransmitterConnectView<Model>: View where Model: TransmitterConnectModel {

    @Environment(\.guidanceColors) var guidanceColors
    @Environment(\.glucoseTintColor) var glucoseTintColor
    
    @ObservedObject var viewModel: Model
    @State var hasSelected: Transmitter?
    
    var body: some View {
        VStack(spacing: 0) {
            List {
                Section(header: Spacer()) {
                    HStack {
                        Image(systemName: "info.circle")
                           .foregroundColor(.blue).font(.system(size: 20)).padding(.trailing, 8)
                        Text(descriptiveText)
                           .font(.footnote).foregroundColor(.secondary)
                    }
                }
                Section(header: HStack {
                    SectionHeader(label: "Transmitters", style: .regular)
                    ActivityIndicator(isAnimating: .constant(true), style: .medium)
                }) {
                    ForEach(viewModel.transmitters, id: \.peripheral.identifier) { transmitter in
                        TransmitterSelectorView(transmitter: transmitter, selected: Binding(
                            get: { self.hasSelected },
                            set: { newValue in
                                if let transmitter = hasSelected { viewModel.disconnect(transmitter) }
                                if let newTransmitter = newValue { viewModel.connect(newTransmitter) }
                                self.hasSelected = newValue
                            }
                        ))
                    }
                }
            }
            .insetGroupedListStyle()
            actionArea
        }
        .edgesIgnoringSafeArea(.bottom)
        .navigationBarTitle(Text("Connect Transmitter"), displayMode: .large)
        .navigationBarItems(trailing: dismissButton)
    }
    
    var descriptiveText: String {
        LocalizedString(
            "If your transmitter does not appear, it could mean that it is currently not supported.",
            comment: "Header info description for transmitter connection page"
        )
    }
    
    var actionArea: some View {
        VStack(spacing: 0) {
            Button<Text>(action: {
                viewModel.hasContinued?(viewModel.cgmManager)
            }) {
                Text("Continue", comment: "Action title for connection continue")
            }
            .disabled(hasSelected == nil)
            .buttonStyle(ActionButtonStyle(.primary))
            .padding()
        }
        .background(Color(.secondarySystemGroupedBackground).shadow(radius: 5))
    }
    
    var dismissButton: some View {
        Button(action: { viewModel.hasCancelled?() }) { Text("Cancel").bold() }
    }
}

private struct TransmitterSelectorView: View {
    
    var transmitter: Transmitter
    @Binding var selected: Transmitter?
    
    var body: some View {
        Button(action: {
            selected = transmitter
        }, label: {
            HStack(alignment: .center) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .blue : .gray)
                    .font(.system(size: 20)).padding(.trailing, 8)
                Text(transmitter.name)
            }
        }).foregroundColor(.primary)
    }
    
    var isSelected: Bool { selected === transmitter }
}
