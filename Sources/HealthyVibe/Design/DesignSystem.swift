import SwiftUI

enum LayoutMetrics {
    static let popoverWidth: CGFloat = 340
    static let popoverHeight: CGFloat = 356
}

enum HVSpacing {
    static let xsmall: CGFloat = 4
    static let small: CGFloat = 8
    static let medium: CGFloat = 12
    static let large: CGFloat = 16
    static let xlarge: CGFloat = 22
}

enum HVRadius {
    static let small: CGFloat = 6
    static let medium: CGFloat = 8
}

enum HVColor {
    static let background = Color(red: 0.99, green: 0.985, blue: 0.97)
    static let surface = Color.white
    static let primaryText = Color(red: 0.12, green: 0.115, blue: 0.105)
    static let secondaryText = Color(red: 0.40, green: 0.38, blue: 0.34)
    static let mutedText = Color(red: 0.62, green: 0.59, blue: 0.54)
    static let border = Color(red: 0.88, green: 0.86, blue: 0.82)
    static let warmAccent = Color(red: 0.88, green: 0.38, blue: 0.20)
    static let calmAccent = Color(red: 0.17, green: 0.49, blue: 0.42)
    static let accentFill = Color(red: 1.0, green: 0.90, blue: 0.82)
    static let successFill = Color(red: 0.86, green: 0.94, blue: 0.90)
    static let warningFill = Color(red: 1.0, green: 0.95, blue: 0.84)
}

struct HVCard<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(HVSpacing.large)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(HVColor.surface)
            .clipShape(RoundedRectangle(cornerRadius: HVRadius.medium, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: HVRadius.medium, style: .continuous)
                    .stroke(HVColor.border, lineWidth: 1)
            )
    }
}

struct HVProgressBar: View {
    let value: Double

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(HVColor.border.opacity(0.55))
                Capsule()
                    .fill(value >= 1 ? HVColor.warmAccent : HVColor.calmAccent)
                    .frame(width: max(0, min(proxy.size.width, proxy.size.width * value)))
            }
        }
        .frame(height: 8)
        .accessibilityLabel("今日延寿进度")
        .accessibilityValue("\(Int(value * 100))%")
    }
}

struct HVPrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(Color.white.opacity(isEnabled ? 1 : 0.72))
            .frame(height: 32)
            .frame(maxWidth: .infinity)
            .background(backgroundColor(isPressed: configuration.isPressed))
            .clipShape(RoundedRectangle(cornerRadius: HVRadius.small, style: .continuous))
    }

    private func backgroundColor(isPressed: Bool) -> Color {
        guard isEnabled else {
            return HVColor.border
        }

        return isPressed ? HVColor.warmAccent.opacity(0.82) : HVColor.warmAccent
    }
}

struct HVSecondaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(isEnabled ? HVColor.primaryText : HVColor.mutedText)
            .frame(height: 32)
            .frame(maxWidth: .infinity)
            .background(backgroundColor(isPressed: configuration.isPressed))
            .clipShape(RoundedRectangle(cornerRadius: HVRadius.small, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: HVRadius.small, style: .continuous)
                    .stroke(HVColor.border, lineWidth: 1)
            )
    }

    private func backgroundColor(isPressed: Bool) -> Color {
        guard isEnabled else {
            return HVColor.surface.opacity(0.62)
        }

        return isPressed ? HVColor.border.opacity(0.55) : HVColor.surface
    }
}
