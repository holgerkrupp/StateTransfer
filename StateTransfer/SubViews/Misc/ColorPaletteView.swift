import SwiftUI

struct ColorPaletteView: View {
    let colorDefinitions: [(name: String, color: Color)] = [
        ("Primary", .primary), ("Secondary", .secondary), ("Accent", .accentColor),
        ("Black", .black), ("Blue", .blue), ("Brown", .brown),
        ("Clear", .clear), ("Cyan", .cyan), ("Gray", .gray),
        ("Green", .green), ("Indigo", .indigo), ("Mint", .mint),
        ("Orange", .orange), ("Pink", .pink), ("Purple", .purple),
        ("Red", .red), ("Teal", .teal), ("White", .white), ("Yellow", .yellow)
    ]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(colorDefinitions, id: \.name) { colorItem in
                    RoundedRectangle(cornerRadius: 8)
                        .fill(colorItem.color)
                        .frame(width: 50, height: 50)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.primary.opacity(0.2), lineWidth: 1)
                        )
                        .help(colorItem.name) // Tooltip with color name
                }
            }
            .padding()
        }
    }
}

struct ColorPaletteView_Previews: PreviewProvider {
    static var previews: some View {
        ColorPaletteView()
            .previewLayout(.sizeThatFits)
    }
}
