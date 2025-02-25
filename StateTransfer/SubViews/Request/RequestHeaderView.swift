//
//  RequestHeaderView.swift
//  StateTransfer
//
//  Created by Holger Krupp on 19.02.25.
//

import SwiftUI

enum FieldType: String {
    case header
    case parameter
}

struct RequestHeaderView: View {
    @Binding var header: [HeaderEntry]
   
    @State private var sortOrder = [KeyPathComparator(\HeaderEntry.key)]
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
                HeaderFieldSelector(object: Binding(
                    get: { object.key },
                    set: { newValue in
                        if let index = header.firstIndex(where: { $0.id == object.id }) {
                            /*
                            if newValue != header[index].key {
                                header[index].value = ""
                            }
                             */
                            header[index].key = newValue
                            
                        }
                      
                    }
                ))
                
                 
            }
            
            TableColumn("Header Value") { object in
                HeaderValueSelector(
                    object: Binding(
                        get: { object.value },
                        set: { newValue in
                            if let index = header.firstIndex(where: { $0.id == object.id }) {
                                header[index].value = newValue
                            }
                        }
                    ),
                    fieldValues: {
                        if let field = HeaderFields(rawValue: object.key) {
                            return field.values
                        }
                        return []
                    }()
                )
            }
        }
        
        
        .onChange(of: sortOrder) { _, sortOrder in
                   header.sort(using: sortOrder)
               }
        HStack{
            Spacer()
            Button {
                header.append(HeaderEntry(id: UUID(), active: false, key: "header", value: "value"))
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

