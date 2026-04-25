import SwiftUI
import SwiftData

struct GiftIdeaFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var person: Person?
    var household: Household?
    var occasion: Occasion?
    var existingIdea: GiftIdea?

    @State private var title = ""
    @State private var link = ""
    @State private var priceText = ""
    @State private var status: GiftStatus = .idea
    @State private var notes = ""

    private var isEditing: Bool { existingIdea != nil }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
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

                        VStack(alignment: .leading, spacing: 10) {
                            SectionHeader(title: "Notes")
                            AppCard {
                                TextField("Any notes...", text: $notes, axis: .vertical)
                                    .lineLimit(2...5)
                                    .font(.bodyRegular)
                                    .padding(16)
                            }
                        }
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20).padding(.top, 20)
                }
            }
            .navigationTitle(isEditing ? "Edit Gift Idea" : "New Gift Idea")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Save" : "Add") { save() }
                        .fontWeight(.semibold)
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                guard let e = existingIdea else { return }
                title = e.title
                link = e.link
                priceText = e.priceEstimate.map { String(format: "%.0f", $0) } ?? ""
                status = e.status
                notes = e.notes
            }
        }
    }

    private func save() {
        let price = Double(priceText.filter { $0.isNumber || $0 == "." })
        if let existing = existingIdea {
            existing.title = title
            existing.link = link
            existing.priceEstimate = price
            existing.status = status
            existing.notes = notes
        } else {
            let idea = GiftIdea(title: title)
            idea.link = link
            idea.priceEstimate = price
            idea.status = status
            idea.notes = notes
            idea.person = person
            idea.household = household
            idea.occasion = occasion
            modelContext.insert(idea)
        }
        dismiss()
    }
}

struct GiftHistoryFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var person: Person?
    var household: Household?

    @State private var giftGiven = ""
    @State private var amountText = ""
    @State private var occasionType = ""
    @State private var year = Calendar.current.component(.year, from: Date())
    @State private var reaction = ""
    @State private var historyNotes = ""
    @State private var doNotRepeat = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        AppCard {
                            VStack(spacing: 12) {
                                FormRow("Gift Given") {
                                    TextField("What was gifted?", text: $giftGiven)
                                        .textFieldStyle(AppTextFieldStyle())
                                }
                                HStack(spacing: 12) {
                                    FormRow("Amount Spent") {
                                        TextField("$0", text: $amountText)
                                            .textFieldStyle(AppTextFieldStyle())
                                            .keyboardType(.decimalPad)
                                    }
                                    FormRow("Occasion") {
                                        TextField("e.g. Birthday", text: $occasionType)
                                            .textFieldStyle(AppTextFieldStyle())
                                    }
                                }
                                Stepper("Year: \(year)", value: $year, in: 2000...Calendar.current.component(.year, from: Date()))
                                    .font(.bodyRegular)
                            }
                            .padding(16)
                        }

                        AppCard {
                            VStack(spacing: 12) {
                                FormRow("Their Reaction") {
                                    TextField("How did they react?", text: $reaction)
                                        .textFieldStyle(AppTextFieldStyle())
                                }
                                Toggle("Do not repeat this gift", isOn: $doNotRepeat)
                                    .font(.bodyRegular).tint(.destructive)
                                FormRow("Notes") {
                                    TextField("Any notes...", text: $historyNotes, axis: .vertical)
                                        .lineLimit(2...4)
                                        .textFieldStyle(AppTextFieldStyle())
                                }
                            }
                            .padding(16)
                        }
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20).padding(.top, 20)
                }
            }
            .navigationTitle("Log Gift")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                        .disabled(giftGiven.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func save() {
        let entry = GiftHistory(giftGiven: giftGiven, occasionType: occasionType, year: year)
        entry.amount = Double(amountText.filter { $0.isNumber || $0 == "." })
        entry.recipientReaction = reaction
        entry.historyNotes = historyNotes
        entry.doNotRepeat = doNotRepeat
        entry.person = person
        entry.household = household
        modelContext.insert(entry)
        dismiss()
    }
}
