import SwiftUI
import UniformTypeIdentifiers

// MARK: - Online Book Search Result (Open Library API)

struct OnlineBookResult: Identifiable {
    let id = UUID()
    let title: String
    let author: String
    let isbn: String
    let pageCount: Int
    let publisher: String
}

// MARK: - Add Book Sheet (Search, ISBN Scanner, Manual)

struct AddBookSheet: View {
    @EnvironmentObject private var store: LibraryStore
    @Environment(\.dismiss) private var dismiss

    let defaultShelf: ShelfCategory

    @State private var searchQuery = ""
    @State private var isSearching = false
    @State private var searchResults: [OnlineBookResult] = []
    @State private var showingISBNScanner = false

    // Manual form
    @State private var title = ""
    @State private var author = ""
    @State private var pagesText = "360"
    @State private var priceText = "18.00"
    @State private var shelf: ShelfCategory
    @State private var selectedColorHex = "#263B4D"

    private let colorChoices = ["#1E1A18", "#8C2622", "#142738", "#B57B3C", "#263B4D", "#174B3E", "#C24658", "#D4A73B"]

    init(defaultShelf: ShelfCategory) {
        self.defaultShelf = defaultShelf
        _shelf = State(initialValue: defaultShelf)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                NovelyTheme.espressoBg.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Online Search + Barcode Scan
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Buch suchen oder ISBN scannen")
                                .font(.system(size: 16, weight: .semibold, design: .serif))
                                .foregroundStyle(NovelyTheme.creamText)

                            HStack(spacing: 8) {
                                TextField("Titel, Autor oder ISBN...", text: $searchQuery)
                                    .textFieldStyle(.plain)
                                    .padding(12)
                                    .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
                                    .onSubmit { performSearch() }

                                Button {
                                    performSearch()
                                } label: {
                                    Image(systemName: "magnifyingglass")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundStyle(.black)
                                        .padding(12)
                                        .background(NovelyTheme.creamText, in: RoundedRectangle(cornerRadius: 14))
                                }

                                Button {
                                    showingISBNScanner = true
                                } label: {
                                    Image(systemName: "barcode.viewfinder")
                                        .font(.system(size: 18))
                                        .foregroundStyle(NovelyTheme.warmGold)
                                        .padding(11)
                                        .novelyGlassCard(cornerRadius: 14)
                                }
                            }

                            if isSearching {
                                HStack {
                                    ProgressView().tint(NovelyTheme.warmGold)
                                    Text("Suche im Katalog...")
                                        .font(.system(size: 13))
                                        .foregroundStyle(NovelyTheme.warmMutedText)
                                }
                                .padding(.top, 4)
                            }

                            ForEach(searchResults) { item in
                                HStack {
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(item.title)
                                            .font(.system(size: 15, weight: .semibold, design: .serif))
                                            .foregroundStyle(NovelyTheme.creamText)
                                        Text("\(item.author) · \(item.pageCount) S.")
                                            .font(.system(size: 12))
                                            .foregroundStyle(NovelyTheme.warmMutedText)
                                    }
                                    Spacer()
                                    Button("Hinzufügen") {
                                        let book = Book(
                                            title: item.title,
                                            author: item.author,
                                            isbn: item.isbn,
                                            publisher: item.publisher,
                                            pageCount: item.pageCount,
                                            currentPage: shelf == .read ? item.pageCount : 0,
                                            shelf: shelf,
                                            spineColorHex: colorChoices.randomElement() ?? "#263B4D",
                                            purchasePrice: 18.0
                                        )
                                        store.addBook(book)
                                        dismiss()
                                    }
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(.black)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 7)
                                    .background(NovelyTheme.creamText, in: Capsule())
                                }
                                .padding(12)
                                .novelyGlassCard(cornerRadius: 14)
                            }
                        }

                        Divider().background(Color.white.opacity(0.12))

                        // Manual Creation
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Oder manuell anlegen")
                                .font(.system(size: 16, weight: .semibold, design: .serif))
                                .foregroundStyle(NovelyTheme.creamText)

                            TextField("Buchtitel", text: $title)
                                .padding(12)
                                .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
                            TextField("Autor:in", text: $author)
                                .padding(12)
                                .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))

                            HStack(spacing: 12) {
                                TextField("Seiten", text: $pagesText)
                                    .keyboardType(.numberPad)
                                    .padding(12)
                                    .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
                                TextField("Preis (€)", text: $priceText)
                                    .keyboardType(.decimalPad)
                                    .padding(12)
                                    .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
                            }

                            Picker("Regal", selection: $shelf) {
                                ForEach(ShelfCategory.allCases) { cat in
                                    Text(cat.rawValue).tag(cat)
                                }
                            }
                            .pickerStyle(.segmented)

                            HStack(spacing: 10) {
                                ForEach(colorChoices, id: \.self) { hex in
                                    Circle()
                                        .fill(Color(hex: hex))
                                        .frame(width: 28, height: 28)
                                        .overlay(
                                            Circle().strokeBorder(selectedColorHex == hex ? NovelyTheme.warmGold : .clear, lineWidth: 2)
                                        )
                                        .onTapGesture { selectedColorHex = hex }
                                }
                            }

                            Button {
                                guard !title.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                                let pages = Int(pagesText) ?? 320
                                let price = Double(priceText.replacingOccurrences(of: ",", with: ".")) ?? 18.0
                                let newBook = Book(
                                    title: title,
                                    author: author.isEmpty ? "Unbekannt" : author,
                                    pageCount: max(20, pages),
                                    currentPage: shelf == .read ? max(20, pages) : 0,
                                    shelf: shelf,
                                    spineColorHex: selectedColorHex,
                                    purchasePrice: price
                                )
                                store.addBook(newBook)
                                dismiss()
                            } label: {
                                Text("Ins Regal stellen")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(.black)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(NovelyTheme.creamText, in: Capsule())
                            }
                            .padding(.top, 6)
                        }
                    }
                    .padding(18)
                }
            }
            .navigationTitle("Buch hinzufügen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Abbrechen") { dismiss() }
                }
            }
            .sheet(isPresented: $showingISBNScanner) {
                ISBNScannerView { scannedISBN in
                    searchQuery = scannedISBN
                    performSearch()
                }
            }
        }
    }

    private func performSearch() {
        let trimmed = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        isSearching = true
        searchResults = []

        Task {
            defer { isSearching = false }
            guard let encoded = trimmed.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                  let url = URL(string: "https://openlibrary.org/search.json?q=\(encoded)&limit=6") else { return }
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let docs = json["docs"] as? [[String: Any]] {
                    self.searchResults = docs.compactMap { doc in
                        guard let t = doc["title"] as? String else { return nil }
                        let authors = doc["author_name"] as? [String]
                        let isbns = doc["isbn"] as? [String]
                        let publishers = doc["publisher"] as? [String]
                        let pages = doc["number_of_pages_median"] as? Int ?? 340
                        return OnlineBookResult(
                            title: t,
                            author: authors?.first ?? "Unbekannt",
                            isbn: isbns?.first ?? "",
                            pageCount: pages,
                            publisher: publishers?.first ?? ""
                        )
                    }
                }
            } catch {
                // Offline fallback
            }
        }
    }
}

