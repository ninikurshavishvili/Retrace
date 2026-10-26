import SwiftUI

/// Design tokens shared by every screen (APP_PLAN.md §6).
///
/// The accent color "Trail" lives in the `AccentColor` asset, so standard controls pick it up as
/// the tint. Use it for lines, dots, icons and text on plain backgrounds, never as a fill behind text.
enum Theme {
    /// The spacing scale: 4 · 8 · 12 · 16 · 24 · 32.
    enum Spacing {
        static let xxSmall: CGFloat = 4
        static let xSmall: CGFloat = 8
        static let small: CGFloat = 12
        static let medium: CGFloat = 16
        static let large: CGFloat = 24
        static let xLarge: CGFloat = 32
    }

    enum Radius {
        static let thumbnail: CGFloat = 12
        static let card: CGFloat = 20
    }
}

extension View {
    /// Places the content on a material card with the card corner radius.
    func card() -> some View {
        padding(Theme.Spacing.medium)
            .background(
                .regularMaterial,
                in: RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
            )
    }
}

#Preview {
    VStack(alignment: .leading, spacing: Theme.Spacing.xSmall) {
        Label("Trail", systemImage: "figure.walk")
            .foregroundStyle(.tint)
        Text("Cards use the regular material.")
            .foregroundStyle(.secondary)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .card()
    .padding()
    .background(Color(.systemGroupedBackground))
}
