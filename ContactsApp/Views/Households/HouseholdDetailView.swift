import SwiftUI
import SwiftData

struct HouseholdDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var household: Household

    @State private var showingEdit = false
    @State private var showingAddPerson = false
    @State private var showingAddressSheet = false
    @State private var personToEdit: Person?
    @State private var showingDeleteConfirm = false

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    membersSection
                    addressSection
                    if !household.anniversaries.isEmpty { anniversariesSection }
                    if !household.notes.isEmpty { notesSection }
                    giftingTagsSection
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
            }
        }
        .navigationTitle(household.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Edit") { showingEdit = true }
            }
        }
        .sheet(isPresented: $showingEdit) {
            HouseholdFormView(household: household)
        }
        .sheet(isPresented: $showingAddPerson) {
            PersonFormView(household: household)
        }
        .sheet(item: $personToEdit) { person in
            PersonFormView(person: person, household: household)
        }
        .sheet(isPresented: $showingAddressSheet) {
            AddressPreviewSheet(household: household)
        }
    }

    private var headerSection: some View {
        AppCard {
            VStack(spacing: 12) {
                HouseholdAvatar(name: household.name, size: 72)

                VStack(spacing: 4) {
                    Text(household.name)
                        .font(.titleLarge)
                        .foregroundStyle(.primaryText)
                    Text(AddressFormatter.mailingLine(household: household))
                        .font(.captionRegular)
                        .foregroundStyle(.secondaryText)
                }

                Divider().padding(.horizontal)

                HStack(spacing: 0) {
                    statView(value: "\(household.adults.count)", label: "Adults")
                    Divider().frame(height: 32)
                    statView(value: "\(household.children.count)", label: "Children")
                    Divider().frame(height: 32)
                    Button {
                        showingAddressSheet = true
                    } label: {
                        VStack(spacing: 2) {
                            Image(systemName: "envelope.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(.accent)
                            Text("Address")
                                .font(.captionMedium)
                                .foregroundStyle(.secondaryText)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .padding(20)
        }
    }

    private func statView(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.titleMedium)
                .foregroundStyle(.primaryText)
            Text(label)
                .font(.captionRegular)
                .foregroundStyle(.secondaryText)
        }
        .frame(maxWidth: .infinity)
    }

    private var membersSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Members") {
                showingAddPerson = true
            } actionLabel: "Add"

            AppCard {
                VStack(spacing: 0) {
                    if household.persons.isEmpty {
                        EmptyStateView(
                            icon: "person.fill",
                            title: "No members",
                            subtitle: "Tap Add to add someone to this household"
                        )
                    } else {
                        ForEach(household.persons.sorted { $0.role.rawValue < $1.role.rawValue }) { person in
                            NavigationLink(destination: PersonDetailView(person: person)) {
                                PersonRowInHousehold(person: person)
                            }
                            .buttonStyle(.plain)

                            if person.id != household.persons.last?.id {
                                Divider().padding(.leading, 62)
                            }
                        }
                    }
                }
            }
        }
    }

    private var addressSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Address")
            AppCard {
                VStack(alignment: .leading, spacing: 8) {
                    Text(household.formattedAddress)
                        .font(.bodyRegular)
                        .foregroundStyle(.primaryText)
                        .multilineTextAlignment(.leading)

                    if household.useCustomMailingAddress {
                        Label("Custom mailing address set", systemImage: "info.circle")
                            .font(.captionRegular)
                            .foregroundStyle(.secondaryText)
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var anniversariesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Anniversaries")
            AppCard {
                VStack(spacing: 0) {
                    ForEach(household.anniversaries) { ann in
                        HStack {
                            Image(systemName: "heart.fill")
                                .foregroundStyle(.accent)
                                .frame(width: 28)
                            Text(ann.label)
                                .font(.bodyRegular)
                                .foregroundStyle(.primaryText)
                            Spacer()
                            Text(ann.date, format: .dateTime.month().day().year())
                                .font(.captionRegular)
                                .foregroundStyle(.secondaryText)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                }
            }
        }
    }

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Notes")
            AppCard {
                Text(household.notes)
                    .font(.bodyRegular)
                    .foregroundStyle(.primaryText)
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var giftingTagsSection: some View {
        Group {
            if !household.giftingTags.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    SectionHeader(title: "Gifting Groups")
                    AppCard {
                        FlowLayout(spacing: 8) {
                            ForEach(household.giftingTags, id: \.self) { tag in
                                TagChip(label: tag)
                            }
                        }
                        .padding(16)
                    }
                }
            }
        }
    }
}

struct PersonRowInHousehold: View {
    let person: Person

    var body: some View {
        HStack(spacing: 12) {
            PersonAvatar(initials: person.initials, size: 40)
            VStack(alignment: .leading, spacing: 2) {
                Text(person.fullName)
                    .font(.bodyMedium)
                    .foregroundStyle(.primaryText)
                HStack(spacing: 6) {
                    Text(person.role.rawValue)
                        .font(.captionRegular)
                        .foregroundStyle(.secondaryText)
                    if let days = person.daysUntilBirthday, days <= 30 {
                        CountdownBadge(days: days)
                    }
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.captionMedium)
                .foregroundStyle(.tertiaryText)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

struct AddressPreviewSheet: View {
    @Environment(\.dismiss) private var dismiss
    let household: Household
    @State private var copied = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                VStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 16) {
                        SectionHeader(title: "Mailing Label")
                        AppCard {
                            VStack(alignment: .leading, spacing: 4) {
                                ForEach(AddressFormatter.envelopeLine(household: household), id: \.self) { line in
                                    Text(line)
                                        .font(.bodyRegular)
                                        .foregroundStyle(.primaryText)
                                }
                            }
                            .padding(20)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        SectionHeader(title: "Addressing Styles")
                        AppCard {
                            VStack(spacing: 0) {
                                ForEach(AddressingStyle.allCases, id: \.self) { style in
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(style.displayName)
                                                .font(.captionMedium)
                                                .foregroundStyle(.secondaryText)
                                            Text(previewFor(style: style))
                                                .font(.bodyRegular)
                                                .foregroundStyle(.primaryText)
                                        }
                                        Spacer()
                                        if household.preferredAddressingStyle == style {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundStyle(.accent)
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    if style != AddressingStyle.allCases.last {
                                        Divider().padding(.leading, 16)
                                    }
                                }
                            }
                        }
                    }

                    Button {
                        UIPasteboard.general.string = AddressFormatter.labelBlock(household: household)
                        copied = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { copied = false }
                    } label: {
                        Label(copied ? "Copied!" : "Copy Address", systemImage: copied ? "checkmark" : "doc.on.doc")
                            .font(.bodyMedium)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.accent)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }

                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
            }
            .navigationTitle("Address")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func previewFor(style: AddressingStyle) -> String {
        let original = household.preferredAddressingStyle
        // Temporarily compute without mutation — we create a mirror
        let adults = household.adults
        switch style {
        case .familyName:
            return household.name.isEmpty ? "The \(adults.first?.lastName ?? "Family") Family" : household.name
        case .formalCouple:
            guard adults.count >= 2 else { return adults.first?.fullName ?? "" }
            let last = adults[0].lastName
            return adults.allSatisfy { $0.lastName == last } ? "Mr. and Mrs. \(last)" : adults.map { $0.fullName }.joined(separator: " and ")
        case .firstNames:
            let names = adults.map { $0.firstName }.joined(separator: " and ")
            let last = adults.first?.lastName ?? ""
            return names + (last.isEmpty ? "" : " \(last)")
        case .individual:
            return adults.first?.fullName ?? household.name
        }
    }
}
