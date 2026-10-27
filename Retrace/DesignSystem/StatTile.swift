import SwiftUI

/// A labeled number, such as "DISTANCE 1.2 km".
struct StatTile: View {
    let title: LocalizedStringKey
    let value: String

    init(title: LocalizedStringKey, value: String) {
        self.title = title
        self.value = value
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xxSmall) {
            Text(title)
                .font(.caption)
                .textCase(.uppercase)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title2.weight(.semibold).monospacedDigit())
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    HStack {
        StatTile(title: "Distance", value: "1.2 km")
        StatTile(title: "Elapsed", value: "14m 5s")
    }
    .padding()
}
