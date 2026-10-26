import SwiftUI

/// A small capsule label, such as "Sample".
///
/// The capsule uses a quiet fill and secondary text, so it never puts accent-colored text on a fill.
struct Badge: View {
    let text: LocalizedStringKey

    init(text: LocalizedStringKey) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
            .padding(.horizontal, Theme.Spacing.xSmall)
            .padding(.vertical, Theme.Spacing.xxSmall / 2)
            .background(.fill.tertiary, in: Capsule())
    }
}

#Preview {
    Badge(text: "Sample")
        .padding()
}
