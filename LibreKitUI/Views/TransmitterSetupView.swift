//
//  TransmitterSetupView.swift
//  LibreKitUI
//
//  Created by Julian Groen on 16/12/2020.
//  Copyright © 2020 Julian Groen. All rights reserved.
//

import SwiftUI
import LoopKit
import LoopKitUI
import CoreBluetooth

struct TransmitterSetupView<Model>: View where Model: TransmitterSetupViewModel {
    
    @State var selectedIdentifier: UUID?
    
    @Environment(\.glucoseTintColor) var glucoseTintColor
    @Environment(\.guidanceColors) var guidanceColors
    
    @ObservedObject var viewModel: Model
 
    var body: some View {
        VStack(spacing: 0) {
            List {
                Section(header: Spacer()) {
                    HStack {
                        Image(systemName: "info.circle")
                           .foregroundColor(.blue)
                           .font(.system(size: 20))
                           .padding(.trailing, 8)
                       Text("If your transmitter does not appear, it could mean that it is currently not supported.")
                           .font(.footnote)
                           .foregroundColor(.secondary)
                    }
                }
                Section(header: HStack {
                    SectionHeader(label: "Transmitters", style: .regular)
                    ActivityIndicator(isAnimating: .constant(true), style: .medium)
                }) {
                    ForEach(viewModel.transmitters, id: \.identifier) { transmitter in
                        TransmitterSelectorView(transmitter: transmitter, selectedID: $selectedIdentifier)
                    }
                }
            }
            .insetGroupedListStyle()
            actionArea
        }
        .edgesIgnoringSafeArea(.bottom)
        .navigationBarTitle(Text("Transmitter Setup"), displayMode: .large)
        .navigationBarItems(trailing: dismissButton)
    }
    
    private var actionArea: some View {
        VStack(spacing: 0) {
            Button<Text>(action: {
                UserDefaults.standard.transmitterIdentifier = selectedIdentifier
                viewModel.didContinue?()
            }, label: {
                Text("Continue")
            })
            .buttonStyle(ActionButtonStyle(.primary))
            .disabled(selectedIdentifier == nil)
            .padding()
        }
        .background(Color(.secondarySystemGroupedBackground).shadow(radius: 5))
    }
    
    private var dismissButton: some View {
        Button(action: { viewModel.didCancel?() }) { Text("Cancel").bold() }
    }
}

struct TransmitterSelectorView: View {
    
    var transmitter: CBPeripheral
    @Binding var selectedID: UUID?
    
    var body: some View {
        Button(action: {
            selectedID = transmitter.identifier
        }, label: {
            HStack(alignment: .center) {
                Image(systemName: selected() ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(selected() ? .blue : .gray)
                    .font(.system(size: 20))
                    .padding(.trailing, 8)
                Text(transmitter.name ?? "unidentified")
            }
        })
        .foregroundColor(.primary)
    }
    
    func selected() -> Bool {
        return selectedID == transmitter.identifier
    }
}

#if DEBUG
struct TransmitterSetupView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            TransmitterSetupView(viewModel: TransmitterSetupViewModel())
        }.preferredColorScheme(.light)
    }
}
#endif
