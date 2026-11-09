import SwiftUI

enum ArcTheme {
    static let left = Color(red: 0.37, green: 0.88, blue: 0.85)
    static let right = Color(red: 1, green: 0.49, blue: 0.57)
    static let ink = Color(red: 0.055, green: 0.075, blue: 0.11)
    static let stage = Color(red: 0.10, green: 0.14, blue: 0.21)

    static func side(_ rightSide: Bool) -> Color {
        rightSide ? right : left
    }
}

struct ArcKicker: View {
    let title: String

    var body: some View {
        Text(title.uppercased())
            .font(.system(.caption2, design: .monospaced, weight: .semibold))
            .tracking(1.5)
            .foregroundStyle(.secondary)
    }
}

struct ArcHeading: View {
    let index: String
    let title: String
    let summary: String

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            ArcKicker(title: index)
            Text(title)
                .font(.system(size: 34, weight: .semibold))
                .tracking(-1.2)
                .accessibilityAddTraits(.isHeader)
            Text(summary)
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct ArcBadge: View {
    let title: String
    let symbol: String

    var body: some View {
        Label(title, systemImage: symbol)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(.primary.opacity(0.075), in: .capsule)
            .accessibilityElement(children: .combine)
    }
}

struct ArcPage<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                content
            }
            .frame(maxWidth: 1060)
            .padding(24)
            .frame(maxWidth: .infinity)
        }
    }
}

extension View {
    func arcPanel(radius: CGFloat = 16) -> some View {
        background(.background, in: .rect(cornerRadius: radius))
            .overlay {
                RoundedRectangle(cornerRadius: radius)
                    .strokeBorder(.primary.opacity(0.10))
                    .allowsHitTesting(false)
            }
    }
}

struct ArcGrid: View {
    var body: some View {
        Canvas { context, size in
            let step: CGFloat = 24
            var path = Path()
            for x in stride(from: step / 2, to: size.width, by: step) {
                for y in stride(from: step / 2, to: size.height, by: step) {
                    path.addEllipse(in: CGRect(x: x, y: y, width: 1.5, height: 1.5))
                }
            }
            context.fill(path, with: .color(.white.opacity(0.18)))
        }
        .accessibilityHidden(true)
    }
}
