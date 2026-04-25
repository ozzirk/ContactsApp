import Foundation

enum AddressFormatter {
    static func mailingLine(household: Household, adultsOnly: Bool = false) -> String {
        let adults = household.adults
        switch household.preferredAddressingStyle {
        case .familyName:
            return household.name.isEmpty ? "The \(primaryLastName(adults)) Family" : household.name
        case .formalCouple:
            return formalCoupleLine(adults)
        case .firstNames:
            let names = adults.map { $0.firstName }.filter { !$0.isEmpty }
            let last = adults.first?.lastName ?? ""
            return names.joined(separator: " and ") + (last.isEmpty ? "" : " \(last)")
        case .individual:
            return adults.first?.fullName ?? household.name
        }
    }

    static func envelopeLine(household: Household) -> [String] {
        var lines: [String] = [mailingLine(household: household)]
        let m = household.effectiveMailingAddress
        lines.append(m.line1)
        if !m.line2.isEmpty { lines.append(m.line2) }
        lines.append("\(m.city), \(m.state) \(m.zip)")
        if m.country != "USA" { lines.append(m.country) }
        return lines
    }

    static func labelBlock(household: Household) -> String {
        envelopeLine(household: household).joined(separator: "\n")
    }

    private static func primaryLastName(_ adults: [Person]) -> String {
        adults.first?.lastName ?? "Family"
    }

    private static func formalCoupleLine(_ adults: [Person]) -> String {
        guard !adults.isEmpty else { return "" }
        if adults.count == 1 {
            return adults[0].fullName
        }
        let lastName = adults[0].lastName
        let allSameLastName = adults.allSatisfy { $0.lastName == lastName }
        if allSameLastName && adults.count == 2 {
            return "Mr. and Mrs. \(lastName)"
        }
        return adults.map { $0.fullName }.joined(separator: " and ")
    }
}