// MARK: - Discover, Import/Export & Settings View

struct DiscoverAndSettingsView: View {
    @EnvironmentObject private var store: LibraryStore
    @State private var showingCSVImporter = false
    @State private var showingJSONImporter = false
    @State private var statusBanner: String?
    @State private var showingAddBook = false

    var body: some View {
        NavigationStack {
            ZStack {
                NovelyTheme.espressoBg.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        // Privacy Badge (100% Free & Local!)
                        HStack(spacing: 14) {
                            Image(systemName: "lock.shield.fill")
                                .font(.system(size: 28))
                                .foregroundStyle(Color(hex: "#6BCB77"))
                            VStack(alignment: .leading, spacing: 3) {
                                Text("100 % Privat & Kostenlos")
                                    .font(.system(size: 16, weight: .bold, design: .serif))
                                    .foregroundStyle(NovelyTheme.creamText)
                                Text("Kein Abo, keine Paywall, kein Tracking. Alle deine Bücher & Zitate bleiben lokal auf deinem iPhone.")
                                    .font(.system(size: 12))
                                    .foregroundStyle(NovelyTheme.warmMutedText)
                            }
                        }
                        .padding(16)
                        .novelyGlassCard(cornerRadius: 20, tint: Color(hex: "#2D6A4F").opacity(0.25))

                        if let statusBanner {
                            Text(statusBanner)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(NovelyTheme.warmGold)
                                .padding(12)
                                .frame(maxWidth: .infinity)
                                .novelyGlassCard(cornerRadius: 14)
                        }

                        // Personalization
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Dein Profil & Leseziele")
                                .font(.system(size: 18, weight: .semibold, design: .serif))
                                .foregroundStyle(NovelyTheme.creamText)

                            HStack {
                                Text("Regal-Name")
                                    .foregroundStyle(NovelyTheme.warmMutedText)
                                TextField("Mein", text: Binding(
                                    get: { store.settings.ownerName },
                                    set: { store.settings.ownerName = $0; store.persist() }
                                ))
                                .multilineTextAlignment(.trailing)
                                .foregroundStyle(NovelyTheme.creamText)
                            }

                            Stepper("Jahresziel: \(store.settings.yearlyBookGoal) Bücher", value: Binding(
                                get: { store.settings.yearlyBookGoal },
                                set: { store.settings.yearlyBookGoal = $0; store.persist() }
                            ), in: 1...300)

                            Stepper("Tagesziel: \(store.settings.dailyPagesGoal) Seiten", value: Binding(
                                get: { store.settings.dailyPagesGoal },
                                set: { store.settings.dailyPagesGoal = $0; store.persist() }
                            ), in: 5...300, step: 5)
                        }
                        .padding(16)
                        .novelyGlassCard(cornerRadius: 20)

                        // Import & Backup
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Bibliothek importieren & sichern")
                                .font(.system(size: 18, weight: .semibold, design: .serif))
                                .foregroundStyle(NovelyTheme.creamText)

                            Button {
                                showingCSVImporter = true
                            } label: {
                                Label("Goodreads / StoryGraph CSV importieren", systemImage: "square.and.arrow.down")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(NovelyTheme.creamText)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(12)
                                    .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 14))
                            }
                            .buttonStyle(.plain)

