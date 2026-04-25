import Foundation
import SwiftData

enum GiftStatus: String, Codable, CaseIterable {
    case idea = "Idea"
    case purchased = "Purchased"
    case wrapped = "Wrapped"
    case shipped = "Shipped"
    case given = "Given"

    var icon: String {
        switch self {
        case .idea: return "lightbulb.fill"
        case .purchased: return "bag.fill"
        case .wrapped: return "gift.fill"
        case .shipped: return "shippingbox.fill"
        case .given: return "checkmark.seal.fill"
        }
    }

    var isDone: Bool { self == .given }
}

@Model
final class GiftIdea {
    var id: UUID
    var title: String
    var link: String
    var priceEstimate: Double?
    var status: GiftStatus
    var notes: String
    var createdAt: Date

    var person: Person?
    var household: Household?
    var occasion: Occasion?

    init(title: String = "") {
        self.id = UUID()
        self.title = title
        self.link = ""
        self.priceEstimate = nil
        self.status = .idea
        self.notes = ""
        self.createdAt = Date()
    }

    var formattedPrice: String? {
        guard let price = priceEstimate else { return nil }
        return String(format: "$%.0f", price)
    }
}

@Model
final class GiftHistory {
    var id: UUID
    var year: Int
    var occasionType: String
    var giftGiven: String
    var amount: Double?
    var recipientReaction: String
    var historyNotes: String
    var doNotRepeat: Bool
    var date: Date

    var person: Person?
    var household: Household?

    init(giftGiven: String = "", occasionType: String = "", year: Int = Calendar.current.component(.year, from: Date())) {
        self.id = UUID()
        self.year = year
        self.occasionType = occasionType
        self.giftGiven = giftGiven
        self.amount = nil
        self.recipientReaction = ""
        self.historyNotes = ""
        self.doNotRepeat = false
        self.date = Date()
    }

    var formattedAmount: String? {
        guard let a = amount else { return nil }
        return String(format: "$%.0f", a)
    }
}
