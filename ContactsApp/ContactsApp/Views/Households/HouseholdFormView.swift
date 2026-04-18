import SwiftUI
import SwiftData

struct HouseholdFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var household: Household?

    @State private var name = ""
    @State private var addressLine1 = ""
    @State private var addressLine2 = ""
    @State private var city = ""
    @State private var state = ""
    @State private var zip = ""
    @State private var country = "USA"
    @State private var useCustomMailing = false
    @State private var mailingLine1 = ""
    @State private var mailingLine2 = ""
    @State private var mailingCity = ""
    @State private var mailingState = ""
    @State private var mailingZip = ""
    @State private var mailingCountry = "USA"
    @State private var addressingStyle: AddressingStyle = .familyName
    @State private var notes = ""
    @State private var giftingTagsText = ""
    @State private var giftingTags: [String] = []
    @State private var anniversaries: [HouseholdAnniversary] = []
    @State private var showingAddAnniversary = false
    @State private var newAnnLabel = ""
    @State private var newAnnDate = Date()

    private var isEditing: Bool { household != nil }
    private var isValid: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }

    init(household: Household? = nil) {
        self.household = household
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        nameSection
                        addressSection
                        if useCustomMailing { mailingAddressSection }
                        addressingStyleSection
                        anniversarySection
                        giftingTagsSection
                        notesSection
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }
            .navigationTitle(isEditing ? "Edit Household" : "New Household")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Save" : "Add") { save() }
                        .fontWeight(.semibold)
                        .disabled(!isValid)
                }
            }
            .onAppear { populateFromExisting() }
        }
    }

    private var nameSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Household Name")
            AppCard {
                VStack(spacing: 12) {
                    FormRow("Name") {
                        TextField("e.g. The Smith Family", text: $name)
                            .textFieldStyle(AppTextFieldStyle())
                    }
                }
                .padding(16)
            }
        }
    }

    private var addressSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Address")
            AppCard {
                VStack(spacing: 12) {
                    FormRow("Street") {
                        TextField("Line 1", text: $addressLine1)
                            .textFieldStyle(AppTextFieldStyle())
                    }
                    TextField("Line 2 (Apt, Suite...)", text: $addressLine2)
                        .textFieldStyle(AppTextFieldStyle())
                    HStack(spacing: 8) {
                        FormRow("City") {
                            TextField("City", text: $city)
                                .textFieldStyle(AppTextFieldStyle())
                        }
                        .frame(maxWidth: .infinity)
                        FormRow("State") {
                            TextField("ST", text: $state)
                                .textFieldStyle(AppTextFieldStyle())
                        }
                        .frame(width: 64)
                        FormRow("ZIP") {
                            TextField("ZIP", text: $zip)
                                .textFieldStyle(AppTextFieldStyle())
                                .keyboardType(.numbersAndPunctuation)
                        }
                        .frame(width: 80)
                    }
                    Toggle("Use separate mailing address", isOn: $useCustomMailing)
                        .font(.bodyRegular)
                        .tint(.accent)
                }
                .padding(16)
            }
        }
    }

    private var mailingAddressSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Mailing Address")
            AppCard {
                VStack(spacing: 12) {
                    FormRow("Street") {
                        TextField("Line 1", text: $mailingLine1)
                            .textFieldStyle(AppTextFieldStyle())
                    }
                    TextField("Line 2", text: $mailingLine2)
                        .textFieldStyle(AppTextFieldStyle())
                    HStack(spacing: 8) {
                        FormRow("City") {
                            TextField("City", text: $mailingCity)
                                .textFieldStyle(AppTextFieldStyle())
                        }
                        .frame(maxWidth: .infinity)
                        FormRow("State") {
                            TextField("ST", text: $mailingState)
                                .textFieldStyle(AppTextFieldStyle())
                        }
                        .frame(width: 64)
                        FormRow("ZIP") {
                            TextField("ZIP", text: $mailingZip)
                                .textFieldStyle(AppTextFieldStyle())
                                .keyboardType(.numbersAndPunctuation)
                        }
                        .frame(width: 80)
                    }
                }
                .padding(16)
            }
        }
    }

    private var addressingStyleSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Preferred Addressing Style")
            AppCard {
                VStack(spacing: 0) {
                    ForEach(AddressingStyle.allCases, id: \.self) { style in
                        Button {
                            addressingStyle = style
                        } label: {
                            HStack {
                                Text(style.displayName)
                                    .font(.bodyRegular)
                                    .foregroundStyle(.primaryText)
                                Spacer()
                                if addressingStyle == style {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.accent)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 13)
                        }
                        if style != AddressingStyle.allCases.last {
                            Divider().padding(.leading, 16)
                        }
                    }
                }
            }
        }
    }

    private var anniversarySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Anniversaries") {
                showingAddAnniversary = true
            } actionLabel: "Add"

            if !anniversaries.isEmpty {
                AppCard {
                    VStack(spacing: 0) {
                        ForEach(anniversaries) { ann in
                            HStack {
                                Image(systemName: "heart.fill").foregroundStyle(.accent).frame(width: 28)
                                Text(ann.label).font(.bodyRegular).foregroundStyle(.primaryText)
                                Spacer()
                                Text(ann.date, format: .dateTime.month().day().year())
                                    .font(.captionRegular).foregroundStyle(.secondaryText)
                                Button {
                                    anniversaries.removeAll { $0.id == ann.id }
                                } label: {
                                    Image(systemName: "minus.circle.fill").foregroundStyle(.destructive)
                                }
                            }
                            .padding(.horizontal, 16).padding(.vertical, 12)
                            if ann.id != anniversaries.last?.id { Divider().padding(.leading, 16) }
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddAnniversary) {
            NavigationStack {
                VStack(spacing: 20) {
                    AppCard {
                        VStack(spacing: 12) {
                            FormRow("Label") {
                                TextField("e.g. Wedding Anniversary", text: $newAnnLabel)
                                    .textFieldStyle(AppTextFieldStyle())
                            }
                            DatePicker("Date", selection: $newAnnDate, displayedComponents: .date)
                                .font(.bodyRegular)
                        }
                        .padding(16)
                    }
                    Spacer()
                }
                .padding(.horizontal, 20).padding(.top, 20)
                .navigationTitle("Add Anniversary")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancel") { showingAddAnniversary = false } }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Add") {
                            anniversaries.append(HouseholdAnniversary(label: newAnnLabel, date: newAnnDate))
                            newAnnLabel = ""
                            newAnnDate = Date()
                            showingAddAnniversary = false
                        }
                        .disabled(newAnnLabel.isEmpty)
                    }
                }
            }
            .presentationDetents([.medium])
        }
    }

    private var giftingTagsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Gifting Groups")
            AppCard {
                VStack(alignment: .leading, spacing: 10) {
                    if !giftingTags.isEmpty {
                        FlowLayout(spacing: 8) {
                            ForEach(giftingTags, id: \.self) { tag in
                                TagChip(label: tag, removable: true) {
                                    giftingTags.removeAll { $0 == tag }
                                }
                            }
                        }
                    }
                    HStack {
                        TextField("Add group (e.g. Neighbor Gifts)", text: $giftingTagsText)
                            .textFieldStyle(AppTextFieldStyle())
                        Button {
                            let tag = giftingTagsText.trimmingCharacters(in: .whitespaces)
                            if !tag.isEmpty && !giftingTags.contains(tag) {
                                giftingTags.append(tag)
                            }
                            giftingTagsText = ""
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.accent)
                        }
                        .disabled(giftingTagsText.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }
                .padding(16)
            }
        }
    }

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Notes")
            AppCard {
                TextField("Any notes about this household...", text: $notes, axis: .vertical)
                    .lineLimit(3...6)
                    .font(.bodyRegular)
                    .padding(16)
            }
        }
    }

    private func save() {
        if let existing = household {
            existing.name = name
            existing.addressLine1 = addressLine1
            existing.addressLine2 = addressLine2
            existing.city = city
            existing.state = state
            existing.zip = zip
            existing.country = country
            existing.useCustomMailingAddress = useCustomMailing
            existing.mailingLine1 = mailingLine1
            existing.mailingLine2 = mailingLine2
            existing.mailingCity = mailingCity
            existing.mailingState = mailingState
            existing.mailingZip = mailingZip
            existing.mailingCountry = mailingCountry
            existing.preferredAddressingStyle = addressingStyle
            existing.notes = notes
            existing.giftingTags = giftingTags
            existing.anniversaries = anniversaries
        } else {
            let h = Household(name: name, addressLine1: addressLine1, addressLine2: addressLine2, city: city, state: state, zip: zip, country: country)
            h.useCustomMailingAddress = useCustomMailing
            h.mailingLine1 = mailingLine1
            h.mailingLine2 = mailingLine2
            h.mailingCity = mailingCity
            h.mailingState = mailingState
            h.mailingZip = mailingZip
            h.mailingCountry = mailingCountry
            h.preferredAddressingStyle = addressingStyle
            h.notes = notes
            h.giftingTags = giftingTags
            h.anniversaries = anniversaries
            modelContext.insert(h)
        }
        dismiss()
    }

    private func populateFromExisting() {
        guard let h = household else { return }
        name = h.name
        addressLine1 = h.addressLine1
        addressLine2 = h.addressLine2
        city = h.city
        state = h.state
        zip = h.zip
        country = h.country
        useCustomMailing = h.useCustomMailingAddress
        mailingLine1 = h.mailingLine1
        mailingLine2 = h.mailingLine2
        mailingCity = h.mailingCity
        mailingState = h.mailingState
        mailingZip = h.mailingZip
        mailingCountry = h.mailingCountry
        addressingStyle = h.preferredAddressingStyle
        notes = h.notes
        giftingTags = h.giftingTags
        anniversaries = h.anniversaries
    }
}
