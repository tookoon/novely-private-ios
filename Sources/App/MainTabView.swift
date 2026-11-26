import SwiftUI

struct MainTabView: View {
    @EnvironmentObject private var store: LibraryStore
    @State private var selectedTab: Int = 0
    @State private var activeSessionBook: Book?

    var body: some View {
        TabView(selection: $selectedTab) {
            BookshelfView(onStartReadingBook: { book in
                activeSessionBook = book
                selectedTab = 2
            })
            .tabItem {
                Label("Regal", systemImage: "books.vertical.fill")
            }
            .tag(0)

            ProgressAndQuotesView(onStartReadingBook: { book in
                activeSessionBook = book
                selectedTab = 2
            })
            .tabItem {
                Label("Lesen", systemImage: "book.pages.fill")
            }
            .tag(1)

            ReadingRoomView(externalBook: $activeSessionBook)
                .tabItem {
                    Label("Lesezeit", systemImage: "flame.fill")
                }
                .tag(2)

            StatisticsView()
                .tabItem {
                    Label("Statistik", systemImage: "calendar")
                }
                .tag(3)

            DiscoverAndSettingsView()
                .tabItem {
                    Label("Mehr", systemImage: "sparkles")
                }
                .tag(4)
        }
        .tint(NovelyTheme.terracotta)
        .fullScreenCover(isPresented: Binding(
            get: { !store.settings.hasCompletedOnboarding },
            set: { _ in }
        )) {
            OnboardingWelcomeView()
                .environmentObject(store)
        }
    }
}

// MARK: - Clean Onboarding (Empty Shelf vs Demo Shelf)

struct OnboardingWelcomeView: View {
    @EnvironmentObject private var store: LibraryStore
    @State private var ownerName = ""

    var body: some View {
        ZStack {
            BookshelfCabinetBackdrop(settings: store.settings)

            VStack(spacing: 22) {
                Spacer()

                Image("DecorSleepingCat")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 150, height: 100)
                    .shadow(color: .black.opacity(0.5), radius: 10, y: 5)

                VStack(spacing: 8) {
                    Text("Dein virtuelles Bücherregal")
                        .font(.system(size: 30, weight: .bold, design: .serif))
                        .foregroundStyle(NovelyTheme.creamText)
                        .multilineTextAlignment(.center)

                    Text("Scanne deine echten Bücher, richte dein Regal mit Katze, Pflanze & Lichterkette ein und sammle deine Lesezeit – 100 % privat & kostenlos.")
                        .font(.system(size: 15))
                        .foregroundStyle(NovelyTheme.creamText.opacity(0.85))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 12)
                }

                TextField("Dein Name (z. B. Gizem)", text: $ownerName)
                    .padding(14)
                    .background(Color.black.opacity(0.35), in: RoundedRectangle(cornerRadius: 16))
                    .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(.white.opacity(0.2)))
                    .foregroundStyle(NovelyTheme.creamText)
                    .padding(.horizontal, 28)

                Spacer()

                VStack(spacing: 12) {
                    Button {
                        if !ownerName.trimmingCharacters(in: .whitespaces).isEmpty {
                            store.settings.ownerName = ownerName.trimmingCharacters(in: .whitespaces)
                        }
                        store.startWithEmptyShelf()
                    } label: {
                        Text("Leer starten & eigene Bücher scannen")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(NovelyTheme.creamText, in: Capsule())
                    }

                    Button {
                        if !ownerName.trimmingCharacters(in: .whitespaces).isEmpty {
                            store.settings.ownerName = ownerName.trimmingCharacters(in: .whitespaces)
                        }
                        store.loadDemoLibrary(markOnboarded: true)
                        Task { await store.hydrateRealCoversIfNeeded() }
                    } label: {
                        Text("Erstmal Demo-Regal ansehen")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(NovelyTheme.creamText)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .novelyGlassCapsule()
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 34)
            }
        }
    }
}
