//
//  ComboBox.swift
//  StateTransfer
//
//  Created by Holger Krupp on 20.02.25.
//

import SwiftUI

struct ComboBox: View {
    @Binding var text: String
    var items: [String]
    var maxItems: Int = 5  // Maximum visible items in the dropdown

    @State private var isDropdownVisible = false
    @State private var selectedIndex: Int = -1  // Track highlighted item for keyboard navigation

    var filteredItems: [String] {
        items.filter { $0.lowercased().contains(text.lowercased()) || text.isEmpty }
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            TextField("", text: $text, onEditingChanged: { isEditing in
                withAnimation {
                    isDropdownVisible = isEditing
                }
            })
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .overlay(
                HStack {
                    Spacer()
                    Image(systemName: "chevron.down")
                        .padding(.trailing, 8)
                        .foregroundColor(.gray)
                        .onTapGesture {
                            withAnimation {
                                isDropdownVisible.toggle()
                            }
                        }
                }
            )
            .onSubmit {
                if selectedIndex >= 0, selectedIndex < filteredItems.count {
                    text = filteredItems[selectedIndex]
                }
                isDropdownVisible = false
            }
            .onKeyPress { event in
                handleKeyPress(event)
            }

            if isDropdownVisible {
                VStack(spacing: 0) {
                    ScrollView {
                        VStack(spacing: 0) {
                            ForEach(filteredItems.prefix(maxItems), id: \.self) { option in
                                let index = filteredItems.firstIndex(of: option) ?? -1
                                Text(option)
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(index == selectedIndex ? Color.gray.opacity(0.3) : Color.white)
                                    .onTapGesture {
                                        text = option
                                        isDropdownVisible = false
                                    }
                            }
                        }
                    }
                    .frame(maxHeight: CGFloat(maxItems) * 30) // Adjust dropdown height
                }
                .background(Color.white)
                .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color.gray.opacity(0.5)))
                .shadow(radius: 3)
                .offset(y: 35)
                .frame(maxWidth: .infinity)
            }
        }
        .frame(width: 250)
    }

    private func handleKeyPress(_ event: KeyEvent) {
        switch event.key {
        case .downArrow:
            if selectedIndex < filteredItems.count - 1 {
                selectedIndex += 1
            }
        case .upArrow:
            if selectedIndex > 0 {
                selectedIndex -= 1
            }
        case .return:
            if selectedIndex >= 0, selectedIndex < filteredItems.count {
                text = filteredItems[selectedIndex]
            }
            isDropdownVisible = false
        case .escape:
            isDropdownVisible = false
        default:
            break
        }
    }
}

extension View {
    func onKeyPress(perform action: @escaping (KeyEvent) -> Void) -> some View {
        self.modifier(KeyPressModifier(action: action))
    }
}

// Custom Keyboard Modifier
struct KeyPressModifier: ViewModifier {
    let action: (KeyEvent) -> Void
    
    func body(content: Content) -> some View {
        content
            .overlay(
                KeyEventHandlingView(action: action)
                    .frame(width: 0, height: 0) // Invisible overlay
            )
    }
}

// Bridge SwiftUI to AppKit for Key Events (macOS Only)
#if os(macOS)
import AppKit

struct KeyEventHandlingView: NSViewRepresentable {
    let action: (KeyEvent) -> Void

    func makeNSView(context: Context) -> NSView {
        let view = KeyCaptureView()
        view.action = action
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}

    class KeyCaptureView: NSView {
        var action: ((KeyEvent) -> Void)?

        override var acceptsFirstResponder: Bool { true }

        override func keyDown(with event: NSEvent) {
            action?(KeyEvent(event: event))
        }
    }
}

struct KeyEvent {
    enum Key {
        case upArrow, downArrow, `return`, escape, other
    }

    let key: Key

    init(event: NSEvent) {
        switch event.keyCode {
        case 126: key = .upArrow
        case 125: key = .downArrow
        case 36: key = .return
        case 53: key = .escape
        default: key = .other
        }
    }
}
#endif

#Preview {
    @Previewable @State var text = ""
    let options: [String] = ["eins", "zwei", "drei"]
    ComboBox(text: $text, items: options)
}
