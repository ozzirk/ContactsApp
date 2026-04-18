import SwiftUI
import SwiftData

struct GroupsListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ContactGroup.name) private var groups: [ContactGroup]
    @Query private var households: [Household]

    @State private var showingAddGroup = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                if groups.isEmpty {
                    EmptyStateView(
                        icon: "person.2.fill",
                        title: "No groups yet",
                        subtitle: "Create groups for holiday cards, events, and gifting"
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(groups) { group in
                                NavigationLink(destination: GroupDetailView(group: group)) {
                                    GroupRow(group: group, allHouseholds: households)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                    }
                }
            }
            .navigationTitle("Groups")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showingAddGroup = true } label: {
                        Image(systemName: "plus").fontWeight(.semibold)
                    }
                }
            }
            .sheet(isPresented: $showingAddGroup) {
                GroupFormView()
            }
        }
    }
}

struct GroupRow: View {
    let group: ContactGroup
    let allHouseholds: [Household]

    var body: some View {
        AppCard {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.groupColor(group.colorName).opacity(0.18))
                        .frame(width: 50, height: 50)
                    Image(systemName: group.icon)
                        .font(.system(size: 20))
                        .foregroundStyle(Color.groupColor(group.colorName))
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(group.name)
                        .font(.titleSmall)
                        .foregroundStyle(.primaryText)
                    HStack(spacing: 6) {
                        Text("\(group.resolvedPersons(allHouseholds: allHouseholds).count) people")
                            .font(.captionRegular)
                            .foregroundStyle(.secondaryText)
                        if group.groupType == .dynamic {
                            Label("Dynamic", systemImage: "wand.and.stars")
                                .font(.captionMedium)
                                .foregroundStyle(.accent)
                        }
                    }
                }
                Spacer()
                Image(systemName: "chevron.right").font(.captionMedium).foregroundStyle(.tertiaryText)
            }
            .padding(16)
        }
    }
}

