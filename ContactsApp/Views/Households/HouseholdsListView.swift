import SwiftUI
import SwiftData

struct HouseholdsListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Household.name) private var households: [Household]

    @State private var searchText = ""
    @State private var showingAddHousehold = false
    @State private var selectedHousehold: Household?

    private var filtered: [Household] {
        guard !searchText.isEmpty else { return households }
        let q = searchText.lowercased()
        return households.filter {
            $0.name.lowercased().contains(q) ||
            $0.city.lowercased().contains(q) ||
            $0.persons.contains { $0.fullName.lowercased().contains(q) }
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                if households.isEmpty {
                    EmptyStateView(
                        icon: "house.fill",
                        title: "No households yet",
                        subtitle: "Add your first household to get started"
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(filtered) { household in
                                NavigationLink(destination: HouseholdDetailView(household: household)) {
                                    HouseholdRow(household: household)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                    }
                }
            }
            .navigationTitle("Households")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, prompt: "Search households or people")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddHousehold = true
                    } label: {
                        Image(systemName: "plus")
                            .fontWeight(.semibold)
                    }
                }
            }
            .sheet(isPresented: $showingAddHousehold) {
                HouseholdFormView()
            }
        }
    }
}

struct HouseholdRow: View {
    let household: Household

    var body: some View {
        AppCard {
            HStack(spacing: 14) {
                HouseholdAvatar(name: household.name, size: 50)

                VStack(alignment: .leading, spacing: 3) {
                    Text(household.name)
                        .font(.titleSmall)
                        .foregroundStyle(.primaryText)

                    if !household.persons.isEmpty {
                        Text(memberSummary)
                            .font(.captionRegular)
                            .foregroundStyle(.secondaryText)
                    }

                    if !household.city.isEmpty {
                        Label(household.city + (household.state.isEmpty ? "" : ", \(household.state)"), systemImage: "mappin")
                            .font(.captionRegular)
                            .foregroundStyle(.tertiaryText)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.captionMedium)
                    .foregroundStyle(.tertiaryText)
            }
            .padding(16)
        }
    }

    private var memberSummary: String {
        let adults = household.adults.count
        let children = household.children.count
        var parts: [String] = []
        if adults > 0 { parts.append("\(adults) adult\(adults == 1 ? "" : "s")") }
        if children > 0 { parts.append("\(children) child\(children == 1 ? "" : "ren")") }
        return parts.joined(separator: " · ")
    }
}
