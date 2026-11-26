import SwiftUI

struct BookshelfView: View {
    @EnvironmentObject private var store: LibraryStore
    @State private var selectedBook: Book?
    @State private var showingAddBook = false
    @State private var showingShelfCustomizer = false
    @State private var showingSpineScanner = false
    @State private var searchText = ""

    private var currentBooks: [Book] {
        let base = store.books(for: store.selectedShelf)
        if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return base
        }
        let q = searchText.lowercased()
        return base.filter {
            $0.title.lowercased().contains(q) || $0.author.lowercased().contains(q)
        }
    }

    /// Groups books into realistic shelf tiers (max ~6 items or 1 stack + 4 upright per row)
    private var shelfRows: [[Book]] {
        let list = currentBooks
        guard !list.isEmpty else { return [] }
        var rows: [[Book]] = []
        var currentRow: [Book] = []
        var currentUnits: CGFloat = 0

        for book in list {
            let units: CGFloat = {
                switch book.displayStyle {
                case .spine: return book.spineWidthPoints + 5
                case .coverForward: return book.spineHeightPoints * 0.67 + 8
                case .stacked:
                    // Stacked books share width if already a stacked book in row
                    return currentRow.contains(where: { $0.displayStyle == .stacked }) ? 0 : 112
                }
            }()

            if currentUnits + units > 315 && !currentRow.isEmpty {
                rows.append(currentRow)
                currentRow = [book]
                currentUnits = max(units, 40)
            } else {
                currentRow.append(book)
                currentUnits += units
            }
        }
        if !currentRow.isEmpty {
            rows.append(currentRow)
        }
        return rows
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Cozy textured wall backdrop
                LinearGradient(
                    colors: [
                        Color(hex: store.settings.wallTheme.topHex),
                        Color(hex: store.settings.wallTheme.bottomHex)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                // Warm top ambient spotlight cone
                if store.settings.warmSpotlightsEnabled {
                    RadialGradient(
                        colors: [
                            Color(hex: "#FFB85C").opacity(0.16),
                            Color.clear
                        ],
                        center: .top,
                        startRadius: 20,
                        endRadius: 360
                    )
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
                }

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        headerSection
                        shelfCategoryBar

                        if shelfRows.isEmpty {
                            emptyShelfCard
                        } else {
                            VStack(spacing: 22) {
                                ForEach(Array(shelfRows.enumerated()), id: \.offset) { rowIndex, rowBooks in
                                    let rowDecor = store.decor.first(where: { $0.rowIndex == rowIndex && $0.isEnabled })
                                    BookshelfTierView(
                                        books: rowBooks,
                                        decorItem: rowDecor,
                                        woodFinish: store.settings.woodFinish,
                                        fairyLightsEnabled: store.settings.fairyLightsEnabled,
                                        scale: 1.0,
                                        onTapBook: { book in
                                            selectedBook = book
                                        }
                                    )
                                }
                            }
                            .padding(.top, 6)
                        }

                        // Quick Series preview banner if books belong to series
                        if !store.seriesGroups.isEmpty {
                            seriesStrip
                                .padding(.top, 12)
                        }

                        Spacer(minLength: 40)
                    }
                    .padding(.top, 8)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showingShelfCustomizer = true
                    } label: {
                        Image(systemName: "paintbrush.pointed.fill")
                            .foregroundStyle(NovelyTheme.creamText)
                    }
                    .accessibilityIdentifier("customizeShelfButton")
                }

                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        showingSpineScanner = true
                    } label: {
                        Image(systemName: "camera.viewfinder")
                            .foregroundStyle(NovelyTheme.creamText)
                    }
                    .accessibilityIdentifier("spineScannerButton")

                    Button {
                        showingAddBook = true
                    } label: {
                        Image(systemName: "plus")
                            .fontWeight(.semibold)
                            .foregroundStyle(NovelyTheme.creamText)
                    }
                    .accessibilityIdentifier("addBookButton")
                }
            }
            .sheet(item: $selectedBook) { book in
                BookDetailSheet(book: book)
                    .environmentObject(store)
            }
            .sheet(isPresented: $showingAddBook) {
                AddBookSheet(defaultShelf: store.selectedShelf)
                    .environmentObject(store)
            }
            .sheet(isPresented: $showingShelfCustomizer) {
                ShelfCustomizerSheet()
                    .environmentObject(store)
            }
            .sheet(isPresented: $showingSpineScanner) {
                SpineScannerView(book: currentBooks.first) { imageData in
                    if var first = currentBooks.first,
                       let filename = LibraryStorage.saveImageData(imageData, prefix: "spine") {
                        first.customSpineFilename = filename
                        store.updateBook(first)
                    }
                }
            }
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(store.settings.displayTitle)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(NovelyTheme.warmMutedText)

            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("\(store.selectedShelf.rawValue) · \(currentBooks.count) \(currentBooks.count == 1 ? "Buch" : "Bücher")")
                    .font(.system(size: 28, weight: .bold, design: .serif))
                    .foregroundStyle(NovelyTheme.creamText)
                Spacer()
            }
        }
        .padding(.horizontal, 18)
    }

    private var shelfCategoryBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(ShelfCategory.allCases) { category in
                    let isSelected = store.selectedShelf == category
                    let count = store.books(for: category).count
                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            store.selectedShelf = category
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: category.iconName)
                                .font(.system(size: 12, weight: .semibold))
                            Text(category.rawValue)
                                .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                            if count > 0 {
                                Text("\(count)")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(isSelected ? NovelyTheme.terracotta : NovelyTheme.warmMutedText)
                            }
                        }
                        .foregroundStyle(isSelected ? NovelyTheme.creamText : NovelyTheme.warmMutedText)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .novelyGlassCapsule(tint: isSelected ? NovelyTheme.terracotta.opacity(0.28) : nil)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("shelfTab_\(category.rawValue)")
                }
            }
            .padding(.horizontal, 18)
        }
    }

    private var emptyShelfCard: some View {
        VStack(spacing: 14) {
            Image(systemName: "books.vertical")
                .font(.system(size: 38, weight: .light))
                .foregroundStyle(NovelyTheme.warmGold)

            Text("Dieses Regal ist noch leer")
                .font(.system(size: 20, weight: .semibold, design: .serif))
                .foregroundStyle(NovelyTheme.creamText)

            Text("Scanne einen ISBN-Barcode, suche nach einem Titel oder importiere deine Goodreads-Bibliothek.")
                .font(.system(size: 14))
                .foregroundStyle(NovelyTheme.warmMutedText)
                .multilineTextAlignment(.center)

            Button {
                showingAddBook = true
            } label: {
                Label("Erstes Buch hinzufügen", systemImage: "plus")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 11)
                    .background(NovelyTheme.creamText, in: Capsule())
            }
            .padding(.top, 4)
        }
        .padding(28)
        .frame(maxWidth: .infinity)
        .novelyGlassCard(cornerRadius: 24)
        .padding(.horizontal, 18)
        .padding(.top, 16)
    }

    private var seriesStrip: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Deine Buchreihen")
                .font(.system(size: 18, weight: .semibold, design: .serif))
                .foregroundStyle(NovelyTheme.creamText)
                .padding(.horizontal, 18)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(store.seriesGroups) { group in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(group.name)
                                    .font(.system(size: 15, weight: .semibold, design: .serif))
                                    .foregroundStyle(NovelyTheme.creamText)
                                Spacer()
                                Text("\(group.ownedBooks.count)/\(group.totalExpected)")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(NovelyTheme.warmGold)
                            }

                            HStack(alignment: .bottom, spacing: 4) {
                                ForEach(1...max(group.totalExpected, 1), id: \.self) { index in
                                    if let owned = group.ownedBooks.first(where: { $0.seriesIndex == index }) {
                                        RoundedRectangle(cornerRadius: 2)
                                            .fill(Color(hex: owned.spineColorHex))
                                            .frame(width: 14, height: 42)
                                            .overlay(
                                                Text("\(index)")
                                                    .font(.system(size: 8, weight: .bold))
                                                    .foregroundStyle(Color(hex: owned.spineTextColorHex))
                                            )
                                    } else {
                                        // Ghosted missing volume on shelf!
                                        RoundedRectangle(cornerRadius: 2)
                                            .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [3, 2]))
                                            .foregroundStyle(NovelyTheme.warmMutedText.opacity(0.45))
                                            .frame(width: 14, height: 42)
                                            .overlay(
                                                Text("\(index)")
                                                    .font(.system(size: 8))
                                                    .foregroundStyle(NovelyTheme.warmMutedText.opacity(0.6))
                                            )
                                    }
                                }
                            }

                            if !group.missingIndices.isEmpty {
                                Text("Fehlt: Band \(group.missingIndices.map(String.init).joined(separator: ", "))")
                                    .font(.system(size: 11))
                                    .foregroundStyle(NovelyTheme.terracotta)
                            } else {
                                Text("Reihe komplett ✓")
                                    .font(.system(size: 11))
                                    .foregroundStyle(Color(hex: "#6BCB77"))
                            }
                        }
                        .padding(14)
                        .frame(width: 185)
                        .novelyGlassCard(cornerRadius: 18)
                    }
                }
                .padding(.horizontal, 18)
            }
        }
    }
}

