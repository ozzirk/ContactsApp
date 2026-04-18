import SwiftUI
import SwiftData

struct DashboardView: View {
    @Query private var households: [Household]
    @Query private var persons: [Person]
    @Query private var occasions: [Occasion]
    @Query(sort: \Event.date) private var events: [Event]
    @Query private var groups: [ContactGroup]

    private var upcomingBirthdays: [Person] {
        persons.filter { ($0.daysUntilBirthday ?? 999) <= 30 }
              .sorted { ($0.daysUntilBirthday ?? 999) < ($1.daysUntilBirthday ?? 999) }
    }

    private var upcomingOccasions: [Occasion] {
        occasions.filter { $0.daysUntil >= 0 && $0.daysUntil <= 30 }
                 .sorted { $0.daysUntil < $1.daysUntil }
    }

    private var upcomingEvents: [Event] {
        events.filter { !$0.isPast }.prefix(3).map { $0 }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 28) {
                        statsRow
                        if !upcomingBirthdays.isEmpty || !upcomingOccasions.isEmpty {
                            upcomingSection
                        }
                        if !upcomingEvents.isEmpty {
                            eventsSection
                        }
                        if households.isEmpty {
                            gettingStartedSection
                        }
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }
            .navigationTitle("Home")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    private var statsRow: some View {
        HStack(spacing: 12) {
            StatCard(value: "\(households.count)", label: "Households", icon: "house.fill")
            StatCard(value: "\(persons.count)", label: "People", icon: "person.2.fill")
            StatCard(value: "\(groups.count)", label: "Groups", icon: "tag.fill")
        }
    }

    private var upcomingSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Coming Up Soon")
            VStack(spacing: 8) {
                ForEach(upcomingBirthdays.prefix(3)) { person in
                    NavigationLink(destination: PersonDetailView(person: person)) {
                        AppCard {
                            HStack(spacing: 14) {
                                PersonAvatar(initials: person.initials, size: 40)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(person.fullName).font(.bodyMedium).foregroundStyle(.primaryText)
                                    Text("Birthday").font(.captionRegular).foregroundStyle(.secondaryText)
                                }
                                Spacer()
                                if let days = person.daysUntilBirthday { CountdownBadge(days: days) }
                            }
                            .padding(14)
                        }
                    }
                    .buttonStyle(.plain)
                }

                ForEach(upcomingOccasions.prefix(3)) { occasion in
                    NavigationLink(destination: OccasionDetailView(occasion: occasion)) {
                        AppCard {
                            HStack(spacing: 14) {
                                ZStack {
                                    Circle().fill(Color.accent.opacity(0.12)).frame(width: 40, height: 40)
                                    Image(systemName: occasion.occasionType.icon).foregroundStyle(.accent)
                                }
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(occasion.recipientName).font(.bodyMedium).foregroundStyle(.primaryText)
                                    Text(occasion.displayLabel).font(.captionRegular).foregroundStyle(.secondaryText)
                                }
                                Spacer()
                                CountdownBadge(days: occasion.daysUntil)
                            }
                            .padding(14)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var eventsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Upcoming Events")
            VStack(spacing: 8) {
                ForEach(upcomingEvents) { event in
                    NavigationLink(destination: EventDetailView(event: event)) {
                        AppCard {
                            HStack(spacing: 14) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .fill(Color.accent.opacity(0.12)).frame(width: 40, height: 40)
                                    Image(systemName: event.eventType.icon).foregroundStyle(.accent)
                                }
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(event.name).font(.bodyMedium).foregroundStyle(.primaryText)
                                    Text(event.date, format: .dateTime.weekday(.abbreviated).month().day())
                                        .font(.captionRegular).foregroundStyle(.secondaryText)
                                }
                                Spacer()
                                Text("\(event.invitations.count) guests")
                                    .font(.captionRegular).foregroundStyle(.tertiaryText)
                            }
                            .padding(14)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var gettingStartedSection: some View {
        AppCard {
            VStack(spacing: 16) {
                Image(systemName: "house.circle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.accent)
                Text("Welcome")
                    .font(.titleLarge).foregroundStyle(.primaryText)
                Text("Start by adding your first household. People, events, and gifting all connect through households.")
                    .font(.bodyRegular).foregroundStyle(.secondaryText)
                    .multilineTextAlignment(.center)
            }
            .padding(28)
        }
    }
}

struct StatCard: View {
    let value: String
    let label: String
    let icon: String

    var body: some View {
        AppCard {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundStyle(.accent)
                Text(value)
                    .font(.displayMedium)
                    .foregroundStyle(.primaryText)
                Text(label)
                    .font(.captionRegular)
                    .foregroundStyle(.secondaryText)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
        }
    }
}