struct GroupDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allHouseholds: [Household]
    @Bindable var group: ContactGroup
    @State private var showingEdit = false

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 24) {
                    headerCard
                    membersSection
                    if !group.notes.isEmpty { notesSection }
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20).padding(.top, 8)
            }
        }
        .navigationTitle(group.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .primaryAction) { Button("Edit") { showingEdit = true } }
        }
        .sheet(isPresented: $showingEdit) { GroupFormView(group: group) }
    }

    private var headerCard: some View {
        AppCard {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.groupColor(group.colorName).opacity(0.18))
                        .frame(width: 64, height: 64)
                    Image(systemName: group.icon)
                        .font(.system(size: 26))
                        .foregroundStyle(Color.groupColor(group.colorName))
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(group.name).font(.titleLarge).foregroundStyle(.primaryText)
                    Text("\(group.resolvedPersons(allHouseholds: allHouseholds).count) people · \(group.resolvedHouseholds(allHouseholds: allHouseholds).count) households")
                        .font(.captionRegular).foregroundStyle(.secondaryText)
                    if group.groupType == .dynamic {
                        Label("Dynamic group", systemImage: "wand.and.stars")
                            .font(.captionMedium).foregroundStyle(.accent)
                    }
                }
                Spacer()
            }
            .padding(20)
        }
    }

    private var membersSection: some View {
        let people = group.resolvedPersons(allHouseholds: allHouseholds)
        return VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Members")
            AppCard {
                if people.isEmpty {
                    EmptyStateView(icon: "person.fill", title: "No members", subtitle: "Add households or people to this group")
                } else {
                    VStack(spacing: 0) {
                        ForEach(people) { person in
                            NavigationLink(destination: PersonDetailView(person: person)) {
                                HStack(spacing: 12) {
                                    PersonAvatar(initials: person.initials, size: 38)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(person.fullName).font(.bodyMedium).foregroundStyle(.primaryText)
                                        Text(person.household?.name ?? "").font(.captionRegular).foregroundStyle(.secondaryText)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right").font(.captionMedium).foregroundStyle(.tertiaryText)
                                }
                                .padding(.horizontal, 16).padding(.vertical, 12)
                            }
                            .buttonStyle(.plain)
                            if person.id != people.last?.id { Divider().padding(.leading, 62) }
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
                Text(group.notes).font(.bodyRegular).foregroundStyle(.primaryText)
                    .padding(16).frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

struct GroupFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Household.name) private var allHouseholds: [Household]

    var group: ContactGroup?

    @State private var name = ""
    @State private var groupType: GroupType = .manual
    @State private var color: GroupColor = .sage
    @State private var icon = "person.2.fill"
    @State private var notes = ""
    @State private var selectedRules: Set<DynamicFilterRule> = []
    @State private var selectedHouseholds: Set<UUID> = []

    private let icons = ["person.2.fill", "house.fill", "heart.fill", "gift.fill", "star.fill", "mappin", "graduationcap.fill", "figure.and.child.holdinghands", "envelope.fill", "birthday.cake.fill"]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        AppCard {
                            VStack(spacing: 12) {
                                FormRow("Group Name") {
                                    TextField("e.g. Holiday Cards", text: $name)
                                        .textFieldStyle(AppTextFieldStyle())
                                }
                                Picker("Type", selection: $groupType) {
                                    ForEach(GroupType.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                                }
                                .pickerStyle(.segmented)
                            }
                            .padding(16)
                        }

                        colorSection
                        iconSection

                        if groupType == .dynamic { dynamicRulesSection }
                        if groupType == .manual { householdPickerSection }

                        AppCard {
                            TextField("Notes...", text: $notes, axis: .vertical)
                                .lineLimit(2...5).font(.bodyRegular).padding(16)
                        }
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20).padding(.top, 20)
                }
            }
            .navigationTitle(group == nil ? "New Group" : "Edit Group")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button(group == nil ? "Add" : "Save") { save() }
                        .fontWeight(.semibold)
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear { populate() }
        }
    }

    private var colorSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Color")
            AppCard {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(GroupColor.allCases, id: \.self) { c in
                            Button { color = c } label: {
                                ZStack {
                                    Circle().fill(Color.groupColor(c)).frame(width: 36, height: 36)
                                    if color == c {
                                        Image(systemName: "checkmark").font(.system(size: 14, weight: .bold)).foregroundStyle(.white)
                                    }
                                }
                            }
                        }
                    }
                    .padding(16)
                }
            }
        }
    }

    private var iconSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Icon")
            AppCard {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(icons, id: \.self) { i in
                            Button { icon = i } label: {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .fill(icon == i ? Color.groupColor(color).opacity(0.2) : Color.secondaryText.opacity(0.08))
                                        .frame(width: 44, height: 44)
                                    Image(systemName: i)
                                        .font(.system(size: 18))
                                        .foregroundStyle(icon == i ? Color.groupColor(color) : .secondaryText)
                                }
                            }
                        }
                    }
                    .padding(16)
                }
            }
        }
    }

    private var dynamicRulesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Auto-include when")
            AppCard {
                VStack(spacing: 0) {
                    ForEach(DynamicFilterRule.allCases, id: \.self) { rule in
                        Button {
                            if selectedRules.contains(rule) { selectedRules.remove(rule) }
                            else { selectedRules.insert(rule) }
                        } label: {
                            HStack {
                                Text(rule.rawValue).font(.bodyRegular).foregroundStyle(.primaryText)
                                Spacer()
                                Image(systemName: selectedRules.contains(rule) ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(selectedRules.contains(rule) ? .accent : .tertiaryText)
                            }
                            .padding(.horizontal, 16).padding(.vertical, 13)
                        }
                        if rule != DynamicFilterRule.allCases.last { Divider().padding(.leading, 16) }
                    }
                }
            }
        }
    }

    private var householdPickerSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Households")
            AppCard {
                VStack(spacing: 0) {
                    if allHouseholds.isEmpty {
                        EmptyStateView(icon: "house.fill", title: "No households", subtitle: "Add households first")
                    } else {
                        ForEach(allHouseholds) { h in
                            Button {
                                if selectedHouseholds.contains(h.id) { selectedHouseholds.remove(h.id) }
                                else { selectedHouseholds.insert(h.id) }
                            } label: {
                                HStack(spacing: 12) {
                                    HouseholdAvatar(name: h.name, size: 36)
                                    Text(h.name).font(.bodyRegular).foregroundStyle(.primaryText)
                                    Spacer()
                                    Image(systemName: selectedHouseholds.contains(h.id) ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(selectedHouseholds.contains(h.id) ? .accent : .tertiaryText)
                                }
                                .padding(.horizontal, 16).padding(.vertical, 12)
                            }
                            if h.id != allHouseholds.last?.id { Divider().padding(.leading, 62) }
                        }
                    }
                }
            }
        }
    }

    private func save() {
        if let existing = group {
            existing.name = name
            existing.groupType = groupType
            existing.colorName = color
            existing.icon = icon
            existing.notes = notes
            existing.dynamicRules = Array(selectedRules)
            existing.households = allHouseholds.filter { selectedHouseholds.contains($0.id) }
        } else {
            let g = ContactGroup(name: name, groupType: groupType, color: color, icon: icon)
            g.notes = notes
            g.dynamicRules = Array(selectedRules)
            g.households = allHouseholds.filter { selectedHouseholds.contains($0.id) }
            modelContext.insert(g)
        }
        dismiss()
    }

    private func populate() {
        guard let g = group else { return }
        name = g.name; groupType = g.groupType; color = g.colorName; icon = g.icon; notes = g.notes
        selectedRules = Set(g.dynamicRules)
        selectedHouseholds = Set(g.households.map { $0.id })
    }
}
