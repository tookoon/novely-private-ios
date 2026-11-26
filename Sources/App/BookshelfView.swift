import PhotosUI
import SwiftUI

struct BookshelfView: View {
    @EnvironmentObject private var store: LibraryStore
    var onStartReadingBook: ((Book) -> Void)?

    @State private var selectedBook: Book?
    @State private var isEditingShelf = false
    @State private var showingAddBook = false
    @State private var showingShelfCustomizer = false
    @State private var showingSpineScanner = false
    @State private var showingNewCustomShelf = false
    @State private var newCustomShelfName = ""
    @State private var showingTBRPicker = false
    @State private var pickedTBRBook: Book?

    private var currentBooks: [Book] {
        store.activeShelfBooks
    }

    private var shelfRows: [[Book]] {
        let list = currentBooks
        guard !list.isEmpty else { return [[]] } // Always show at least 2 cozy shelves with cat & plant!
        var rows: [[Book]] = []
        var currentRow: [Book] = []
        var currentUnits: CGFloat = 0

        for book in list {
            let units: CGFloat = {
                switch book.displayStyle {
                case .spine: return book.spineWidthPoints + 5
                case .coverForward: return book.spineHeightPoints * 0.67 + 8
                case .stacked:
                    return currentRow.contains(where: { $0.displayStyle == .stacked }) ? 0 : 112
                }
            }()

            if currentUnits + units > 250 && !currentRow.isEmpty {
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
        if rows.count == 1 {
            rows.append([]) // Second cozy shelf tier for decor/plant
        }
        return rows
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                // Warm handcrafted wooden bookshelf cabinet backdrop!
                BookshelfCabinetBackdrop(settings: store.settings)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 14) {
                        headerSection

                        // "Zieh eine Pflanze groß" Gamification Banner (from Reel 2!)
                        if !store.plantState.isBannerDismissed {
                            growingPlantBanner
                        }

                        shelfCategoryBar

                        if isEditingShelf {
                            Text("Tippe auf ein Buch für Rücken/Cover/Stapel · Pfeile oder Wischen zum Verschieben von Büchern & Deko")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(NovelyTheme.warmGold)
                                .padding(.horizontal, 18)
                        }

                        // Realistic 3D Wooden Bookshelf Tiers
                        VStack(spacing: 14) {
                            ForEach(Array(shelfRows.enumerated()), id: \.offset) { rowIndex, rowBooks in
                                let rowDecor = store.decor.filter { $0.rowIndex == rowIndex && $0.isEnabled }
                                BookshelfTierView(
                                    books: rowBooks,
                                    decorItems: rowDecor,
                                    woodFinish: store.settings.woodFinish,
                                    fairyLightsEnabled: store.settings.fairyLightsEnabled,
                                    scale: 1.0,
                                    plantStage: store.plantGrowthStage,
                                    isEditing: isEditingShelf,
                                    onTapBook: { book in
                                        selectedBook = book
                                    },
                                    onMoveBook: { book, dir in
                                        store.moveBook(book, direction: dir)
                                    },
                                    onCycleStyle: { book in
                                        store.cycleDisplayStyle(for: book)
                                    },
                                    onShiftDecor: { item, delta in
                                        store.shiftDecor(item, slotDelta: delta)
                                    }
                                )
                            }
                        }
                        .padding(.top, 4)

                        // Book Series Preview Strip
                        if !store.seriesGroups.isEmpty {
                            seriesStrip
                                .padding(.top, 8)
                        }

                        Spacer(minLength: 96)
                    }
                    .padding(.top, 6)
                }

                // Floating "+ Ins Regal" Liquid Glass Pill (exact Reel 1 & 2 placement!)
                Button {
                    showingAddBook = true
                } label: {
                    Label("Ins Regal", systemImage: "plus")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 22)
                        .padding(.vertical, 12)
                        .background(NovelyTheme.creamText, in: Capsule())
                        .shadow(color: .black.opacity(0.42), radius: 12, y: 5)
                }
                .padding(.bottom, 14)
                .accessibilityIdentifier("addBookFloatingButton")
            }
            .toolbar {
                ToolbarItemGroup(placement: .topBarLeading) {
                    Button {
                        showingShelfCustomizer = true
                    } label: {
                        Image(systemName: "paintbrush.pointed.fill")
                            .foregroundStyle(NovelyTheme.creamText)
                    }
                    .accessibilityIdentifier("customizeShelfButton")

                    Button {
                        showingTBRPicker = true
                        pickedTBRBook = (store.books(for: .unread).isEmpty ? store.books : store.books(for: .unread)).randomElement()
                    } label: {
                        Image(systemName: "dice.fill")
                            .foregroundStyle(NovelyTheme.creamText)
                    }
                    .accessibilityIdentifier("tbrRandomizerButton")
                }

                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            isEditingShelf.toggle()
                        }
                    } label: {
                        Text(isEditingShelf ? "Fertig" : "Bearbeiten")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(isEditingShelf ? NovelyTheme.warmGold : NovelyTheme.creamText)
                    }
                    .accessibilityIdentifier("editShelfButton")
                }
            }
            .sheet(item: $selectedBook) { book in
                BookDetailSheet(book: book, onStartReading: { b in
                    selectedBook = nil
                    onStartReadingBook?(b)
                })
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
            .sheet(isPresented: $showingTBRPicker) {
                tbrRandomizerSheet
                    .presentationDetents([.height(340)])
            }
            .alert("Neues eigenes Regal", isPresented: $showingNewCustomShelf) {
                TextField("z. B. Favoriten 2026, Manga...", text: $newCustomShelfName)
                Button("Erstellen") {
                    store.addCustomShelf(name: newCustomShelfName, iconName: "star.fill")
                    newCustomShelfName = ""
                }
                Button("Abbrechen", role: .cancel) {}
            }
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(store.settings.displayTitle)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(NovelyTheme.creamText.opacity(0.8))

            Text("\(store.activeShelfTitle) · \(currentBooks.count) \(currentBooks.count == 1 ? "Buch" : "Bücher")")
                .font(.system(size: 27, weight: .bold, design: .serif))
                .foregroundStyle(NovelyTheme.creamText)
                .shadow(color: .black.opacity(0.35), radius: 4, y: 2)
        }
        .padding(.horizontal, 18)
    }

    // MARK: - "Zieh eine Pflanze groß" Banner (Reel 2)

    private var growingPlantBanner: some View {
        let stage = store.plantGrowthStage
        let stageName = ["Keimling", "Jungpflanze", "Wächst kräftig", "Üppige Monstera", "Volle Blüte ✨"][min(4, max(0, stage - 1))]

        return HStack(spacing: 12) {
            Image("DecorPottedPlant")
                .resizable()
                .scaledToFit()
                .frame(width: 44, height: 48)

            VStack(alignment: .leading, spacing: 3) {
                Text("Zieh deine Pflanze groß · Stufe \(stage)/5")
                    .font(.system(size: 14, weight: .bold, design: .serif))
                    .foregroundStyle(NovelyTheme.creamText)
                Text("Sie wächst an jedem Tag, an dem du liest (\(stageName)).")
                    .font(.system(size: 11.5))
                    .foregroundStyle(NovelyTheme.creamText.opacity(0.82))
            }

            Spacer(minLength: 4)

            Button {
                withAnimation {
                    store.plantState.isBannerDismissed = true
                    store.persist()
                }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(NovelyTheme.creamText.opacity(0.7))
                    .padding(6)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .novelyGlassCard(cornerRadius: 18, tint: Color(hex: "#2D4A36").opacity(0.35))
        .padding(.horizontal, 16)
    }

    // MARK: - Shelf Category & Custom Shelf Bar

    private var shelfCategoryBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(ShelfCategory.allCases) { category in
                    let isSelected = store.selectedCustomShelfId == nil && store.selectedShelf == category
                    let count = store.books(for: category).count
                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            store.selectedCustomShelfId = nil
                            store.selectedShelf = category
                        }
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: category.iconName)
                                .font(.system(size: 11.5, weight: .semibold))
                            Text(category.rawValue)
                                .font(.system(size: 13.5, weight: isSelected ? .semibold : .regular))
                            if count > 0 {
                                Text("\(count)")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(isSelected ? NovelyTheme.warmGold : NovelyTheme.creamText.opacity(0.7))
                            }
                        }
                        .foregroundStyle(NovelyTheme.creamText)
                        .padding(.horizontal, 13)
                        .padding(.vertical, 8)
                        .novelyGlassCapsule(tint: isSelected ? NovelyTheme.terracotta.opacity(0.45) : Color.black.opacity(0.22))
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("shelfTab_\(category.rawValue)")
                }

                // Custom User Shelves
                ForEach(store.customShelves) { custom in
                    let isSelected = store.selectedCustomShelfId == custom.id
                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            store.selectedCustomShelfId = custom.id
                        }
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: custom.iconName)
                                .font(.system(size: 11.5))
                            Text(custom.name)
                                .font(.system(size: 13.5, weight: isSelected ? .semibold : .regular))
                        }
                        .foregroundStyle(NovelyTheme.creamText)
                        .padding(.horizontal, 13)
                        .padding(.vertical, 8)
                        .novelyGlassCapsule(tint: isSelected ? NovelyTheme.terracotta.opacity(0.45) : Color.black.opacity(0.22))
                    }
                    .buttonStyle(.plain)
                }

                Button {
                    showingNewCustomShelf = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(NovelyTheme.creamText)
                        .padding(9)
                        .novelyGlassCapsule(tint: Color.black.opacity(0.22))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
        }
    }

    private var seriesStrip: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Deine Buchreihen")
                .font(.system(size: 18, weight: .semibold, design: .serif))
                .foregroundStyle(NovelyTheme.creamText)
                .shadow(color: .black.opacity(0.35), radius: 3)
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
                                        RoundedRectangle(cornerRadius: 2)
                                            .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [3, 2]))
                                            .foregroundStyle(NovelyTheme.creamText.opacity(0.45))
                                            .frame(width: 14, height: 42)
                                            .overlay(
                                                Text("\(index)")
                                                    .font(.system(size: 8))
                                                    .foregroundStyle(NovelyTheme.creamText.opacity(0.6))
                                            )
                                    }
                                }
                            }

                            if !group.missingIndices.isEmpty {
                                Text("Fehlt: Band \(group.missingIndices.map(String.init).joined(separator: ", "))")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundStyle(NovelyTheme.warmGold)
                            } else {
                                Text("Reihe komplett ✓")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundStyle(Color(hex: "#8CE99A"))
                            }
                        }
                        .padding(14)
                        .frame(width: 185)
                        .novelyGlassCard(cornerRadius: 18, tint: Color.black.opacity(0.28))
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }

    // MARK: - TBR Randomizer ("Was lese ich als Nächstes?")

    private var tbrRandomizerSheet: some View {
        ZStack {
            NovelyTheme.espressoBg.ignoresSafeArea()
            VStack(spacing: 16) {
                Text("Was lese ich als Nächstes?")
                    .font(.system(size: 22, weight: .bold, design: .serif))
                    .foregroundStyle(NovelyTheme.creamText)
                    .padding(.top, 16)

                if let book = pickedTBRBook {
                    HStack(spacing: 16) {
                        BookCoverForwardView(book: book, scale: 0.72)
                        VStack(alignment: .leading, spacing: 6) {
                            Text(book.title)
                                .font(.system(size: 18, weight: .bold, design: .serif))
                                .foregroundStyle(NovelyTheme.creamText)
                            Text(book.author)
                                .font(.system(size: 14))
                                .foregroundStyle(NovelyTheme.warmMutedText)
                            Text("\(book.pageCount) Seiten · \(store.estimatedRemainingTimeString(for: book))")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(NovelyTheme.warmGold)
                        }
                    }
                    .padding(14)
                    .novelyGlassCard(cornerRadius: 20)
                    .padding(.horizontal, 20)
                }

                HStack(spacing: 12) {
                    Button {
                        let pool = store.books(for: .unread).isEmpty ? store.books : store.books(for: .unread)
                        withAnimation(.spring) {
                            pickedTBRBook = pool.randomElement()
                        }
                    } label: {
                        Label("Neu würfeln", systemImage: "dice.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(NovelyTheme.creamText)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 12)
                            .novelyGlassCapsule()
                    }

                    if let book = pickedTBRBook {
                        Button {
                            showingTBRPicker = false
                            onStartReadingBook?(book)
                        } label: {
                            Text("Jetzt anfangen")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.black)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                .background(NovelyTheme.creamText, in: Capsule())
                        }
                    }
                }
                Spacer()
            }
        }
    }
}

