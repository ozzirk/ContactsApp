import Foundation
import SwiftData

enum EventType: String, Codable, CaseIterable {
    case casual = "Casual"
    case formal = "Formal"
    case holiday = "Holiday"
    case kidsParty = "Kids Party"
    case adultsOnly = "Adults Only"
    case dinner = "Dinner"
    case celebration = "Celebration"
    case other = "Other"

    var icon: String {
        switch self {
        case .casual: return "cup.and.saucer.fill"
        case .formal: return "star.fill"
        case .holiday: return "gift.fill"
        case .kidsParty: return "balloon.fill"
        case .adultsOnly: return "wineglass.fill"
        case .dinner: return "fork.knife"
        case .celebration: return "party.popper.fill"
        case .other: return "calendar"
        }
    }
}

enum RSVPStatus: String, Codable, CaseIterable {
    case noResponse = "No Response"
    case attending = "Attending"
    case declined = "Declined"
    case maybe = "Maybe"

    var icon: String {
        switch self {
        case .noResponse: return "questionmark.circle"
        case .attending: return "checkmark.circle.fill"
        case .declined: return "xmark.circle.fill"
        case .maybe: return "minus.circle.fill"
        }
    }

    var color: String {
        switch self {
        case .noResponse: return "secondaryText"
        case .attending: return "success"
        case .declined: return "destructive"
        case .maybe: return "warning"
        }
    }
}

@Model
final class GuestInvitation {
    var id: UUID
    var rsvpStatus: RSVPStatus
    var rsvpNote: String
    var isAdultsOnly: Bool

    var event: Event?
    var person: Person?
    var household: Household?

    init(person: Person? = nil, household: Household? = nil, adultsOnly: Bool = false) {
        self.id = UUID()
        self.rsvpStatus = .noResponse
        self.rsvpNote = ""
        self.isAdultsOnly = adultsOnly
        self.person = person
        self.household = household
    }

    var displayName: String {
        if let p = person { return p.fullName }
        if let h = household { return h.name }
        return "Unknown"
    }
}

@Model
final class Event {
    var id: UUID
    var name: String
    var date: Date
    var endDate: Date?
    var location: String
    var eventType: EventType
    var notes: String
    var isAdultsOnly: Bool

    @Relationship(deleteRule: .cascade, inverse: \GuestInvitation.event)
    var invitations: [GuestInvitation]

    init(name: String = "", date: Date = Date(), eventType: EventType = .casual) {
        self.id = UUID()
        self.name = name
        self.date = date
        self.endDate = nil
        self.location = ""
        self.eventType = eventType
        self.notes = ""
        self.isAdultsOnly = false
        self.invitations = []
    }

    var attendingCount: Int {
        invitations.filter { $0.rsvpStatus == .attending }.count
    }

    var declinedCount: Int {
        invitations.filter { $0.rsvpStatus == .declined }.count
    }

    var maybeCount: Int {
        invitations.filter { $0.rsvpStatus == .maybe }.count
    }

    var noResponseCount: Int {
        invitations.filter { $0.rsvpStatus == .noResponse }.count
    }

    var isPast: Bool { date < Date() }

    var householdRollups: [(household: Household, invitations: [GuestInvitation])] {
        let householdInvites = invitations.filter { $0.household != nil }
        let grouped = Dictionary(grouping: householdInvites) { $0.household!.id }
        return grouped.compactMap { (_, invites) -> (Household, [GuestInvitation])? in
            guard let h = invites.first?.household else { return nil }
            return (h, invites)
        }.sorted { $0.household.name < $1.household.name }
    }
}