                            Button {
                                showingJSONImporter = true
                            } label: {
                                Label("JSON-Backup wiederherstellen", systemImage: "arrow.counterclockwise")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(NovelyTheme.creamText)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(12)
                                    .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 14))
                            }
                            .buttonStyle(.plain)

                            if let jsonData = store.exportJSONData(),
                               let jsonStr = String(data: jsonData, encoding: .utf8) {
                                ShareLink(item: jsonStr, subject: Text("Novely Backup")) {
                                    Label("Komplettes Backup exportieren", systemImage: "square.and.arrow.up")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(NovelyTheme.warmGold)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(12)
                                        .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 14))
                                }
                            }
                        }
                        .padding(16)
                        .novelyGlassCard(cornerRadius: 20)

                        // Quick Actions
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Schnellaktionen")
                                .font(.system(size: 18, weight: .semibold, design: .serif))
                                .foregroundStyle(NovelyTheme.creamText)

                            Button {
                                showingAddBook = true
                            } label: {
                                Label("Buch per Online-Suche oder Barcode hinzufügen", systemImage: "plus.circle.fill")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(NovelyTheme.creamText)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(12)
                                    .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 14))
                            }
                            .buttonStyle(.plain)

                            Button {
                                store.loadDemoLibrary()
                                statusBanner = "Demo-Bibliothek mit 18 Büchern geladen ✓"
                            } label: {
                                Label("Demo-Regal zurücksetzen", systemImage: "sparkles")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(NovelyTheme.warmMutedText)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(12)
                                    .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 14))
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(16)
                        .novelyGlassCard(cornerRadius: 20)

                        Spacer(minLength: 40)
                    }
                    .padding(18)
                }
            }
            .navigationTitle("Entdecken & Mehr")
            .navigationBarTitleDisplayMode(.inline)
            .fileImporter(isPresented: $showingCSVImporter, allowedContentTypes: [.commaSeparatedText, .plainText]) { result in
                if case .success(let url) = result,
                   url.startAccessingSecurityScopedResource() {
                    defer { url.stopAccessingSecurityScopedResource() }
                    if let text = try? String(contentsOf: url, encoding: .utf8) {
                        let count = store.importGoodreadsCSV(text)
                        statusBanner = "\(count) Bücher aus CSV importiert ✓"
                    }
                }
            }
            .fileImporter(isPresented: $showingJSONImporter, allowedContentTypes: [.json]) { result in
                if case .success(let url) = result,
                   url.startAccessingSecurityScopedResource() {
                    defer { url.stopAccessingSecurityScopedResource() }
                    if let data = try? Data(contentsOf: url), store.importJSONData(data) {
                        statusBanner = "Backup erfolgreich wiederhergestellt ✓"
                    }
                }
            }
            .sheet(isPresented: $showingAddBook) {
                AddBookSheet(defaultShelf: store.selectedShelf)
                    .environmentObject(store)
            }
        }
    }
}
