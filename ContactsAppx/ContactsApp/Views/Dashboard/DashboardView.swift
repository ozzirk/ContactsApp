import SwiftUI
import SwiftData

// MARK: - Dashboard item model (unified upcoming item)

struct DashboardItem: Identifiable {
    enum Kind {
        case birthday(Person)
        case importantDate(Household, HouseholdAnniversary)
        case event(Event)
    }

    var id = UUID()
    var kind: Kind
    var daysUntil: Int

    var title: String {
        switch kind {
        case .birthday(let p): return p.fullName
        case .importantDate(let h, _): return h.name
        case .event(let e): return e.name
        }
    }

    var subtitle: String {
        switch kind {
        case .birthday: return "Birthday"
        case .importantDate(_, let ann): return ann.label.isEmpty ? "Important Date" : ann.label
        case .event(let e): return e.location.isEmpty ? e.eventType.rawValue : e.location
        }
    }

    var icon: String {
        switch kind {
        case .birthday: return "birthday.cake.fill"
        case .importantDate: return "calendar.badge.checkmark"
        case .event(let e): return e.eventType.icon
        }
    }

    var person: Person? {
        if case .birthday(let p) = kind { return p }
        return nil
    }
    var household: Household? {
        if case .importantDate(let h, _) = kind { return h }
        return nil
    }
    var event: Event? {
        if case .event(let e) = kind { return e }
        return nil
    }

    var pendingGiftIdeas: [GiftIdea] {
        person?.giftIdeas.filter { !$0.status.isDone } ?? []
    }

    var hasGiftCovered: Bool {
        guard let p = person else { return true }
        return p.giftIdeas.contains { $0.status == .given || $0.status == .purchased || $0.status == .wrapped || $0.status == .shipped }
    }
}

// MARK: - Dashboard

struct DashboardView: View {
    @Query private var households: [Household]
    @Query private var persons: [Person]
    @Query(sort: \Event.date) private var events: [Event]
    @Query private var groups: [ContactGroup]
    @Query private var giftIdeas: [GiftIdea]

    @State private var showingAddGiftIdea = false
    @State private var giftIdeaTarget: Person? = nil

