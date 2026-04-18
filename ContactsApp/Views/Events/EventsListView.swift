import SwiftUI
import SwiftData

struct EventsListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Event.date) private var events: [Event]
    @State private var showingAddEvent = false
    @State private var showPast = false

    private var upcoming: [Event] { events.filter { !$0.isPast } }
    private var past: [Event] { events.filter { $0.isPast }.reversed() }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                if events.isEmpty {
                    EmptyStateView(icon: "calendar", title: "No events yet", subtitle: "Plan a dinner, party, or gathering")
                } else {
                    ScrollView {
                        VStack(spacing: 24) {
                            if !upcoming.isEmpty {
                                section(title: "Upcoming", events: upcoming)
                            }
                            if !past.isEmpty {
                                VStack(alignment: .leading, spacing: 10) {
                                    Button {
                                        withAnimation { showPast.toggle() }
                                    } label: {
                                        HStack {
                                            SectionHeader(title: "Past Events (\(past.count))")
                                            Image(systemName: showPast ? "chevron.up" : "chevron.down")
                                                .font(.captionMedium).foregroundStyle(.secondaryText)
                                        }
                                    }
                                    if showPast {
                                        ForEach(past.prefix(10)) { event in
                                            NavigationLink(destination: EventDetailView(event: event)) {
                                                EventRow(event: event)
                                            }.buttonStyle(.plain)
                                        }
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                            Spacer(minLength: 40)
                        }
                        .padding(.top, 16)
                    }
                }
            }
            .navigationTitle("Events")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showingAddEvent = true } label: {
                        Image(systemName: "plus").fontWeight(.semibold)
                    }
                }
            }
            .sheet(isPresented: $showingAddEvent) {
                EventFormView()
            }
        }
    }

    private func section(title: String, events: [Event]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: title).padding(.horizontal, 20)
            ForEach(events) { event in
                NavigationLink(destination: EventDetailView(event: event)) {
                    EventRow(event: event)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 20)
            }
        }
    }
}

struct EventRow: View {
    let event: Event

    var body: some View {
        AppCard {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.accent.opacity(0.12))
                        .frame(width: 50, height: 50)
                    Image(systemName: event.eventType.icon)
                        .font(.system(size: 20))
                        .foregroundStyle(.accent)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(event.name).font(.titleSmall).foregroundStyle(.primaryText)
                    Text(event.date, format: .dateTime.weekday(.wide).month().day())
                        .font(.captionRegular).foregroundStyle(.secondaryText)
                    if !event.location.isEmpty {
                        Label(event.location, systemImage: "mappin")
                            .font(.captionRegular).foregroundStyle(.tertiaryText)
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(event.invitations.count)")
                        .font(.titleSmall).foregroundStyle(.accent)
                    Text("invited").font(.captionRegular).foregroundStyle(.tertiaryText)
                }
            }
            .padding(16)
        }
    }
}
