import Foundation
import SwiftData

enum AddressingStyle: String, Codable, CaseIterable {
    case familyName = "The Smith Family"
    case formalCouple = "Mr. and Mrs. Smith"
    case firstNames = "John and Jane Smith"
    case individual = "Individual"

    var displayName: String { rawValue }
}

@Model
final class Household {
    var id: UUID
    var name: String
    var addressLine1: String
    var addressLine2: String
    var city: String
    var state: String
    var zip: String
    var country: String
    var useCustomMailingAddress: Bool
    var mailingLine1: String
    var mailingLine2: String
    var mailingCity: String
    var mailingState: String
    var mailingZip: String
    var mailingCountry: String
    var preferredAddressingStyle: AddressingStyle
    var notes: String
    var giftingTags: [String]
    var anniversaries: [HouseholdAnniversary]

    @Relationship(deleteRule: .cascade, inverse: \Person.household)
    var persons: [Person]

    @Relationship(deleteRule: .nullify)
    var groups: [ContactGroup]

    init(
        name: String = "",
        addressLine1: String = "",
        addressLine2: String = "",
        city: String = "",
        state: String = "",
        zip: String = "",
        country: String = "USA"
    ) {
        self.id = UUID()
        self.name = name
        self.addressLine1 = addressLine1
        self.addressLine2 = addressLine2
        self.city = city
        self.state = state
        self.zip = zip
        self.country = country
        self.useCustomMailingAddress = false
        self.mailingLine1 = ""
        self.mailingLine2 = ""
        self.mailingCity = ""
        self.mailingState = ""
        self.mailingZip = ""
        self.mailingCountry = ""
        self.preferredAddressingStyle = .familyName
        self.notes = ""
        self.giftingTags = []
        self.anniversaries = []
        self.persons = []
        self.groups = []
    }

    var effectiveMailingAddress: (line1: String, line2: String, city: String, state: String, zip: String, country: String) {
        if useCustomMailingAddress && !mailingLine1.isEmpty {
            return (mailingLine1, mailingLine2, mailingCity, mailingState, mailingZip, mailingCountry)
        }
        return (addressLine1, addressLine2, city, state, zip, country)
    }

    var adults: [Person] {
        persons.filter { $0.role == .adult }.sorted { $0.firstName < $1.firstName }
    }

    var children: [Person] {
        persons.filter { $0.role == .child }.sorted { $0.firstName < $1.firstName }
    }

    var formattedAddress: String {
        let m = effectiveMailingAddress
        var lines = [m.line1]
        if !m.line2.isEmpty { lines.append(m.line2) }
        lines.append("\(m.city), \(m.state) \(m.zip)")
        if m.country != "USA" { lines.append(m.country) }
        return lines.joined(separator: "\n")
    }
}

struct HouseholdAnniversary: Codable, Identifiable {
    var id: UUID = UUID()
    var label: String
    var date: Date
}