    // All upcoming items in the next 90 days, sorted by date
    private var allUpcoming: [DashboardItem] {
        var items: [DashboardItem] = []

        for person in persons {
            if let days = person.daysUntilBirthday, days <= 90 {
                items.append(DashboardItem(kind: .birthday(person), daysUntil: days))
            }
        }
        for household in households {
            for ann in household.anniversaries {
                let days = daysUntilAnnual(ann.date)
                if days <= 90 {
                    items.append(DashboardItem(kind: .importantDate(household, ann), daysUntil: days))
                }
            }
        }
        for event in events where !event.isPast {
            let days = Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: Date()), to: event.date).day ?? 0
            if days <= 90 {
                items.append(DashboardItem(kind: .event(event), daysUntil: days))
            }
        }

        return items.sorted { $0.daysUntil < $1.daysUntil }
    }

    private var thisWeek: [DashboardItem] { allUpcoming.filter { $0.daysUntil <= 7 } }
    private var thisMonth: [DashboardItem] { allUpcoming.filter { $0.daysUntil > 7 && $0.daysUntil <= 30 } }
    private var beyond: [DashboardItem] { allUpcoming.filter { $0.daysUntil > 30 } }

    // Gift ideas that need action: pending ideas for people with birthdays within 30 days
    private var giftActionNeeded: [GiftIdea] {
        giftIdeas
            .filter { !$0.status.isDone }
            .filter { idea in
                guard let p = idea.person, let days = p.daysUntilBirthday else { return false }
                return days <= 30
            }
            .sorted { a, b in
                (a.person?.daysUntilBirthday ?? 999) < (b.person?.daysUntilBirthday ?? 999)
            }
    }

    // People with upcoming birthdays (<= 30 days) with NO gift ideas at all
    private var uncoveredBirthdays: [Person] {
        persons
            .filter { p in
                guard let days = p.daysUntilBirthday else { return false }
                return days <= 30 && p.giftIdeas.isEmpty
            }
            .sorted { ($0.daysUntilBirthday ?? 999) < ($1.daysUntilBirthday ?? 999) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 28) {
                        summaryRow
                        if !thisWeek.isEmpty { section(title: "This Week", items: thisWeek) }
                        if !uncoveredBirthdays.isEmpty || !giftActionNeeded.isEmpty { giftNeedsSection }
                        if !thisMonth.isEmpty { section(title: "This Month", items: thisMonth) }
                        if !beyond.isEmpty { beyondSection }
                        if allUpcoming.isEmpty && giftIdeas.isEmpty { emptyState }
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }
            .navigationTitle("Home")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(isPresented: $showingAddGiftIdea) {
            if let person = giftIdeaTarget {
                GiftIdeaFormView(person: person)
            }
        }
    }

    // MARK: - Summary row

    private var summaryRow: some View {
        HStack(spacing: 10) {
            SummaryPill(
                count: thisWeek.count,
                label: "This Week",
                color: thisWeek.isEmpty ? .secondaryText : .destructive
            )
            SummaryPill(
                count: thisMonth.count,
                label: "This Month",
                color: thisMonth.isEmpty ? .secondaryText : .warning
            )
            SummaryPill(
                count: giftIdeas.filter { !$0.status.isDone }.count,
                label: "Gift Ideas",
                color: .accent
            )
        }
    }

    // MARK: - Generic upcoming section

    private func section(title: String, items: [DashboardItem]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: title)
            VStack(spacing: 8) {
                ForEach(items) { item in
                    dashboardCard(item)
                }
            }
        }
    }

    // MARK: - Gift needs section

    private var giftNeedsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Needs Attention")
            AppCard {
                VStack(spacing: 0) {
                    ForEach(uncoveredBirthdays) { person in
                        uncoveredBirthdayRow(person)
                        Divider().padding(.leading, 16)
                    }
                    ForEach(giftActionNeeded) { idea in
                        NavigationLink(destination: PersonDetailView(person: idea.person!)) {
                            giftProgressRow(idea)
                        }
                        .buttonStyle(.plain)
                        if idea.id != giftActionNeeded.last?.id {
                            Divider().padding(.leading, 16)
                        }
                    }
                }
            }
        }
    }

    private func uncoveredBirthdayRow(_ person: Person) -> some View {
        HStack(spacing: 12) {
            PersonAvatar(initials: person.initials, size: 36)
            VStack(alignment: .leading, spacing: 2) {
                Text(person.fullName).font(.bodyMedium).foregroundStyle(.primaryText)
                Text("No gift ideas yet").font(.captionRegular).foregroundStyle(.tertiaryText)
            }
            Spacer()
            if let days = person.daysUntilBirthday { CountdownBadge(days: days) }
            Button {
                giftIdeaTarget = person
                showingAddGiftIdea = true
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.accent)
            }
            .padding(.leading, 4)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private func giftProgressRow(_ idea: GiftIdea) -> some View {
        HStack(spacing: 12) {
            Image(systemName: idea.status.icon)
                .foregroundStyle(.accent)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(idea.title).font(.bodyMedium).foregroundStyle(.primaryText)
                if let name = idea.person?.fullName {
                    Text("For \(name)").font(.captionRegular).foregroundStyle(.secondaryText)
                }
            }
            Spacer()
            Text(idea.status.rawValue)
                .font(.captionMedium)
                .foregroundStyle(.secondaryText)
                .padding(.horizontal, 8).padding(.vertical, 3)
                .background(Color.secondaryText.opacity(0.1))
                .clipShape(Capsule())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Beyond section (compact)

    private var beyondSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Later (up to 90 days)")
            AppCard {
                VStack(spacing: 0) {
                    ForEach(beyond) { item in
                        compactRow(item)
                        if item.id != beyond.last?.id {
                            Divider().padding(.leading, 56)
                        }
                    }
                }
            }
        }
    }

    private func compactRow(_ item: DashboardItem) -> some View {
        Group {
            if let person = item.person {
                NavigationLink(destination: PersonDetailView(person: person)) { compactRowContent(item) }
                    .buttonStyle(.plain)
            } else if let household = item.household {
                NavigationLink(destination: HouseholdDetailView(household: household)) { compactRowContent(item) }
                    .buttonStyle(.plain)
            } else if let event = item.event {
                NavigationLink(destination: EventDetailView(event: event)) { compactRowContent(item) }
                    .buttonStyle(.plain)
            }
        }
    }

    private func compactRowContent(_ item: DashboardItem) -> some View {
        HStack(spacing: 12) {
            Image(systemName: item.icon).foregroundStyle(.accent).frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(item.title).font(.bodyMedium).foregroundStyle(.primaryText)
                Text(item.subtitle).font(.captionRegular).foregroundStyle(.secondaryText)
            }
            Spacer()
            CountdownBadge(days: item.daysUntil)
        }
        .padding(.horizontal, 16).padding(.vertical, 13)
    }

    // MARK: - Individual dashboard card

    @ViewBuilder
    private func dashboardCard(_ item: DashboardItem) -> some View {
        Group {
            if let person = item.person {
                NavigationLink(destination: PersonDetailView(person: person)) {
                    DashboardItemCard(item: item, onAddGift: {
                        giftIdeaTarget = person
                        showingAddGiftIdea = true
                    })
                }
                .buttonStyle(.plain)
            } else if let household = item.household {
                NavigationLink(destination: HouseholdDetailView(household: household)) {
                    DashboardItemCard(item: item, onAddGift: nil)
                }
                .buttonStyle(.plain)
            } else if let event = item.event {
                NavigationLink(destination: EventDetailView(event: event)) {
                    DashboardItemCard(item: item, onAddGift: nil)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var emptyState: some View {
        AppCard {
            VStack(spacing: 16) {
                Image(systemName: "house.circle.fill").font(.system(size: 48)).foregroundStyle(.accent)
                Text("Welcome").font(.titleLarge).foregroundStyle(.primaryText)
                Text("Add birthdays and important dates to contacts — they'll all appear here automatically.")
                    .font(.bodyRegular).foregroundStyle(.secondaryText).multilineTextAlignment(.center)
            }
            .padding(28)
        }
    }

    // MARK: - Helpers

    private func daysUntilAnnual(_ date: Date) -> Int {
        let calendar = Calendar.current
        let now = Date()
        var components = calendar.dateComponents([.month, .day], from: date)
        components.year = calendar.component(.year, from: now)
        guard var next = calendar.date(from: components) else { return 365 }
        if next < calendar.startOfDay(for: now) {
            components.year = (components.year ?? 0) + 1
            next = calendar.date(from: components) ?? next
        }
        return calendar.dateComponents([.day], from: calendar.startOfDay(for: now), to: next).day ?? 365
    }
}

// MARK: - Dashboard item card

struct DashboardItemCard: View {
    let item: DashboardItem
    var onAddGift: (() -> Void)?

    var body: some View {
        AppCard {
            HStack(spacing: 14) {
                // Icon
                ZStack {
                    Circle().fill(iconBackground).frame(width: 46, height: 46)
                    Image(systemName: item.icon).font(.system(size: 18)).foregroundStyle(iconColor)
                }

                // Content
                VStack(alignment: .leading, spacing: 3) {
                    Text(item.title).font(.bodyMedium).foregroundStyle(.primaryText)
                    Text(item.subtitle).font(.captionRegular).foregroundStyle(.secondaryText)

                    if let person = item.person {
                        giftStatusLine(person)
                    }
                    if let event = item.event {
                        eventStatusLine(event)
                    }
                }

                Spacer()

                // Right side
                VStack(alignment: .trailing, spacing: 8) {
                    CountdownBadge(days: item.daysUntil)
                    if let onAddGift, item.person != nil, item.pendingGiftIdeas.isEmpty && !item.hasGiftCovered {
                        Button(action: onAddGift) {
                            Label("Add idea", systemImage: "plus")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(.accent)
                        }
                    }
                }
            }
            .padding(16)
        }
    }

    @ViewBuilder
    private func giftStatusLine(_ person: Person) -> some View {
        let ideas = person.giftIdeas
        if ideas.isEmpty { EmptyView() }
        else if ideas.contains(where: { $0.status == .given }) {
            Label("Gift given ✓", systemImage: "checkmark.seal.fill")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color.success)
        } else if ideas.contains(where: { $0.status == .purchased || $0.status == .wrapped || $0.status == .shipped }) {
            Label("Gift on its way", systemImage: "bag.fill")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.accent)
        } else {
            let count = ideas.filter { !$0.status.isDone }.count
            Label("\(count) idea\(count == 1 ? "" : "s") saved", systemImage: "lightbulb.fill")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Color.warning)
        }
    }

    @ViewBuilder
    private func eventStatusLine(_ event: Event) -> some View {
        let attending = event.attendingCount
        let pending = event.noResponseCount
        if attending > 0 || pending > 0 {
            HStack(spacing: 8) {
                if attending > 0 {
                    Label("\(attending) attending", systemImage: "checkmark.circle.fill")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color.success)
                }
                if pending > 0 {
                    Label("\(pending) pending", systemImage: "clock")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondaryText)
                }
            }
        }
    }

    private var iconBackground: Color {
        switch item.daysUntil {
        case 0...3: return Color.destructive.opacity(0.12)
        case 4...7: return Color.warning.opacity(0.12)
        default: return Color.accent.opacity(0.12)
        }
    }

    private var iconColor: Color {
        switch item.daysUntil {
        case 0...3: return .destructive
        case 4...7: return .warning
        default: return .accent
        }
    }
}

// MARK: - Summary pill

struct SummaryPill: View {
    let count: Int
    let label: String
    let color: Color

    var body: some View {
        AppCard {
            VStack(spacing: 4) {
                Text("\(count)")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(count == 0 ? .tertiaryText : color)
                Text(label)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondaryText)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
        }
    }
}
