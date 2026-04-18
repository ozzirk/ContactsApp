import Foundation
import SwiftData

enum OccasionType: String, Codable, CaseIterable {
    case birthday = "Birthday"
    case anniversary = "Anniversary"
    case christmas = "Christmas"
    case hanukkah = "Hanukkah"
    case mothersDay = "Mother's Day"
    case fathersDay = "Father's Day"
    case valentinesDay = "Valentine's Day"
    case newBaby = "New Baby"
    case graduation = "Graduation"
    case housewarming = "Housewarming"
    case wedding = "Wedding"
    case hostessGift = "Hostess Gift"
    case other = "Other"

    var icon: String {
        switch self {
        case .birthday: return "birthday.cake.fill"
        case .anniversary: return "heart.fill"
        case .christmas: return "snowflake"
        case .hanukkah: return "star.of.david.fill"
        case .mothersDay: return "figure.and.child.holdinghands"
        case .fathersDay: return "figure.wave"
        case .valentinesDay: return "heart.circle.fill"
        case .newBaby: return "figure.and.child.holdinghands"
        case .graduation: return "graduationcap.fill"
        case .housewarming: return "house.fill"
        case .wedding: return "sparkles"
        case .hostessGift: return "gift.fill"
        case .other: return "calendar.badge.plus"
        }
    }

    var isRecurringAnnually: Bool {
        switch self {
        case .birthday, .anniversary, .christmas, .hanukkah, .mothersDay, .fathersDay, .valentinesDay:
            return true
        default:
            return false
        }
    }
}

enum GiftRequirement: String, Codable, CaseIterable {
    case required = "Gift required"
    case optional = "Gift optional"
    case none = "No gift"
}

@Model
final class Occasion {
    var id: UUID
    var occasionType: OccasionType
    var customLabel: String
    var date: Date
    var isRecurringAnnually: Bool
    var giftRequirement: GiftRequirement
    var budget: Double?
    var notes: String

    var person: Person?
    var household: Household?

    @Relationship(deleteRule: .cascade, inverse: \GiftIdea.occasion)
    var giftIdeas: [GiftIdea]

    init(type: OccasionType = .birthday, date: Date = Date()) {
        self.id = UUID()
        self.occasionType = type
        self.customLabel = ""
        self.date = date
        self.isRecurringAnnually = type.isRecurringAnnually
        self.giftRequirement = .optional
        self.budget = nil
        self.notes = ""
        self.giftIdeas = []
    }

    var displayLabel: String {
        customLabel.isEmpty ? occasionType.rawValue : customLabel
    }

    var nextOccurrence: Date {
        guard isRecurringAnnually else { return date }
        let calendar = Calendar.current
        let now = Date()
        var components = calendar.dateComponents([.month, .day], from: date)
        components.year = calendar.component(.year, from: now)
        guard var next = calendar.date(from: components) else { return date }
        if next < now {
            components.year = (components.year ?? 0) + 1
            next = calendar.date(from: components) ?? next
        }
        return next
    }

    var daysUntil: Int {
        Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: Date()), to: nextOccurrence).day ?? 0
    }

    var recipientName: String {
        person?.fullName ?? household?.name ?? ""
    }
}
