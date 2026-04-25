import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }

            HouseholdsListView()
                .tabItem {
                    Label("Households", systemImage: "person.2.fill")
                }

            GroupsListView()
                .tabItem {
                    Label("Groups", systemImage: "tag.fill")
                }

            EventsListView()
                .tabItem {
                    Label("Events", systemImage: "calendar")
                }

            GiftingDashboardView()
                .tabItem {
                    Label("Gifting", systemImage: "gift.fill")
                }
        }
        .tint(.accent)
    }
}