// MARK: - Shelf Customizer Sheet (Warm Walls, Custom Photo Wall, Wood, Fairy Lights, Cat/Plant/Snowman)

struct ShelfCustomizerSheet: View {
    @EnvironmentObject private var store: LibraryStore
    @Environment(\.dismiss) private var dismiss
    @State private var wallPhotoItem: PhotosPickerItem?

    var body: some View {
        NavigationStack {
            ZStack {
                NovelyTheme.espressoBg.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Live Mini Shelf Preview
                        ZStack {
                            BookshelfCabinetBackdrop(settings: store.settings)
                            BookshelfTierView(
                                books: Array(store.activeShelfBooks.prefix(4)),
                                decorItems: store.decor.filter { $0.rowIndex == 0 && $0.isEnabled },
                                woodFinish: store.settings.woodFinish,
                                fairyLightsEnabled: store.settings.fairyLightsEnabled,
                                scale: 0.78,
                                plantStage: store.plantGrowthStage
                            )
                            .padding(.vertical, 12)
                        }
                        .frame(height: 165)
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

                        // Wall Theme + Custom Photo
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text("Regal-Hintergrund")
                                    .font(.system(size: 16, weight: .semibold, design: .serif))
                                    .foregroundStyle(NovelyTheme.creamText)
                                Spacer()
                                PhotosPicker(selection: $wallPhotoItem, matching: .images) {
                                    Label("Eigenes Foto", systemImage: "photo")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundStyle(NovelyTheme.warmGold)
                                }
                            }

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(ShelfWallTheme.allCases) { theme in
                                        let active = store.settings.customWallPhotoFilename == nil && store.settings.wallTheme == theme
                                        Button {
                                            store.settings.customWallPhotoFilename = nil
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
                                                        Circle().strokeBorder(active ? NovelyTheme.warmGold : .white.opacity(0.2), lineWidth: active ? 2.5 : 1)
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
                            HStack(spacing: 8) {
                                ForEach(WoodFinish.allCases) { wood in
                                    let active = store.settings.woodFinish == wood
                                    Button {
                                        store.settings.woodFinish = wood
                                        store.persist()
                                    } label: {
                                        Text(wood.rawValue)
                                            .font(.system(size: 12.5, weight: .semibold))
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
                            Toggle("Lichterkette mit Schnur", isOn: Binding(
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

                        // Decor Objects (Cat, Plant, Candle, Snowman...)
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Regal-Deko (Katze, Pflanze & mehr)")
                                .font(.system(size: 16, weight: .semibold, design: .serif))
                                .foregroundStyle(NovelyTheme.creamText)

                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 10)], spacing: 10) {
                                ForEach(Array(DecorKind.allCases.enumerated()), id: \.element.id) { idx, kind in
                                    let enabled = store.decor.first(where: { $0.kind == kind })?.isEnabled ?? false
                                    Button {
                                        store.toggleDecor(kind, rowIndex: idx % 2)
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
                                            tint: enabled ? NovelyTheme.terracotta.opacity(0.28) : nil
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
            .onChange(of: wallPhotoItem) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let filename = LibraryStorage.saveImageData(data, prefix: "wall") {
                        store.settings.customWallPhotoFilename = filename
                        store.persist()
                    }
                }
            }
        }
    }
}
