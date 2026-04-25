import SwiftUI
import SwiftData

@main
struct ContactsAppApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [
            Household.self,
            Person.self,
            ContactGroup.self,
            Event.self,
            GuestInvitation.self,
            Occasion.self,
            GiftIdea.self,
            GiftHistory.self,
        ])
    }
}