// MARK: - Shelf Customizer Sheet (Wall, Wood, Lights, Decor)

struct ShelfCustomizerSheet: View {
    @EnvironmentObject private var store: LibraryStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                NovelyTheme.espressoBg.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        // Live Mini Preview
                        BookshelfTierView(
                            books: Array(store.books(for: store.selectedShelf).prefix(5)),
                            decorItem: store.decor.first(where: { $0.isEnabled }),
                            woodFinish: store.settings.woodFinish,
                            fairyLightsEnabled: store.settings.fairyLightsEnabled,
                            scale: 0.78
                        )
                        .padding(.vertical, 12)
                        .background(
                            LinearGradient(
                                colors: [
                                    Color(hex: store.settings.wallTheme.topHex),
                                    Color(hex: store.settings.wallTheme.bottomHex)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            in: RoundedRectangle(cornerRadius: 20)
                        )

                        // Wall Theme
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Rückwand")
                                .font(.system(size: 16, weight: .semibold, design: .serif))
                                .foregroundStyle(NovelyTheme.creamText)
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(ShelfWallTheme.allCases) { theme in
                                        let active = store.settings.wallTheme == theme
                                        Button {
                                            store.settings.wallTheme = theme
                                            store.persist()
                                        } label: {
                                            VStack(spacing: 6) {
                                                Circle()
                                                    .fill(
                                                        LinearGradient(
                                                            colors: [Color(hex: theme.topHex), Color(hex: theme.bottomHex)],
                                                            startPoint: .top,
                                                            endPoint: .bottom
                                                        )
                                                    )
                                                    .frame(width: 44, height: 44)
                                                    .overlay(
                                                        Circle().strokeBorder(active ? NovelyTheme.terracotta : .white.opacity(0.2), lineWidth: active ? 2.5 : 1)
                                                    )
                                                Text(theme.rawValue)
                                                    .font(.system(size: 11, weight: active ? .bold : .regular))
                                                    .foregroundStyle(active ? NovelyTheme.creamText : NovelyTheme.warmMutedText)
                                            }
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }

                        // Wood Finish
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Regalholz")
                                .font(.system(size: 16, weight: .semibold, design: .serif))
                                .foregroundStyle(NovelyTheme.creamText)
                            HStack(spacing: 10) {
                                ForEach(WoodFinish.allCases) { wood in
                                    let active = store.settings.woodFinish == wood
                                    Button {
                                        store.settings.woodFinish = wood
                                        store.persist()
                                    } label: {
                                        Text(wood.rawValue)
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundStyle(NovelyTheme.creamText)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 10)
                                            .background(Color(hex: wood.frontHex), in: RoundedRectangle(cornerRadius: 12))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .strokeBorder(active ? NovelyTheme.warmGold : .clear, lineWidth: 2)
                                            )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }

                        // Lighting Toggles
                        VStack(spacing: 12) {
                            Toggle("Lichterkette am Regal", isOn: Binding(
                                get: { store.settings.fairyLightsEnabled },
                                set: { store.settings.fairyLightsEnabled = $0; store.persist() }
                            ))
                            Toggle("Warme Regal-Spotlights", isOn: Binding(
                                get: { store.settings.warmSpotlightsEnabled },
                                set: { store.settings.warmSpotlightsEnabled = $0; store.persist() }
                            ))
                        }
                        .tint(NovelyTheme.terracotta)
                        .padding(16)
                        .novelyGlassCard(cornerRadius: 18)

                        // Decor Objects
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Regal-Dekoration")
                                .font(.system(size: 16, weight: .semibold, design: .serif))
                                .foregroundStyle(NovelyTheme.creamText)

                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 10)], spacing: 10) {
                                ForEach(Array(DecorKind.allCases.enumerated()), id: \.element.id) { idx, kind in
                                    let enabled = store.decor.first(where: { $0.kind == kind })?.isEnabled ?? false
                                    Button {
                                        store.toggleDecor(kind, rowIndex: idx % 3)
                                    } label: {
                                        VStack(spacing: 8) {
                                            Image(systemName: kind.symbolName)
                                                .font(.system(size: 20))
                                                .foregroundStyle(enabled ? NovelyTheme.warmGold : NovelyTheme.warmMutedText)
                                            Text(kind.rawValue)
                                                .font(.system(size: 12, weight: .medium))
                                                .foregroundStyle(NovelyTheme.creamText)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 14)
                                        .novelyGlassCard(
                                            cornerRadius: 16,
                                            tint: enabled ? NovelyTheme.terracotta.opacity(0.25) : nil
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                    .padding(18)
                }
            }
            .navigationTitle("Regal gestalten")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fertig") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
    }
}
