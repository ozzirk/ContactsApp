import SwiftUI
import SwiftData

struct PersonDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var person: Person

    @State private var showingEdit = false
    @State private var showingAddGiftIdea = false
    @State private var showingAddGiftHistory = false

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    contactSection
                    if !person.interests.isEmpty || !person.allergies.isEmpty { preferencesSection }
                    giftSection
                    if !person.giftHistory.isEmpty { giftHistorySection }
                    if !person.notes.isEmpty { notesSection }
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
            }
        }
        .navigationTitle(person.fullName)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Edit") { showingEdit = true }
            }
        }
        .sheet(isPresented: $showingEdit) {
            PersonFormView(person: person, household: person.household)
        }
        .sheet(isPresented: $showingAddGiftIdea) {
            GiftIdeaFormView(person: person)
        }
        .sheet(isPresented: $showingAddGiftHistory) {
            GiftHistoryFormView(person: person)
        }
    }

    private var headerSection: some View {
        AppCard {
            VStack(spacing: 14) {
                PersonAvatar(initials: person.initials, size: 72)

                VStack(spacing: 4) {
                    Text(person.fullName)
                        .font(.titleLarge)
                        .foregroundStyle(.primaryText)

                    HStack(spacing: 8) {
                        Label(person.relationshipType.rawValue, systemImage: person.relationshipType.icon)
                            .font(.captionMedium)
                            .foregroundStyle(.secondaryText)

                        if let household = person.household {
                            Text("·")
                                .foregroundStyle(.tertiaryText)
                            Label(household.name, systemImage: "house")
                                .font(.captionMedium)
                                .foregroundStyle(.secondaryText)
                        }
                    }
                }

                if let days = person.daysUntilBirthday {
                    Divider().padding(.horizontal)
                    HStack {
                        Image(systemName: "birthday.cake.fill")
                            .foregroundStyle(.accent)
                        if let bday = person.birthday {
                            Text(bday, format: .dateTime.month(.wide).day())
                        }
                        Spacer()
                        CountdownBadge(days: days)
                    }
                    .padding(.horizontal, 4)
                    .font(.bodyRegular)
                    .foregroundStyle(.primaryText)
                }

                if !person.tags.isEmpty {
                    Divider().padding(.horizontal)
                    FlowLayout(spacing: 6) {
                        ForEach(person.tags, id: \.self) { tag in
                            TagChip(label: tag)
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
            .padding(20)
        }
    }

    private var contactSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Contact")
            AppCard {
                VStack(spacing: 0) {
                    if !person.phone.isEmpty {
                        contactRow(icon: "phone.fill", value: person.phone, action: {
                            if let url = URL(string: "tel:\(person.phone.filter { $0.isNumber })") {
                                UIApplication.shared.open(url)
                            }
                        })
                        Divider().padding(.leading, 44)
                    }
                    if !person.email.isEmpty {
                        contactRow(icon: "envelope.fill", value: person.email, action: {
                            if let url = URL(string: "mailto:\(person.email)") {
                                UIApplication.shared.open(url)
                            }
                        })
                    }
                    if person.phone.isEmpty && person.email.isEmpty {
                        EmptyStateView(icon: "person.fill", title: "No contact info", subtitle: "Add phone or email via Edit")
                    }
                }
            }
        }
    }

    private func contactRow(icon: String, value: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundStyle(.accent)
                    .frame(width: 28)
                Text(value)
                    .font(.bodyRegular)
                    .foregroundStyle(.primaryText)
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.captionRegular)
                    .foregroundStyle(.tertiaryText)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 13)
        }
    }

    private var preferencesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Preferences")
            AppCard {
                VStack(alignment: .leading, spacing: 12) {
                    if !person.interests.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Label("Interests", systemImage: "sparkles")
                                .font(.captionMedium)
                                .foregroundStyle(.secondaryText)
                            FlowLayout(spacing: 6) {
                                ForEach(person.interests, id: \.self) { interest in
                                    TagChip(label: interest)
                                }
                            }
                        }
                    }

                    if !person.allergies.isEmpty {
                        if !person.interests.isEmpty { Divider() }
                        VStack(alignment: .leading, spacing: 6) {
                            Label("Allergies & Dietary", systemImage: "exclamationmark.triangle.fill")
                                .font(.captionMedium)
                                .foregroundStyle(Color.warning)
                            FlowLayout(spacing: 6) {
                                ForEach(person.allergies, id: \.self) { allergy in
                                    TagChip(label: allergy)
                                }
                            }
                        }
                    }

                    Divider()
                    Label(person.giftPreference.displayName, systemImage: "gift.fill")
                        .font(.bodyRegular)
                        .foregroundStyle(.primaryText)
                }
                .padding(16)
            }
        }
    }

    private var giftSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Gift Ideas", action: { showingAddGiftIdea = true }, actionLabel: "Add")

            AppCard {
                VStack(spacing: 0) {
                    if person.giftIdeas.isEmpty {
                        EmptyStateView(icon: "lightbulb.fill", title: "No gift ideas", subtitle: "Tap Add to capture an idea")
                    } else {
                        ForEach(person.giftIdeas.sorted { $0.createdAt > $1.createdAt }) { idea in
                            GiftIdeaRow(idea: idea)
                            if idea.id != person.giftIdeas.last?.id {
                                Divider().padding(.leading, 16)
                            }
                        }
                    }
                }
            }
        }
    }

    private var giftHistorySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Gift History", action: { showingAddGiftHistory = true }, actionLabel: "Add")
            AppCard {
                VStack(spacing: 0) {
                    ForEach(person.giftHistory.sorted { $0.date > $1.date }) { entry in
                        GiftHistoryRow(entry: entry)
                        if entry.id != person.giftHistory.last?.id {
                            Divider().padding(.leading, 16)
                        }
                    }
                }
            }
        }
    }

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Notes")
            AppCard {
                Text(person.notes)
                    .font(.bodyRegular)
                    .foregroundStyle(.primaryText)
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

struct GiftIdeaRow: View {
    @Bindable var idea: GiftIdea

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: idea.status.icon)
                .foregroundStyle(idea.status.isDone ? Color.success : Color.accent)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(idea.title)
                    .font(.bodyRegular)
                    .foregroundStyle(idea.status.isDone ? .secondaryText : .primaryText)
                    .strikethrough(idea.status.isDone)
                if let price = idea.formattedPrice {
                    Text(price)
                        .font(.captionRegular)
                        .foregroundStyle(.secondaryText)
                }
            }
            Spacer()
            Menu {
                ForEach(GiftStatus.allCases, id: \.self) { status in
                    Button(status.rawValue) { idea.status = status }
                }
            } label: {
                Text(idea.status.rawValue)
                    .font(.captionMedium)
                    .foregroundStyle(.secondaryText)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.secondaryText.opacity(0.1))
                    .clipShape(Capsule())
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

struct GiftHistoryRow: View {
    let entry: GiftHistory

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .center, spacing: 0) {
                Text("\(entry.year)")
                    .font(.captionMedium)
                    .foregroundStyle(.accent)
            }
            .frame(width: 40)

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.giftGiven)
                    .font(.bodyRegular)
                    .foregroundStyle(.primaryText)
                HStack(spacing: 6) {
                    if !entry.occasionType.isEmpty {
                        Text(entry.occasionType)
                            .font(.captionRegular)
                            .foregroundStyle(.secondaryText)
                    }
                    if let amt = entry.formattedAmount {
                        Text("·").foregroundStyle(.tertiaryText).font(.captionRegular)
                        Text(amt).font(.captionMedium).foregroundStyle(.secondaryText)
                    }
                }
            }

            Spacer()

            if entry.doNotRepeat {
                Image(systemName: "nosign")
                    .font(.captionRegular)
                    .foregroundStyle(Color.destructive)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}
