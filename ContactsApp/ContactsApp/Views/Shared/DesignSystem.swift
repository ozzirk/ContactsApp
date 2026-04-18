import SwiftUI

// MARK: - Colors

extension Color {
    static let appBackground = Color("AppBackground")
    static let cardBackground = Color("CardBackground")
    static let primaryText = Color("PrimaryText")
    static let secondaryText = Color("SecondaryText")
    static let tertiaryText = Color("TertiaryText")
    static let accent = Color("AccentColor")
    static let divider = Color("Divider")
    static let success = Color(red: 0.27, green: 0.65, blue: 0.45)
    static let warning = Color(red: 0.92, green: 0.70, blue: 0.24)
    static let destructive = Color(red: 0.85, green: 0.33, blue: 0.33)

    static func groupColor(_ name: GroupColor) -> Color {
        switch name {
        case .sage: return Color(red: 0.56, green: 0.68, blue: 0.57)
        case .clay: return Color(red: 0.78, green: 0.55, blue: 0.44)
        case .slate: return Color(red: 0.48, green: 0.55, blue: 0.63)
        case .blush: return Color(red: 0.85, green: 0.66, blue: 0.66)
        case .stone: return Color(red: 0.63, green: 0.60, blue: 0.57)
        case .navy: return Color(red: 0.22, green: 0.35, blue: 0.53)
        case .moss: return Color(red: 0.44, green: 0.57, blue: 0.38)
        case .terracotta: return Color(red: 0.75, green: 0.44, blue: 0.33)
        }
    }
}

// MARK: - Typography

extension Font {
    static let displayLarge = Font.system(size: 34, weight: .bold, design: .rounded)
    static let displayMedium = Font.system(size: 28, weight: .semibold, design: .rounded)
    static let titleLarge = Font.system(size: 22, weight: .semibold, design: .rounded)
    static let titleMedium = Font.system(size: 18, weight: .semibold, design: .rounded)
    static let titleSmall = Font.system(size: 15, weight: .semibold, design: .rounded)
    static let bodyRegular = Font.system(size: 16, weight: .regular, design: .default)
    static let bodyMedium = Font.system(size: 16, weight: .medium, design: .default)
    static let captionRegular = Font.system(size: 13, weight: .regular, design: .default)
    static let captionMedium = Font.system(size: 13, weight: .medium, design: .default)
    static let label = Font.system(size: 11, weight: .semibold, design: .default).uppercaseSmallCaps()
}

// MARK: - Card

struct AppCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Section Header

struct SectionHeader: View {
    let title: String
    var action: (() -> Void)? = nil
    var actionLabel: String = "See All"

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.label)
                .foregroundStyle(.secondaryText)
                .kerning(0.5)
            Spacer()
            if let action {
                Button(actionLabel, action: action)
                    .font(.captionMedium)
                    .foregroundStyle(.accent)
            }
        }
        .padding(.horizontal, 4)
    }
}

// MARK: - Avatar

struct PersonAvatar: View {
    let initials: String
    var size: CGFloat = 44
    var color: Color = .accent

    var body: some View {
        ZStack {
            Circle()
                .fill(color.opacity(0.15))
                .frame(width: size, height: size)
            Text(initials)
                .font(.system(size: size * 0.35, weight: .semibold, design: .rounded))
                .foregroundStyle(color)
        }
    }
}

struct HouseholdAvatar: View {
    let name: String
    var size: CGFloat = 44

    private var initial: String {
        name.first.map { String($0).uppercased() } ?? "H"
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
                .fill(Color.accent.opacity(0.12))
                .frame(width: size, height: size)
            Text(initial)
                .font(.system(size: size * 0.38, weight: .semibold, design: .rounded))
                .foregroundStyle(.accent)
        }
    }
}

// MARK: - Chips / Tags

struct TagChip: View {
    let label: String
    var removable: Bool = false
    var onRemove: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.captionMedium)
                .foregroundStyle(.primaryText)
            if removable, let onRemove {
                Button(action: onRemove) {
                    Image(systemName: "xmark")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.secondaryText)
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Color.secondaryText.opacity(0.1))
        .clipShape(Capsule())
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 0
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > width, x > 0 {
                y += rowHeight + spacing
                x = 0
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        y += rowHeight
        return CGSize(width: width, height: y)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                y += rowHeight + spacing
                x = bounds.minX
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

// MARK: - Empty State

struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 40, weight: .light))
                .foregroundStyle(.tertiaryText)
            Text(title)
                .font(.titleSmall)
                .foregroundStyle(.secondaryText)
            Text(subtitle)
                .font(.captionRegular)
                .foregroundStyle(.tertiaryText)
                .multilineTextAlignment(.center)
        }
        .padding(32)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Countdown Badge

struct CountdownBadge: View {
    let days: Int

    var body: some View {
        Text(label)
            .font(.system(size: 11, weight: .semibold, design: .rounded))
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
    }

    private var label: String {
        switch days {
        case 0: return "Today"
        case 1: return "Tomorrow"
        default: return "\(days)d"
        }
    }

    private var color: Color {
        switch days {
        case 0...3: return .destructive
        case 4...14: return .warning
        default: return .secondaryText
        }
    }
}

// MARK: - Form Field Styles

struct AppTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .background(Color.secondaryText.opacity(0.07))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .font(.bodyRegular)
    }
}

struct FormRow<Content: View>: View {
    let label: String
    let content: Content

    init(_ label: String, @ViewBuilder content: () -> Content) {
        self.label = label
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.captionMedium)
                .foregroundStyle(.secondaryText)
            content
        }
    }
}

// MARK: - RSVP Status View

struct RSVPBadge: View {
    let status: RSVPStatus

    var body: some View {
        Label(status.rawValue, systemImage: status.icon)
            .font(.captionMedium)
            .foregroundStyle(statusColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(statusColor.opacity(0.1))
            .clipShape(Capsule())
    }

    private var statusColor: Color {
        switch status {
        case .attending: return .success
        case .declined: return .destructive
        case .maybe: return .warning
        case .noResponse: return .secondaryText
        }
    }
}
