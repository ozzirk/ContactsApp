import SwiftUI
import SwiftData

struct OccasionDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var occasion: Occasion
    @State private var showingEdit = false
    @State private var showingAddIdea = false

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 24) {
                    headerCard
                    giftIdeasSection
                    if !occasion.notes.isEmpty { notesSection }
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20).padding(.top, 8)
            }
        }
        .navigationTitle(occasion.displayLabel)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button { showingAddIdea = true } label: { Image(systemName: "lightbulb") }
                Button("Edit") { showingEdit = true }
            }
        }
        .sheet(isPresented: $showingEdit) { OccasionFormView(occasion: occasion) }
        .sheet(isPresented: $showingAddIdea) { GiftIdeaFormView(occasion: occasion) }
    }

    private var headerCard: some View {
        AppCard {
            VStack(spacing: 14) {
                HStack(spacing: 14) {
                    ZStack {
                        Circle().fill(Color.accent.opacity(0.14)).frame(width: 56, height: 56)
                        Image(systemName: occasion.occasionType.icon).font(.system(size: 22)).foregroundStyle(.accent)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text(occasion.recipientName).font(.titleMedium).foregroundStyle(.primaryText)
                        Text(occasion.displayLabel).font(.captionMedium).foregroundStyle(.secondaryText)
                    }
                    Spacer()
                    CountdownBadge(days: occasion.daysUntil)
                }

                Divider()

                HStack {
                    Label(occasion.nextOccurrence.formatted(.dateTime.month(.wide).day().year()), systemImage: "calendar")
                        .font(.captionRegular).foregroundStyle(.secondaryText)
                    Spacer()
                    if let budget = occasion.budget {
                        Label(String(format: "$%.0f budget", budget), systemImage: "dollarsign.circle")
                            .font(.captionMedium).foregroundStyle(.accent)
                    }
                }

                if occasion.giftRequirement != .none {
                    Label(occasion.giftRequirement.rawValue, systemImage: "gift.fill")
                        .font(.captionMedium)
                        .foregroundStyle(occasion.giftRequirement == .required ? .accent : .secondaryText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(20)
        }
    }

    private var giftIdeasSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Gift Ideas") {
                showingAddIdea = true
            } actionLabel: "Add"

            AppCard {
                if occasion.giftIdeas.isEmpty {
                    EmptyStateView(icon: "lightbulb.fill", title: "No ideas yet", subtitle: "Tap Add to capture a gift idea")
                } else {
                    VStack(spacing: 0) {
                        ForEach(occasion.giftIdeas.sorted { $0.createdAt > $1.createdAt }) { idea in
                            GiftIdeaRow(idea: idea)
                            if idea.id != occasion.giftIdeas.last?.id { Divider().padding(.leading, 16) }
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
                Text(occasion.notes).font(.bodyRegular).foregroundStyle(.primaryText)
                    .padding(16).frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

struct OccasionFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Person.firstName) private var persons: [Person]
    @Query(sort: \Household.name) private var households: [Household]

    var occasion: Occasion?

    @State private var occasionType: OccasionType = .birthday
    @State private var customLabel = ""
    @State private var date = Date()
    @State private var isRecurring = true
    @State private var giftRequirement: GiftRequirement = .optional
    @State private var budgetText = ""
    @State private var notes = ""
    @State private var recipientMode: RecipientMode = .person
    @State private var selectedPersonID: UUID?
    @State private var selectedHouseholdID: UUID?

    enum RecipientMode: String, CaseIterable {
        case person = "Person"
        case household = "Household"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        typeSection
                        recipientSection
                        dateSection
                        giftSection
                        AppCard {
                            TextField("Notes...", text: $notes, axis: .vertical)
                                .lineLimit(2...5).font(.bodyRegular).padding(16)
                        }
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20).padding(.top, 20)
                }
            }
            .navigationTitle(occasion == nil ? "New Occasion" : "Edit Occasion")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button(occasion == nil ? "Add" : "Save") { save() }
                        .fontWeight(.semibold)
                }
            }
            .onAppear { populate() }
        }
    }

    private var typeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Occasion Type")
            AppCard {
                VStack(spacing: 12) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(OccasionType.allCases, id: \.self) { type in
                                Button { occasionType = type } label: {
                                    VStack(spacing: 4) {
                                        Image(systemName: type.icon)
                                            .font(.system(size: 18))
                                            .foregroundStyle(occasionType == type ? .white : .accent)
                                            .frame(width: 44, height: 44)
                                            .background(occasionType == type ? Color.accent : Color.accent.opacity(0.1))
                                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                        Text(type.rawValue)
                                            .font(.system(size: 10, weight: .medium))
                                            .foregroundStyle(occasionType == type ? .accent : .secondaryText)
                                            .multilineTextAlignment(.center)
                                    }
                                    .frame(width: 60)
                                }
                            }
                        }
                        .padding(16)
                    }

                    FormRow("Custom Label (optional)") {
                        TextField("Override the default label", text: $customLabel)
                            .textFieldStyle(AppTextFieldStyle())
                    }
                    .padding(.horizontal, 16).padding(.bottom, 16)
                }
            }
        }
    }

    private var recipientSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Recipient")
            AppCard {
                VStack(spacing: 12) {
                    Picker("Recipient Type", selection: $recipientMode) {
                        ForEach(RecipientMode.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)

                    if recipientMode == .person {
                        ScrollView(.vertical) {
                            VStack(spacing: 0) {
                                ForEach(persons) { person in
                                    Button { selectedPersonID = person.id } label: {
                                        HStack(spacing: 12) {
                                            PersonAvatar(initials: person.initials, size: 34)
                                            Text(person.fullName).font(.bodyRegular).foregroundStyle(.primaryText)
                                            Spacer()
                                            Image(systemName: selectedPersonID == person.id ? "checkmark.circle.fill" : "circle")
                                                .foregroundStyle(selectedPersonID == person.id ? .accent : .tertiaryText)
                                        }
                                        .padding(.horizontal, 4).padding(.vertical, 10)
                                    }
                                    if person.id != persons.last?.id { Divider() }
                                }
                            }
                        }
                        .frame(maxHeight: 220)
                    } else {
                        ScrollView(.vertical) {
                            VStack(spacing: 0) {
                                ForEach(households) { h in
                                    Button { selectedHouseholdID = h.id } label: {
                                        HStack(spacing: 12) {
                                            HouseholdAvatar(name: h.name, size: 34)
                                            Text(h.name).font(.bodyRegular).foregroundStyle(.primaryText)
                                            Spacer()
                                            Image(systemName: selectedHouseholdID == h.id ? "checkmark.circle.fill" : "circle")
                                                .foregroundStyle(selectedHouseholdID == h.id ? .accent : .tertiaryText)
                                        }
                                        .padding(.horizontal, 4).padding(.vertical, 10)
                                    }
                                    if h.id != households.last?.id { Divider() }
                                }
                            }
                        }
                        .frame(maxHeight: 220)
                    }
                }
                .padding(16)
            }
        }
    }

    private var dateSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Date")
            AppCard {
                VStack(spacing: 12) {
                    DatePicker("Date", selection: $date, displayedComponents: .date).font(.bodyRegular)
                    Toggle("Repeats annually", isOn: $isRecurring).font(.bodyRegular).tint(.accent)
                }
                .padding(16)
            }
        }
    }

    private var giftSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Gifting")
            AppCard {
                VStack(spacing: 12) {
                    Picker("Gift requirement", selection: $giftRequirement) {
                        ForEach(GiftRequirement.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.menu).font(.bodyRegular)
                    FormRow("Budget (optional)") {
                        TextField("$0", text: $budgetText)
                            .textFieldStyle(AppTextFieldStyle()).keyboardType(.decimalPad)
                    }
                }
                .padding(16)
            }
        }
    }

    private func save() {
        let budget = Double(budgetText.filter { $0.isNumber || $0 == "." })
        if let existing = occasion {
            existing.occasionType = occasionType
            existing.customLabel = customLabel
            existing.date = date
            existing.isRecurringAnnually = isRecurring
            existing.giftRequirement = giftRequirement
            existing.budget = budget
            existing.notes = notes
            existing.person = persons.first { $0.id == selectedPersonID }
            existing.household = households.first { $0.id == selectedHouseholdID }
        } else {
            let occ = Occasion(type: occasionType, date: date)
            occ.customLabel = customLabel
            occ.isRecurringAnnually = isRecurring
            occ.giftRequirement = giftRequirement
            occ.budget = budget
            occ.notes = notes
            occ.person = persons.first { $0.id == selectedPersonID }
            occ.household = households.first { $0.id == selectedHouseholdID }
            modelContext.insert(occ)
        }
        dismiss()
    }

    private func populate() {
        guard let o = occasion else { return }
        occasionType = o.occasionType; customLabel = o.customLabel; date = o.date
        isRecurring = o.isRecurringAnnually; giftRequirement = o.giftRequirement
        budgetText = o.budget.map { String(format: "%.0f", $0) } ?? ""; notes = o.notes
        if let p = o.person { recipientMode = .person; selectedPersonID = p.id }
        else if let h = o.household { recipientMode = .household; selectedHouseholdID = h.id }
    }
}
