import SwiftUI
import SwiftData

struct GiftingDashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var occasions: [Occasion]
    @Query private var persons: [Person]
    @State private var showingAddOccasion = false

    private var upcoming: [Occasion] {
        occasions
            .filter { $0.daysUntil >= 0 }
            .sorted { $0.daysUntil < $1.daysUntil }
            .prefix(20)
            .map { $0 }
    }

    private var next30: [Occasion] { upcoming.filter { $0.daysUntil <= 30 } }
    private var birthdaysNext30: [Person] { persons.filter { ($0.daysUntilBirthday ?? 999) <= 30 }.sorted { ($0.daysUntilBirthday ?? 999) < ($1.daysUntilBirthday ?? 999) } }

    private var shoppingWorklist: [(String, [Occasion])] {
        let holidays = upcoming.filter {
            [.christmas, .hanukkah, .mothersDay, .fathersDay, .valentinesDay].contains($0.occasionType)
        }
        let grouped = Dictionary(grouping: holidays) { $0.occasionType.rawValue }
        return grouped.map { ($0.key, $0.value) }.sorted { $0.0 < $1.0 }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 24) {
                        if !next30.isEmpty || !birthdaysNext30.isEmpty {
                            upcomingSection
                        }
                        if !shoppingWorklist.isEmpty {
                            shoppingSection
                        }
                        allOccasionsSection
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                }
            }
            .navigationTitle("Gifting")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showingAddOccasion = true } label: {
                        Image(systemName: "plus").fontWeight(.semibold)
                    }
                }
            }
            .sheet(isPresented: $showingAddOccasion) { OccasionFormView() }
        }
    }

    private var upcomingSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Coming Up")
            VStack(spacing: 10) {
                ForEach(birthdaysNext30) { person in
                    NavigationLink(destination: PersonDetailView(person: person)) {
                        AppCard {
                            HStack(spacing: 14) {
                                ZStack {
                                    Circle().fill(Color.accent.opacity(0.12)).frame(width: 44, height: 44)
                                    Image(systemName: "birthday.cake.fill")
                                        .foregroundStyle(.accent)
                                }
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(person.fullName).font(.bodyMedium).foregroundStyle(.primaryText)
                                    Text("Birthday")
                                        .font(.captionRegular).foregroundStyle(.secondaryText)
                                }
                                Spacer()
                                if let days = person.daysUntilBirthday {
                                    CountdownBadge(days: days)
                                }
                            }
                            .padding(16)
                        }
                    }
                    .buttonStyle(.plain)
                }

                ForEach(next30) { occasion in
                    NavigationLink(destination: OccasionDetailView(occasion: occasion)) {
                        OccasionCountdownCard(occasion: occasion)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var shoppingSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Shopping Worklist")
            AppCard {
                VStack(spacing: 0) {
                    ForEach(shoppingWorklist, id: \.0) { (name, occs) in
                        HStack(spacing: 14) {
                            Image(systemName: occs.first?.occasionType.icon ?? "gift.fill")
                                .foregroundStyle(.accent).frame(width: 28)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(name).font(.bodyMedium).foregroundStyle(.primaryText)
                                let done = occs.filter { $0.giftIdeas.contains { $0.status == .given } }.count
                                Text("\(done) of \(occs.count) done")
                                    .font(.captionRegular).foregroundStyle(.secondaryText)
                            }
                            Spacer()
                            CountdownBadge(days: occs.min { $0.daysUntil < $1.daysUntil }?.daysUntil ?? 0)
                        }
                        .padding(.horizontal, 16).padding(.vertical, 14)
                        if name != shoppingWorklist.last?.0 { Divider().padding(.leading, 56) }
                    }
                }
            }
        }
    }

    private var allOccasionsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "All Occasions") {
                showingAddOccasion = true
            } actionLabel: "Add"

            if occasions.isEmpty {
                EmptyStateView(icon: "gift.fill", title: "No occasions yet", subtitle: "Add birthdays, anniversaries, and holidays to track gifting")
            } else {
                AppCard {
                    VStack(spacing: 0) {
                        ForEach(upcoming) { occasion in
                            NavigationLink(destination: OccasionDetailView(occasion: occasion)) {
                                OccasionListRow(occasion: occasion)
                            }
                            .buttonStyle(.plain)
                            if occasion.id != upcoming.last?.id { Divider().padding(.leading, 56) }
                        }
                    }
                }
            }
        }
    }
}

struct OccasionCountdownCard: View {
    let occasion: Occasion

    var body: some View {
        AppCard {
            HStack(spacing: 14) {
                ZStack {
                    Circle().fill(Color.accent.opacity(0.12)).frame(width: 44, height: 44)
                    Image(systemName: occasion.occasionType.icon).foregroundStyle(.accent)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(occasion.recipientName).font(.bodyMedium).foregroundStyle(.primaryText)
                    Text(occasion.displayLabel).font(.captionRegular).foregroundStyle(.secondaryText)
                }
                Spacer()
                CountdownBadge(days: occasion.daysUntil)
            }
            .padding(16)
        }
    }
}

struct OccasionListRow: View {
    let occasion: Occasion

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: occasion.occasionType.icon)
                .foregroundStyle(.accent).frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(occasion.recipientName).font(.bodyMedium).foregroundStyle(.primaryText)
                Text(occasion.displayLabel).font(.captionRegular).foregroundStyle(.secondaryText)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                CountdownBadge(days: occasion.daysUntil)
                let pending = occasion.giftIdeas.filter { !$0.status.isDone }.count
                if pending > 0 {
                    Text("\(pending) to buy").font(.system(size: 10)).foregroundStyle(.warning)
                }
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 13)
    }
}
