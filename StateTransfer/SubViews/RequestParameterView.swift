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
            
            
            TableColumn("Parameter Name"){ object in
               
                    HeaderFieldSelector(object: Binding(
                        get: { object.field },
                        set: { newValue in
                            if let index = header.firstIndex(where: { $0.id == object.id }) {
                                header[index].field = newValue
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
        HStack{
            Picker("", selection: $parameterEncoding, content: {
                ForEach(ParameterEncoding.allCases, id: \.self) { encoding in
                    Text(encoding.rawValue).tag(encoding)
                }
            })
            .frame(width: 200)
            Spacer()
            Button {
                header.append(HeaderEntry(id: UUID(), active: false, field: "parameter", value: "value"))
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
    @Previewable @State var parameterEncoding: ParameterEncoding = .json
    RequestHeaderView(header: $headers)
}
