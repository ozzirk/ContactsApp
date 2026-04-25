import SwiftUI
import SwiftData

// MARK: - Unified upcoming occasion derived from Person/Household data

struct UpcomingDate: Identifiable {
    enum Kind {
        case birthday(Person)
        case anniversary(Household, HouseholdAnniversary)
    }

    var id = UUID()
    var kind: Kind
    var daysUntil: Int

    var recipientName: String {
        switch kind {
        case .birthday(let p): return p.fullName
        case .anniversary(let h, _): return h.name
        }
    }

    var occasionLabel: String {
        switch kind {
        case .birthday: return "Birthday"
        case .anniversary(_, let ann): return ann.label.isEmpty ? "Anniversary" : ann.label
        }
    }

    var icon: String {
        switch kind {
        case .birthday: return "birthday.cake.fill"
        case .anniversary: return "heart.fill"
        }
    }

    var person: Person? {
        if case .birthday(let p) = kind { return p }
        return nil
    }

    var household: Household? {
        if case .anniversary(let h, _) = kind { return h }
        return nil
    }
}

// MARK: - Main Dashboard

struct GiftingDashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var persons: [Person]
    @Query private var households: [Household]
    @Query private var giftIdeas: [GiftIdea]

    @State private var showingAddGiftIdea = false

    // All upcoming dates auto-derived from existing person/household data
    private var upcomingDates: [UpcomingDate] {
        var dates: [UpcomingDate] = []

        // Birthdays from all persons
        for person in persons {
            guard let days = person.daysUntilBirthday else { continue }
            dates.append(UpcomingDate(kind: .birthday(person), daysUntil: days))
        }

        // Anniversaries from all households
        for household in households {
            for anniversary in household.anniversaries {
                let days = daysUntil(anniversary.date)
                dates.append(UpcomingDate(kind: .anniversary(household, anniversary), daysUntil: days))
            }
        }

        return dates.sorted { $0.daysUntil < $1.daysUntil }
    }

    private var next30: [UpcomingDate] { upcomingDates.filter { $0.daysUntil <= 30 } }
    private var later: [UpcomingDate] { upcomingDates.filter { $0.daysUntil > 30 } }

    // Pending gift ideas (not yet given) sorted by the person's next upcoming date
    private var pendingIdeas: [GiftIdea] {
        giftIdeas
            .filter { !$0.status.isDone }
            .sorted { a, b in
                let aDays = a.person?.daysUntilBirthday ?? 999
                let bDays = b.person?.daysUntilBirthday ?? 999
                return aDays < bDays
            }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                Group {
                    if upcomingDates.isEmpty && giftIdeas.isEmpty {
                        emptyState
                    } else {
                        ScrollView {
                            VStack(spacing: 28) {
                                if !next30.isEmpty { urgentSection }
                                if !pendingIdeas.isEmpty { pendingIdeasSection }
                                if !later.isEmpty { laterSection }
                                Spacer(minLength: 40)
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 16)
                        }
                    }
                }
            }
            .navigationTitle("Gifting")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddGiftIdea = true
                    } label: {
                        Image(systemName: "plus").fontWeight(.semibold)
                    }
                }
            }
            .sheet(isPresented: $showingAddGiftIdea) {
                QuickAddGiftIdeaSheet()
            }
        }
    }

    // MARK: - Sections

    private var urgentSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Coming Up")
            VStack(spacing: 10) {
                ForEach(next30) { date in
                    upcomingDateCard(date)
                }
            }
        }
    }

    private var laterSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Later")
            AppCard {
                VStack(spacing: 0) {
                    ForEach(later.prefix(20)) { date in
                        upcomingDateRow(date)
                        if date.id != later.prefix(20).last?.id {
                            Divider().padding(.leading, 56)
                        }
                    }
                }
            }
        }
    }

    private var pendingIdeasSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Gift Ideas in Progress")
            AppCard {
                VStack(spacing: 0) {
                    ForEach(pendingIdeas.prefix(10)) { idea in
                        if let person = idea.person {
                            NavigationLink(destination: PersonDetailView(person: person)) {
                                PendingIdeaRow(idea: idea)
                            }
                            .buttonStyle(.plain)
                        } else {
                            PendingIdeaRow(idea: idea)
                        }
                        if idea.id != pendingIdeas.prefix(10).last?.id {
                            Divider().padding(.leading, 56)
                        }
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            EmptyStateView(
                icon: "gift.fill",
                title: "Nothing here yet",
                subtitle: "Birthdays and anniversaries you add to contacts will appear here automatically"
            )
        }
    }

    // MARK: - Row builders

    @ViewBuilder
    private func upcomingDateCard(_ date: UpcomingDate) -> some View {
        Group {
            if let person = date.person {
                NavigationLink(destination: PersonDetailView(person: person)) {
                    UpcomingDateCard(date: date)
                }
                .buttonStyle(.plain)
            } else if let household = date.household {
                NavigationLink(destination: HouseholdDetailView(household: household)) {
                    UpcomingDateCard(date: date)
                }
                .buttonStyle(.plain)
            }
        }
    }

    @ViewBuilder
    private func upcomingDateRow(_ date: UpcomingDate) -> some View {
        Group {
            if let person = date.person {
                NavigationLink(destination: PersonDetailView(person: person)) {
                    UpcomingDateListRow(date: date)
                }
                .buttonStyle(.plain)
            } else if let household = date.household {
                NavigationLink(destination: HouseholdDetailView(household: household)) {
                    UpcomingDateListRow(date: date)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Helpers

    private func daysUntil(_ date: Date) -> Int {
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

// MARK: - Card views

struct UpcomingDateCard: View {
    let date: UpcomingDate

    var body: some View {
        AppCard {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Color.accent.opacity(0.12))
                        .frame(width: 48, height: 48)
                    Image(systemName: date.icon)
                        .font(.system(size: 20))
                        .foregroundStyle(.accent)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(date.recipientName)
                        .font(.bodyMedium)
                        .foregroundStyle(.primaryText)
                    Text(date.occasionLabel)
                        .font(.captionRegular)
                        .foregroundStyle(.secondaryText)
                    if let person = date.person, !person.giftIdeas.filter({ !$0.status.isDone }).isEmpty {
                        let count = person.giftIdeas.filter { !$0.status.isDone }.count
                        Label("\(count) idea\(count == 1 ? "" : "s") saved", systemImage: "lightbulb.fill")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.accent)
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 6) {
                    CountdownBadge(days: date.daysUntil)
                    Image(systemName: "chevron.right")
                        .font(.captionMedium)
                        .foregroundStyle(.tertiaryText)
                }
            }
            .padding(16)
        }
    }
}

struct UpcomingDateListRow: View {
    let date: UpcomingDate

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: date.icon)
                .foregroundStyle(.accent)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(date.recipientName)
                    .font(.bodyMedium)
                    .foregroundStyle(.primaryText)
                Text(date.occasionLabel)
                    .font(.captionRegular)
                    .foregroundStyle(.secondaryText)
            }
            Spacer()
            CountdownBadge(days: date.daysUntil)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
    }
}

