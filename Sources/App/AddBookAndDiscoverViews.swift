import SwiftUI
import UniformTypeIdentifiers

// MARK: - Add Book Sheet (Magic Scan Flow: Real Cover + Klappentext + "Rücken scannen?" prompt!)

struct AddBookSheet: View {
    @EnvironmentObject private var store: LibraryStore
    @Environment(\.dismiss) private var dismiss

    let defaultShelf: ShelfCategory

    @State private var searchQuery = ""
    @State private var isSearching = false
    @State private var isAddingBook = false
    @State private var searchResults: [OnlineBookResult] = []
    @State private var showingISBNScanner = false
    @State private var pendingSpineBook: Book?
    @State private var showingSpineScanner = false

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

                if let addedBook = pendingSpineBook {
                    // Exact Reel 2 Post-Add Prompt: "Steht im Regal -> Rücken scannen?"
                    postAddSpinePrompt(for: addedBook)
                } else {
                    mainAddForm
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
            .sheet(isPresented: $showingSpineScanner) {
                SpineScannerView(book: pendingSpineBook) { imageData in
                    if var book = pendingSpineBook,
                       let filename = LibraryStorage.saveImageData(imageData, prefix: "spine") {
                        book.customSpineFilename = filename
                        book.displayStyle = .spine
                        store.updateBook(book)
                    }
                    dismiss()
                }
            }
        }
    }

    // MARK: - Post-Add "Rücken scannen?" Prompt (Exact Reel 2 Flow!)

    private func postAddSpinePrompt(for book: Book) -> some View {
        VStack(spacing: 20) {
            Spacer()
            BookCoverForwardView(book: book, scale: 1.1)

            VStack(spacing: 6) {
                Text("Steht im Regal ✨")
                    .font(.system(size: 24, weight: .bold, design: .serif))
                    .foregroundStyle(NovelyTheme.creamText)
                Text(book.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(NovelyTheme.warmGold)
                Text("Fotografier jetzt den Buchrücken, dann steht dein echtes physisches Buch im Regal.")
                    .font(.system(size: 14))
                    .foregroundStyle(NovelyTheme.warmMutedText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 26)
            }

            Spacer()

            VStack(spacing: 12) {
                Button {
                    showingSpineScanner = true
                } label: {
                    Label("Rücken scannen", systemImage: "camera.viewfinder")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(NovelyTheme.creamText, in: Capsule())
                }

                Button("Fertig (mit echtem Cover lassen)") {
                    dismiss()
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(NovelyTheme.warmMutedText)
                .padding(.vertical, 8)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 28)
        }
    }

    // MARK: - Main Search + Barcode + Manual Form

    private var mainAddForm: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                // Big Barcode Scan CTA + Search Bar
                VStack(alignment: .leading, spacing: 10) {
                    Button {
                        showingISBNScanner = true
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "barcode.viewfinder")
                                .font(.system(size: 22))
                                .foregroundStyle(.black)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("ISBN-Barcode scannen")
                                    .font(.system(size: 15.5, weight: .bold))
                                    .foregroundStyle(.black)
                                Text("Lädt echtes Cover, Klappentext & Seitenzahl")
                                    .font(.system(size: 11.5))
                                    .foregroundStyle(.black.opacity(0.7))
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.black.opacity(0.6))
                        }
                        .padding(14)
                        .background(NovelyTheme.creamText, in: RoundedRectangle(cornerRadius: 18))
                    }
                    .buttonStyle(.plain)

                    HStack(spacing: 8) {
                        TextField("Oder Titel / Autor / ISBN suchen...", text: $searchQuery)
                            .textFieldStyle(.plain)
                            .padding(12)
                            .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
                            .onSubmit { performSearch() }

                        Button {
                            performSearch()
                        } label: {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(NovelyTheme.creamText)
                                .padding(12)
                                .novelyGlassCard(cornerRadius: 14)
                        }
                    }

                    // Target Shelf Selector
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach([ShelfCategory.unread, .reading, .read, .wishlist], id: \.self) { cat in
                                let active = shelf == cat
                                Button {
                                    shelf = cat
                                } label: {
                                    Text(cat.rawValue)
                                        .font(.system(size: 12.5, weight: active ? .semibold : .regular))
                                        .foregroundStyle(active ? .black : NovelyTheme.creamText)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 7)
                                        .background(active ? NovelyTheme.warmGold : Color.white.opacity(0.08), in: Capsule())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    if isSearching || isAddingBook {
                        HStack(spacing: 10) {
                            ProgressView().tint(NovelyTheme.warmGold)
                            Text(isAddingBook ? "Lade echtes Buchcover & stelle ins Regal..." : "Suche echte Buchdaten & Cover...")
                                .font(.system(size: 13))
                                .foregroundStyle(NovelyTheme.warmMutedText)
                        }
                        .padding(.top, 4)
                    }

                    // Search Results with REAL Book Cover Previews!
                    ForEach(searchResults) { item in
                        HStack(spacing: 12) {
                            if let coverStr = item.coverURLString, let url = URL(string: coverStr) {
                                AsyncImage(url: url) { phase in
                                    if case .success(let image) = phase {
                                        image.resizable().scaledToFill()
                                    } else {
                                        Color.white.opacity(0.08)
                                    }
                                }
                                .frame(width: 44, height: 64)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                            }

                            VStack(alignment: .leading, spacing: 3) {
                                Text(item.title)
                                    .font(.system(size: 15, weight: .semibold, design: .serif))
                                    .foregroundStyle(NovelyTheme.creamText)
                                    .lineLimit(2)
                                Text(item.author)
                                    .font(.system(size: 12.5))
                                    .foregroundStyle(NovelyTheme.warmMutedText)
                                Text("\(item.publisher.isEmpty ? "Buch" : item.publisher) · \(item.pageCount) Seiten")
                                    .font(.system(size: 11))
                                    .foregroundStyle(NovelyTheme.warmGold)
                            }
                            Spacer()
                            Button("Ins Regal") {
                                addOnlineResult(item)
                            }
                            .font(.system(size: 12.5, weight: .semibold))
                            .foregroundStyle(.black)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(NovelyTheme.creamText, in: Capsule())
                            .disabled(isAddingBook)
                        }
                        .padding(12)
                        .novelyGlassCard(cornerRadius: 16)
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
                        pendingSpineBook = newBook
                    } label: {
                        Text("Ins Regal stellen")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(NovelyTheme.creamText, in: Capsule())
                    }
                    .padding(.top, 4)
                }
            }
            .padding(18)
        }
    }

    private func performSearch() {
        let trimmed = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        isSearching = true
        searchResults = []

        Task {
            defer { isSearching = false }
            self.searchResults = await BookMetadataService.searchBooks(query: trimmed)
        }
    }

    private func addOnlineResult(_ item: OnlineBookResult) {
        isAddingBook = true
        Task {
            defer { isAddingBook = false }
            let coverDownload = await BookMetadataService.downloadAndStoreCover(
                urlString: item.coverURLString,
                isbn: item.isbn
            )

            let book = Book(
                title: item.title,
                author: item.author,
                isbn: item.isbn,
                publisher: item.publisher,
                publishedYear: item.publishedYear,
                bindingType: item.bindingType,
                bookDescription: item.bookDescription,
                pageCount: item.pageCount,
                currentPage: shelf == .read ? item.pageCount : 0,
                shelf: shelf,
                displayStyle: coverDownload != nil ? .coverForward : .spine,
                spineColorHex: coverDownload?.dominantHex ?? (colorChoices.randomElement() ?? "#263B4D"),
                coverURLString: item.coverURLString,
                customCoverFilename: coverDownload?.filename,
                purchasePrice: 18.0
            )
            store.addBook(book)
            pendingSpineBook = book
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
    @State private var showingClearConfirm = false

    var body: some View {
        NavigationStack {
            ZStack {
                NovelyTheme.espressoBg.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        HStack(spacing: 14) {
                            Image(systemName: "lock.shield.fill")
                                .font(.system(size: 28))
                                .foregroundStyle(Color(hex: "#6BCB77"))
                            VStack(alignment: .leading, spacing: 3) {
                                Text("100 % Privat & Kostenlos")
                                    .font(.system(size: 16, weight: .bold, design: .serif))
                                    .foregroundStyle(NovelyTheme.creamText)
                                Text("Kein Abo, keine Paywall, kein Account nötig. Alle Bücher, Cover & Zitate bleiben lokal auf deinem iPhone.")
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

                        // Profile & Goals
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

                        // Quick Actions & Clean Slate
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Regal verwalten")
                                .font(.system(size: 18, weight: .semibold, design: .serif))
                                .foregroundStyle(NovelyTheme.creamText)

                            Button {
                                Task {
                                    statusBanner = "Lade fehlende echte Buchcover..."
                                    await store.hydrateRealCoversIfNeeded()
                                    statusBanner = "Alle verfügbaren echten Cover geladen ✓"
                                }
                            } label: {
                                Label("Fehlende echte Buchcover nachladen", systemImage: "photo.stack")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(NovelyTheme.creamText)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(12)
                                    .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 14))
                            }
                            .buttonStyle(.plain)

                            Button {
                                showingClearConfirm = true
                            } label: {
                                Label("Regal komplett leeren (für eigene Bücher)", systemImage: "trash")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(NovelyTheme.terracotta)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(12)
                                    .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 14))
                            }
                            .buttonStyle(.plain)

                            Button {
                                store.loadDemoLibrary(markOnboarded: true)
                                statusBanner = "Demo-Regal geladen ✓"
                                Task { await store.hydrateRealCoversIfNeeded() }
                            } label: {
                                Label("Demo-Regal laden", systemImage: "sparkles")
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
            .navigationTitle("Mehr")
            .navigationBarTitleDisplayMode(.inline)
            .confirmationDialog("Alle Bücher im Regal entfernen?", isPresented: $showingClearConfirm, titleVisibility: .visible) {
                Button("Alle entfernen", role: .destructive) {
                    store.clearAllBooks()
                    statusBanner = "Regal geleert – bereit für deine eigenen Bücher!"
                }
            }
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
