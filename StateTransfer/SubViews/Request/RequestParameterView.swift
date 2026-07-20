//
//  RequestHeaderView.swift
//  StateTransfer
//
//  Created by Holger Krupp on 19.02.25.
//

import SwiftUI



struct RequestParamterView: View {
    @Binding var header: [HeaderEntry]
    @Binding var parameterEncoding: ParameterEncoding
   
    @State private var sortOrder = [KeyPathComparator(\HeaderEntry.key)]
    
    @State private var selection: Set<HeaderEntry.ID> = []
    
    var body: some View {
        VStack(spacing: 8) {
            Table(header, selection: $selection, sortOrder: $sortOrder) {
            
            TableColumn("") { object in
                            Toggle(isOn: Binding(
                                get: { object.active },
                                set: { newValue in
                                    if let index = header.firstIndex(where: { $0.id == object.id }) {
                                        header[index].active = newValue
                                    }
                                }
                            )) {
                                EmptyView()
                            }
                            .toggleStyle(CheckboxToggleStyle()) // Makes it look like a checkbox
                        }
            .width(20)
            
            
            TableColumn("Parameter Name"){ object in
               
                    HeaderFieldSelector(object: Binding(
                        get: { object.key },
                        set: { newValue in
                            if let index = header.firstIndex(where: { $0.id == object.id }) {
                                header[index].key = newValue
                            }
                        }
                    ))
               
                 
            }
            
            TableColumn("Parameter Value"){ object in
                TextField("", text: Binding(
                    get: { object.value },
                    set: { newValue in
                        if let index = header.firstIndex(where: { $0.id == object.id }) {
                            header[index].value = newValue
                        }
                    }
                ))
            }
            }
            .onChange(of: sortOrder) { _, sortOrder in
                header.sort(using: sortOrder)
            }

            HStack(spacing: 8) {
                Picker("Encoding", selection: $parameterEncoding) {
                    ForEach(ParameterEncoding.allCases, id: \.self) { encoding in
                        Text(encoding.rawValue).tag(encoding)
                    }
                }
                .labelsHidden()
                .frame(width: 200)

                Spacer()

                Button {
                    header.append(HeaderEntry(
                        id: UUID(),
                        active: true,
                        key: "parameter",
                        value: "value"
                    ))
                } label: {
                    Label("Add Parameter", systemImage: "plus")
                        .labelStyle(.iconOnly)
                }
                .help("Add parameter")

                Button {
                    header.removeAll { selection.contains($0.id) }
                } label: {
                    Label("Remove Selected Parameters", systemImage: "minus")
                        .labelStyle(.iconOnly)
                }
                .disabled(selection.isEmpty)
                .help("Remove selected parameters")
            }
            .buttonStyle(.borderless)
            .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#Preview {
    @Previewable @State var headers: [HeaderEntry] = []
    @Previewable @State var parameterEncoding: ParameterEncoding = .json
    RequestHeaderView(header: $headers)
}