struct PendingIdeaRow: View {
    let idea: GiftIdea

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: idea.status.icon)
                .foregroundStyle(.accent)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(idea.title)
                    .font(.bodyMedium)
                    .foregroundStyle(.primaryText)
                if let name = idea.person?.fullName {
                    Text("For \(name)")
                        .font(.captionRegular)
                        .foregroundStyle(.secondaryText)
                }
            }
            Spacer()
            Text(idea.status.rawValue)
                .font(.captionMedium)
                .foregroundStyle(.secondaryText)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Color.secondaryText.opacity(0.1))
                .clipShape(Capsule())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - Quick add gift idea (person-first flow)

struct QuickAddGiftIdeaSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Person.firstName) private var persons: [Person]

    @State private var selectedPerson: Person?
    @State private var title = ""
    @State private var link = ""
    @State private var priceText = ""
    @State private var status: GiftStatus = .idea
    @State private var notes = ""
    @State private var step: Step = .pickPerson

    enum Step { case pickPerson, fillIdea }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                if step == .pickPerson {
                    personPicker
                } else {
                    ideaForm
                }
            }
            .navigationTitle(step == .pickPerson ? "Who's it for?" : "Add Gift Idea")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(step == .fillIdea ? "Back" : "Cancel") {
                        if step == .fillIdea { step = .pickPerson } else { dismiss() }
                    }
                }
                if step == .fillIdea {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Add") { save() }
                            .fontWeight(.semibold)
                            .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }
            }
        }
    }

    private var personPicker: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                ForEach(persons) { person in
                    Button {
                        selectedPerson = person
                        step = .fillIdea
                    } label: {
                        AppCard {
                            HStack(spacing: 14) {
                                PersonAvatar(initials: person.initials, size: 44)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(person.fullName)
                                        .font(.bodyMedium)
                                        .foregroundStyle(.primaryText)
                                    if let h = person.household {
                                        Text(h.name)
                                            .font(.captionRegular)
                                            .foregroundStyle(.secondaryText)
                                    }
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.captionMedium)
                                    .foregroundStyle(.tertiaryText)
                            }
                            .padding(14)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
        }
    }

    private var ideaForm: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Who it's for
                if let person = selectedPerson {
                    AppCard {
                        HStack(spacing: 12) {
                            PersonAvatar(initials: person.initials, size: 40)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(person.fullName).font(.bodyMedium).foregroundStyle(.primaryText)
                                if let days = person.daysUntilBirthday, days <= 60 {
                                    Label("Birthday in \(days) day\(days == 1 ? "" : "s")", systemImage: "birthday.cake.fill")
                                        .font(.captionMedium)
                                        .foregroundStyle(.accent)
                                }
                            }
                            Spacer()
                        }
                        .padding(14)
                    }
                }

                AppCard {
                    VStack(spacing: 12) {
                        FormRow("Gift Idea") {
                            TextField("What's the idea?", text: $title)
                                .textFieldStyle(AppTextFieldStyle())
                        }
                        FormRow("Link (optional)") {
                            TextField("https://...", text: $link)
                                .textFieldStyle(AppTextFieldStyle())
                                .keyboardType(.URL)
                                .autocapitalization(.none)
                        }
                        FormRow("Estimated Price") {
                            TextField("$0", text: $priceText)
                                .textFieldStyle(AppTextFieldStyle())
                                .keyboardType(.decimalPad)
                        }
                    }
                    .padding(16)
                }

                VStack(alignment: .leading, spacing: 10) {
                    SectionHeader(title: "Status")
                    AppCard {
                        VStack(spacing: 0) {
                            ForEach(GiftStatus.allCases, id: \.self) { s in
                                Button { status = s } label: {
                                    HStack(spacing: 10) {
                                        Image(systemName: s.icon).foregroundStyle(.accent).frame(width: 24)
                                        Text(s.rawValue).font(.bodyRegular).foregroundStyle(.primaryText)
                                        Spacer()
                                        if status == s {
                                            Image(systemName: "checkmark.circle.fill").foregroundStyle(.accent)
                                        }
                                    }
                                    .padding(.horizontal, 16).padding(.vertical, 13)
                                }
                                if s != GiftStatus.allCases.last { Divider().padding(.leading, 16) }
                            }
                        }
                    }
                }

                AppCard {
                    TextField("Notes...", text: $notes, axis: .vertical)
                        .lineLimit(2...5).font(.bodyRegular).padding(16)
                }

                Spacer(minLength: 40)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
        }
    }

    private func save() {
        let price = Double(priceText.filter { $0.isNumber || $0 == "." })
        let idea = GiftIdea(title: title)
        idea.link = link
        idea.priceEstimate = price
        idea.status = status
        idea.notes = notes
        idea.person = selectedPerson
        modelContext.insert(idea)
        dismiss()
    }
}
