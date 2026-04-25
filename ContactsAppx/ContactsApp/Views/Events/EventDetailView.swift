import SwiftUI
import SwiftData

struct EventDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Household.name) private var allHouseholds: [Household]
    @Bindable var event: Event
    @State private var showingEdit = false
    @State private var showingAddGuests = false

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 24) {
                    headerCard
                    rsvpSummaryCard
                    guestListSection
                    if !event.notes.isEmpty { notesSection }
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20).padding(.top, 8)
            }
        }
        .navigationTitle(event.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button { showingAddGuests = true } label: {
                    Image(systemName: "person.badge.plus")
                }
                Button("Edit") { showingEdit = true }
            }
        }
        .sheet(isPresented: $showingEdit) { EventFormView(event: event) }
        .sheet(isPresented: $showingAddGuests) { AddGuestsSheet(event: event) }
    }

    private var headerCard: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color.accent.opacity(0.12)).frame(width: 56, height: 56)
                        Image(systemName: event.eventType.icon)
                            .font(.system(size: 22)).foregroundStyle(.accent)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text(event.name).font(.titleMedium).foregroundStyle(.primaryText)
                        Text(event.eventType.rawValue).font(.captionMedium).foregroundStyle(.secondaryText)
                    }
                    Spacer()
                    if event.isAdultsOnly {
                        Label("Adults Only", systemImage: "wineglass.fill")
                            .font(.captionMedium).foregroundStyle(.accent)
                            .padding(.horizontal, 8).padding(.vertical, 4)
                            .background(Color.accent.opacity(0.1)).clipShape(Capsule())
                    }
                }

                Divider()

                HStack(spacing: 20) {
                    Label(event.date.formatted(.dateTime.weekday().month().day().year()), systemImage: "calendar")
                    if !event.location.isEmpty {
                        Label(event.location, systemImage: "mappin")
                    }
                }
                .font(.captionRegular).foregroundStyle(.secondaryText)
            }
            .padding(20)
        }
    }

    private var rsvpSummaryCard: some View {
        AppCard {
            HStack(spacing: 0) {
                rsvpStat(count: event.attendingCount, label: "Attending", color: .success)
                Divider().frame(height: 40)
                rsvpStat(count: event.maybeCount, label: "Maybe", color: .warning)
                Divider().frame(height: 40)
                rsvpStat(count: event.declinedCount, label: "Declined", color: .destructive)
                Divider().frame(height: 40)
                rsvpStat(count: event.noResponseCount, label: "Pending", color: .secondaryText)
            }
            .padding(.vertical, 16)
        }
    }

    private func rsvpStat(count: Int, label: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text("\(count)").font(.titleMedium).foregroundStyle(color)
            Text(label).font(.captionRegular).foregroundStyle(.secondaryText)
        }
        .frame(maxWidth: .infinity)
    }

    private var guestListSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Guest List (\(event.invitations.count))", action: { showingAddGuests = true }, actionLabel: "Add")

            AppCard {
                if event.invitations.isEmpty {
                    EmptyStateView(icon: "person.2.fill", title: "No guests yet", subtitle: "Tap Add to invite households or people")
                } else {
                    VStack(spacing: 0) {
                        ForEach(event.invitations.sorted { $0.displayName < $1.displayName }) { invitation in
                            GuestInvitationRow(invitation: invitation)
                            if invitation.id != event.invitations.last?.id {
                                Divider().padding(.leading, 16)
                            }
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
                Text(event.notes).font(.bodyRegular).foregroundStyle(.primaryText)
                    .padding(16).frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

struct GuestInvitationRow: View {
    @Bindable var invitation: GuestInvitation

    var body: some View {
        HStack(spacing: 12) {
            if let person = invitation.person {
                PersonAvatar(initials: person.initials, size: 38)
                VStack(alignment: .leading, spacing: 2) {
                    Text(person.fullName).font(.bodyMedium).foregroundStyle(.primaryText)
                    Text(person.household?.name ?? "").font(.captionRegular).foregroundStyle(.secondaryText)
                }
            } else if let household = invitation.household {
                HouseholdAvatar(name: household.name, size: 38)
                VStack(alignment: .leading, spacing: 2) {
                    Text(household.name).font(.bodyMedium).foregroundStyle(.primaryText)
                    Text("\(household.adults.count) adults\(household.children.isEmpty ? "" : " · \(household.children.count) children")")
                        .font(.captionRegular).foregroundStyle(.secondaryText)
                }
            }
            Spacer()
            Menu {
                ForEach(RSVPStatus.allCases, id: \.self) { status in
                    Button(status.rawValue) { invitation.rsvpStatus = status }
                }
            } label: {
                RSVPBadge(status: invitation.rsvpStatus)
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
    }
}

struct AddGuestsSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Household.name) private var households: [Household]
    @Query(sort: \ContactGroup.name) private var groups: [ContactGroup]
    @Bindable var event: Event

    @State private var mode: GuestMode = .household
    @State private var selectedHouseholds: Set<UUID> = []
    @State private var adultsOnly = false

    enum GuestMode: String, CaseIterable {
        case household = "Households"
        case group = "Groups"
    }

    private var alreadyInvitedHouseholdIDs: Set<UUID> {
        Set(event.invitations.compactMap { $0.household?.id })
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                VStack(spacing: 0) {
                    Picker("Mode", selection: $mode) {
                        ForEach(GuestMode.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented).padding(16)

                    Toggle("Adults only invitation", isOn: $adultsOnly)
                        .font(.bodyRegular).tint(.accent)
                        .padding(.horizontal, 20).padding(.bottom, 12)

                    ScrollView {
                        LazyVStack(spacing: 8) {
                            if mode == .household {
                                ForEach(households) { h in
                                    let isInvited = alreadyInvitedHouseholdIDs.contains(h.id)
                                    let isSelected = selectedHouseholds.contains(h.id)
                                    Button {
                                        if isInvited { return }
                                        if isSelected { selectedHouseholds.remove(h.id) }
                                        else { selectedHouseholds.insert(h.id) }
                                    } label: {
                                        AppCard {
                                            HStack(spacing: 12) {
                                                HouseholdAvatar(name: h.name, size: 42)
                                                VStack(alignment: .leading, spacing: 2) {
                                                    Text(h.name).font(.bodyMedium).foregroundStyle(.primaryText)
                                                    Text(memberSummary(h)).font(.captionRegular).foregroundStyle(.secondaryText)
                                                }
                                                Spacer()
                                                if isInvited {
                                                    Label("Added", systemImage: "checkmark.circle.fill")
                                                        .font(.captionMedium).foregroundStyle(.secondaryText)
                                                } else {
                                                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                                        .foregroundStyle(isSelected ? .accent : .tertiaryText)
                                                }
                                            }
                                            .padding(14)
                                        }
                                    }
                                    .buttonStyle(.plain)
                                    .disabled(isInvited)
                                    .padding(.horizontal, 20)
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
            .navigationTitle("Add Guests")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add \(selectedHouseholds.count > 0 ? "(\(selectedHouseholds.count))" : "")") {
                        addGuests()
                    }
                    .fontWeight(.semibold)
                    .disabled(selectedHouseholds.isEmpty)
                }
            }
        }
    }

    private func memberSummary(_ h: Household) -> String {
        let adults = h.adults.count
        let children = h.children.count
        var parts: [String] = []
        if adults > 0 { parts.append("\(adults) adult\(adults == 1 ? "" : "s")") }
        if children > 0 { parts.append("\(children) child\(children == 1 ? "" : "ren")") }
        return parts.joined(separator: " · ")
    }

    private func addGuests() {
        for household in households where selectedHouseholds.contains(household.id) {
            let invitation = GuestInvitation(household: household, adultsOnly: adultsOnly)
            invitation.event = event
            modelContext.insert(invitation)
        }
        dismiss()
    }
}

struct EventFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    var event: Event?

    @State private var name = ""
    @State private var date = Date()
    @State private var hasEndDate = false
    @State private var endDate = Date().addingTimeInterval(7200)
    @State private var location = ""
    @State private var eventType: EventType = .casual
    @State private var isAdultsOnly = false
    @State private var notes = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        AppCard {
                            VStack(spacing: 12) {
                                FormRow("Event Name") {
                                    TextField("What's the occasion?", text: $name)
                                        .textFieldStyle(AppTextFieldStyle())
                                }
                                Picker("Type", selection: $eventType) {
                                    ForEach(EventType.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                                }
                                .pickerStyle(.menu).font(.bodyRegular)
                            }
                            .padding(16)
                        }

                        AppCard {
                            VStack(spacing: 12) {
                                DatePicker("Date & Time", selection: $date).font(.bodyRegular)
                                Toggle("End time", isOn: $hasEndDate).font(.bodyRegular).tint(.accent)
                                if hasEndDate { DatePicker("End", selection: $endDate).font(.bodyRegular) }
                                FormRow("Location") {
                                    TextField("Where?", text: $location)
                                        .textFieldStyle(AppTextFieldStyle())
                                }
                                Toggle("Adults only", isOn: $isAdultsOnly).font(.bodyRegular).tint(.accent)
                            }
                            .padding(16)
                        }

                        AppCard {
                            TextField("Notes...", text: $notes, axis: .vertical)
                                .lineLimit(2...6).font(.bodyRegular).padding(16)
                        }
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20).padding(.top, 20)
                }
            }
            .navigationTitle(event == nil ? "New Event" : "Edit Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button(event == nil ? "Create" : "Save") { save() }
                        .fontWeight(.semibold)
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                guard let e = event else { return }
                name = e.name; date = e.date
                if let end = e.endDate { hasEndDate = true; endDate = end }
                location = e.location; eventType = e.eventType; isAdultsOnly = e.isAdultsOnly; notes = e.notes
            }
        }
    }

    private func save() {
        if let existing = event {
            existing.name = name; existing.date = date; existing.endDate = hasEndDate ? endDate : nil
            existing.location = location; existing.eventType = eventType; existing.isAdultsOnly = isAdultsOnly; existing.notes = notes
        } else {
            let e = Event(name: name, date: date, eventType: eventType)
            e.endDate = hasEndDate ? endDate : nil; e.location = location
            e.isAdultsOnly = isAdultsOnly; e.notes = notes
            modelContext.insert(e)
        }
        dismiss()
    }
}
