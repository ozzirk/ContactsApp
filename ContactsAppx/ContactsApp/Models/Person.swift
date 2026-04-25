import Foundation
import SwiftData

enum PersonRole: String, Codable, CaseIterable {
    case adult = "Adult"
    case child = "Child"
    case other = "Other"
}

enum RelationshipType: String, Codable, CaseIterable {
    case family = "Family"
    case friend = "Friend"
    case neighbor = "Neighbor"
    case colleague = "Colleague"
    case acquaintance = "Acquaintance"
    case teacher = "Teacher"
    case other = "Other"

    var icon: String {
        switch self {
        case .family: return "house.fill"
        case .friend: return "heart.fill"
        case .neighbor: return "map.fill"
        case .colleague: return "briefcase.fill"
        case .acquaintance: return "person.fill"
        case .teacher: return "graduationcap.fill"
        case .other: return "star.fill"
        }
    }
}

enum GiftPreference: String, Codable, CaseIterable {
    case open = "Open to gifts"
    case noGifts = "No gifts please"
    case experiencesOnly = "Experiences preferred"
    case charityDonation = "Charity donation"

    var displayName: String { rawValue }
}

@Model
final class Person {
    var id: UUID
    var firstName: String
    var lastName: String
    var role: PersonRole
    var phone: String
    var email: String
    var birthday: Date?
    var relationshipType: RelationshipType
    var tags: [String]
    var interests: [String]
    var allergies: [String]
    var giftPreference: GiftPreference
    var shoeSize: String
    var topSize: String
    var bottomSize: String
    var notes: String

    var household: Household?

    @Relationship(deleteRule: .cascade, inverse: \GiftIdea.person)
    var giftIdeas: [GiftIdea]

    @Relationship(deleteRule: .cascade, inverse: \GiftHistory.person)
    var giftHistory: [GiftHistory]

    @Relationship(deleteRule: .nullify)
    var occasions: [Occasion]

    init(firstName: String = "", lastName: String = "", role: PersonRole = .adult) {
        self.id = UUID()
        self.firstName = firstName
        self.lastName = lastName
        self.role = role
        self.phone = ""
        self.email = ""
        self.birthday = nil
        self.relationshipType = .friend
        self.tags = []
        self.interests = []
        self.allergies = []
        self.giftPreference = .open
        self.shoeSize = ""
        self.topSize = ""
        self.bottomSize = ""
        self.notes = ""
        self.giftIdeas = []
        self.giftHistory = []
        self.occasions = []
    }

    var fullName: String {
        [firstName, lastName].filter { !$0.isEmpty }.joined(separator: " ")
    }

    var initials: String {
        let f = firstName.first.map(String.init) ?? ""
        let l = lastName.first.map(String.init) ?? ""
        return (f + l).uppercased()
    }

    var nextBirthday: Date? {
        guard let bday = birthday else { return nil }
        let calendar = Calendar.current
        let now = Date()
        var components = calendar.dateComponents([.month, .day], from: bday)
        components.year = calendar.component(.year, from: now)
        guard var next = calendar.date(from: components) else { return nil }
        if next < now {
            components.year = (components.year ?? 0) + 1
            next = calendar.date(from: components) ?? next
        }
        return next
    }

    var daysUntilBirthday: Int? {
        guard let next = nextBirthday else { return nil }
        return Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: Date()), to: next).day
    }
}
