import Foundation
import SwiftData

enum GroupType: String, Codable, CaseIterable {
    case manual = "Manual"
    case dynamic = "Dynamic"
}

enum GroupColor: String, Codable, CaseIterable {
    case sage = "sage"
    case clay = "clay"
    case slate = "slate"
    case blush = "blush"
    case stone = "stone"
    case navy = "navy"
    case moss = "moss"
    case terracotta = "terracotta"
}

enum DynamicFilterRule: String, Codable, CaseIterable {
    case hasChildren = "Has children"
    case childrenUnder6 = "Children under 6"
    case childrenUnder13 = "Children under 13"
    case adultsOnly = "Adults only"
    case isFriend = "Is friend"
    case isFamily = "Is family"
    case isNeighbor = "Is neighbor"
    case isColleague = "Is colleague"
    case hasBirthdayThisMonth = "Birthday this month"
    case hasBirthdayNext30Days = "Birthday in next 30 days"
}

@Model
final class ContactGroup {
    var id: UUID
    var name: String
    var groupType: GroupType
    var colorName: GroupColor
    var icon: String
    var notes: String
    var dynamicRules: [DynamicFilterRule]

    @Relationship(deleteRule: .nullify)
    var households: [Household]

    @Relationship(deleteRule: .nullify)
    var persons: [Person]

    init(name: String = "", groupType: GroupType = .manual, color: GroupColor = .sage, icon: String = "person.2.fill") {
        self.id = UUID()
        self.name = name
        self.groupType = groupType
        self.colorName = color
        self.icon = icon
        self.notes = ""
        self.dynamicRules = []
        self.households = []
        self.persons = []
    }

    func resolvedPersons(allHouseholds: [Household]) -> [Person] {
        var result = Set<UUID>()
        var people: [Person] = []

        for person in persons {
            if result.insert(person.id).inserted { people.append(person) }
        }
        for household in households {
            for person in household.persons {
                if result.insert(person.id).inserted { people.append(person) }
            }
        }

        if groupType == .dynamic {
            for household in allHouseholds {
                for rule in dynamicRules {
                    if matchesRule(rule, household: household) {
                        for person in household.persons {
                            if result.insert(person.id).inserted { people.append(person) }
                        }
                    }
                }
            }
        }

        return people.sorted { $0.lastName < $1.lastName }
    }

    func resolvedHouseholds(allHouseholds: [Household]) -> [Household] {
        if groupType == .manual {
            return households.sorted { $0.name < $1.name }
        }
        return allHouseholds.filter { h in
            dynamicRules.contains { matchesRule($0, household: h) }
        }.sorted { $0.name < $1.name }
    }

    private func matchesRule(_ rule: DynamicFilterRule, household: Household) -> Bool {
        switch rule {
        case .hasChildren:
            return !household.children.isEmpty
        case .childrenUnder6:
            return household.children.contains { child in
                guard let bday = child.birthday else { return false }
                let age = Calendar.current.dateComponents([.year], from: bday, to: Date()).year ?? 0
                return age < 6
            }
        case .childrenUnder13:
            return household.children.contains { child in
                guard let bday = child.birthday else { return false }
                let age = Calendar.current.dateComponents([.year], from: bday, to: Date()).year ?? 0
                return age < 13
            }
        case .adultsOnly:
            return household.children.isEmpty
        case .isFriend:
            return household.adults.contains { $0.relationshipType == .friend }
        case .isFamily:
            return household.adults.contains { $0.relationshipType == .family }
        case .isNeighbor:
            return household.adults.contains { $0.relationshipType == .neighbor }
        case .isColleague:
            return household.adults.contains { $0.relationshipType == .colleague }
        case .hasBirthdayThisMonth:
            let month = Calendar.current.component(.month, from: Date())
            return household.persons.contains {
                guard let bday = $0.birthday else { return false }
                return Calendar.current.component(.month, from: bday) == month
            }
        case .hasBirthdayNext30Days:
            return household.persons.contains { ($0.daysUntilBirthday ?? 999) <= 30 }
        }
    }
}
