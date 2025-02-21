//
//  Created by Akash Gurnale on 23/12/24.
//

import SwiftUI
import Combine

struct HeaderFieldSelector: View {
    @Binding var object: String
    var body: some View {
        TextField("", text: $object)
        .textInputSuggestions {
            ForEach(HeaderFields.allCases, id: \.self) { value in
                
                Text(value.rawValue)
                    .onTapGesture {
                        object = value.rawValue
                    }
                }
            }
    }
}

struct HeaderValueSelector: View {
    @Binding var object: String
    var fieldValues: [String]
    var body: some View {
        
        TextField("", text: $object)
        
            .textInputSuggestions {
             
                    // Only show values if it's a valid HeaderFields case
                    ForEach(fieldValues, id: \.self) { value in
                        Text(value)
                            .onTapGesture {
                                object = value
                            }
                    }
                
                
            }
    }
}
