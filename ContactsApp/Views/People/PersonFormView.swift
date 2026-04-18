import SwiftUI
import SwiftData

struct PersonFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var person: Person?
    var household: Household?

    @State private var firstName = ""
    @State private var lastName = ""
    @State private var role: PersonRole = .adult
    @State private var phone = ""
    @State private var email = ""
    @State private var hasBirthday = false
    @State private var birthday = Date()
    @State private var relationshipType: RelationshipType = .friend
    @State private var tagsText = ""
    @State private var tags: [String] = []
    @State private var interestsText = ""
    @State private var interests: [String] = []
    @State private var allergiesText = ""
    @State private var allergies: [String] = []
    @State private var giftPreference: GiftPreference = .open
    @State private var notes = ""

    private var isEditing: Bool { person != nil }
    private var isValid: Bool { !firstName.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        identitySection
                        contactSection
                        birthdaySection
                        tagsSection
                        interestsSection
                        allergiesSection
                        giftPreferenceSection
                        notesSection
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }
            .navigationTitle(isEditing ? "Edit Person" : "New Person")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Save" : "Add") { save() }
                        .fontWeight(.semibold)
                        .disabled(!isValid)
                }
            }
            .onAppear { populateFromExisting() }
        }
    }

    private var identitySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Identity")
            AppCard {
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        FormRow("First Name") {
                            TextField("First", text: $firstName)
                                .textFieldStyle(AppTextFieldStyle())
                        }
                        FormRow("Last Name") {
                            TextField("Last", text: $lastName)
                                .textFieldStyle(AppTextFieldStyle())
                        }
                    }

                    Picker("Role", selection: $role) {
                        ForEach(PersonRole.allCases, id: \.self) { r in
                            Text(r.rawValue).tag(r)
                        }
                    }
                    .pickerStyle(.segmented)

                    Picker("Relationship", selection: $relationshipType) {
                        ForEach(RelationshipType.allCases, id: \.self) { r in
                            Text(r.rawValue).tag(r)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .font(.bodyRegular)
                }
                .padding(16)
            }
        }
    }

    private var contactSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Contact")
            AppCard {
                VStack(spacing: 12) {
                    FormRow("Phone") {
                        TextField("Phone number", text: $phone)
                            .textFieldStyle(AppTextFieldStyle())
                            .keyboardType(.phonePad)
                    }
                    FormRow("Email") {
                        TextField("Email address", text: $email)
                            .textFieldStyle(AppTextFieldStyle())
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                    }
                }
                .padding(16)
            }
        }
    }

    private var birthdaySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Birthday")
            AppCard {
                VStack(spacing: 12) {
                    Toggle("Add birthday", isOn: $hasBirthday).tint(.accent).font(.bodyRegular)
                    if hasBirthday {
                        DatePicker("Birthday", selection: $birthday, displayedComponents: .date)
                            .font(.bodyRegular)
                    }
                }
                .padding(16)
            }
        }
    }

    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Tags")
            AppCard {
                VStack(alignment: .leading, spacing: 10) {
                    if !tags.isEmpty {
                        FlowLayout(spacing: 6) {
                            ForEach(tags, id: \.self) { tag in
                                TagChip(label: tag, removable: true) { tags.removeAll { $0 == tag } }
                            }
                        }
                    }
                    chipInput(placeholder: "Add tag (e.g. close friends)", text: $tagsText) {
                        addToList(text: &tagsText, list: &tags)
                    }
                }
                .padding(16)
            }
        }
    }

    private var interestsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Interests")
            AppCard {
                VStack(alignment: .leading, spacing: 10) {
                    if !interests.isEmpty {
                        FlowLayout(spacing: 6) {
                            ForEach(interests, id: \.self) { interest in
                                TagChip(label: interest, removable: true) { interests.removeAll { $0 == interest } }
                            }
                        }
                    }
                    chipInput(placeholder: "Add interest (e.g. gardening, tennis)", text: $interestsText) {
                        addToList(text: &interestsText, list: &interests)
                    }
                }
                .padding(16)
            }
        }
    }

    private var allergiesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Allergies & Dietary")
            AppCard {
                VStack(alignment: .leading, spacing: 10) {
                    if !allergies.isEmpty {
                        FlowLayout(spacing: 6) {
                            ForEach(allergies, id: \.self) { a in
                                TagChip(label: a, removable: true) { allergies.removeAll { $0 == a } }
                            }
                        }
                    }
                    chipInput(placeholder: "Add restriction (e.g. nut allergy, gluten free)", text: $allergiesText) {
                        addToList(text: &allergiesText, list: &allergies)
                    }
                }
                .padding(16)
            }
        }
    }

    private var giftPreferenceSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Gift Preference")
            AppCard {
                VStack(spacing: 0) {
                    ForEach(GiftPreference.allCases, id: \.self) { pref in
                        Button { giftPreference = pref } label: {
                            HStack {
                                Text(pref.displayName).font(.bodyRegular).foregroundStyle(.primaryText)
                                Spacer()
                                if giftPreference == pref {
                                    Image(systemName: "checkmark.circle.fill").foregroundStyle(.accent)
                                }
                            }
                            .padding(.horizontal, 16).padding(.vertical, 13)
                        }
                        if pref != GiftPreference.allCases.last { Divider().padding(.leading, 16) }
                    }
                }
            }
        }
    }

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Notes")
            AppCard {
                TextField("Notes about this person...", text: $notes, axis: .vertical)
                    .lineLimit(3...6)
                    .font(.bodyRegular)
                    .padding(16)
            }
        }
    }

    @ViewBuilder
    private func chipInput(placeholder: String, text: Binding<String>, onAdd: @escaping () -> Void) -> some View {
        HStack {
            TextField(placeholder, text: text)
                .textFieldStyle(AppTextFieldStyle())
                .onSubmit { onAdd() }
            Button(action: onAdd) {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.accent)
            }
            .disabled(text.wrappedValue.trimmingCharacters(in: .whitespaces).isEmpty)
        }
    }

    private func addToList(text: inout String, list: inout [String]) {
        let value = text.trimmingCharacters(in: .whitespaces)
        if !value.isEmpty && !list.contains(value) { list.append(value) }
        text = ""
    }

    private func save() {
        if let existing = person {
            existing.firstName = firstName
            existing.lastName = lastName
            existing.role = role
            existing.phone = phone
            existing.email = email
            existing.birthday = hasBirthday ? birthday : nil
            existing.relationshipType = relationshipType
            existing.tags = tags
            existing.interests = interests
            existing.allergies = allergies
            existing.giftPreference = giftPreference
            existing.notes = notes
        } else {
            let p = Person(firstName: firstName, lastName: lastName, role: role)
            p.phone = phone
            p.email = email
            p.birthday = hasBirthday ? birthday : nil
            p.relationshipType = relationshipType
            p.tags = tags
            p.interests = interests
            p.allergies = allergies
            p.giftPreference = giftPreference
            p.notes = notes
            p.household = household
            modelContext.insert(p)
        }
        dismiss()
    }

    private func populateFromExisting() {
        guard let p = person else { return }
        firstName = p.firstName
        lastName = p.lastName
        role = p.role
        phone = p.phone
        email = p.email
        if let bday = p.birthday { hasBirthday = true; birthday = bday }
        relationshipType = p.relationshipType
        tags = p.tags
        interests = p.interests
        allergies = p.allergies
        giftPreference = p.giftPreference
        notes = p.notes
    }
}
