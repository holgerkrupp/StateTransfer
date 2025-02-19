//
//  RequestHeaderView.swift
//  StateTransfer
//
//  Created by Holger Krupp on 19.02.25.
//

import SwiftUI

struct RequestHeaderView: View {
    @Binding var header: [HeaderEntry]
    @State private var sortOrder = [KeyPathComparator(\HeaderEntry.field)]
    
    @State private var selection: Set<HeaderEntry.ID> = []
    
    var body: some View {
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
            
            TableColumn("Header Field"){ object in
                TextField("", text: Binding(
                    get: { object.field },
                    set: { newValue in
                        if let index = header.firstIndex(where: { $0.id == object.id }) {
                            header[index].field = newValue
                        }
                    }
                )) 
            }
            
            TableColumn("Header Value"){ object in
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
        .padding()
        .onChange(of: sortOrder) { _, sortOrder in
                   header.sort(using: sortOrder)
               }
        HStack{
            Button {
                header.append(HeaderEntry(id: UUID(), active: false, field: "new", value: ""))
            } label: {
                Text("+")
            }
            Button {
                header.removeAll { selection.contains($0.id) }
            } label: {
                Text("-")
            }
        }
    }
}

#Preview {
    @Previewable @State var headers: [HeaderEntry] = []
    RequestHeaderView(header: $headers)
}
