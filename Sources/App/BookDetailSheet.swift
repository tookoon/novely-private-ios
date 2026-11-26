import PhotosUI
import SwiftUI

struct BookDetailSheet: View {
    @EnvironmentObject private var store: LibraryStore
    @Environment(\.dismiss) private var dismiss

    @State private var book: Book
    @State private var rotationY: Double = -18
    @State private var dragStartRotation: Double = -18
    @State private var selectedCoverPhoto: PhotosPickerItem?
    @State private var selectedSpinePhoto: PhotosPickerItem?
    @State private var newQuoteText = ""
    @State private var newQuotePage = ""
    @State private var showingQuoteScanner = false
    @State private var showingSpineScanner = false
    @State private var showingDeleteConfirm = false

    private let spineColorPresets = [
        "#1E1A18", "#8C2622", "#142738", "#B57B3C",
        "#263B4D", "#174B3E", "#C24658", "#E06A3E",
        "#D4A73B", "#352A47", "#2B4A38", "#DFD5C5"
    ]

    init(book: Book) {
        _book = State(initialValue: book)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color(hex: book.spineColorHex).opacity(0.35), NovelyTheme.espressoBg],
                    startPoint: .top,
                    endPoint: .center
                )
                .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 22) {
                        // Interactive 3D Rotatable Hardcover Book!
                        interactive3DBookStage

                        // Title, Author & Rating
                        VStack(spacing: 6) {
                            Text(book.title)
                                .font(.system(size: 26, weight: .bold, design: .serif))
                                .foregroundStyle(NovelyTheme.creamText)
                                .multilineTextAlignment(.center)
                            Text(book.author)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(NovelyTheme.warmMutedText)

                            if let series = book.seriesName, !series.isEmpty {
                                Text("\(series)\(book.seriesIndex.map { " · Band \($0)" } ?? "")")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(NovelyTheme.warmGold)
                                    .padding(.top, 2)
                            }

                            // Interactive 5-Star Rating (0.5 steps)
                            HStack(spacing: 8) {
                                ForEach(1...5, id: \.self) { star in
                                    Button {
                                        if book.rating == Double(star) {
                                            book.rating = Double(star) - 0.5
                                        } else {
                                            book.rating = Double(star)
                                        }
                                        store.updateBook(book)
                                    } label: {
                                        Image(systemName: starImage(for: star))
                                            .font(.system(size: 22))
                                            .foregroundStyle(NovelyTheme.warmGold)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.top, 8)
                        }
                        .padding(.horizontal, 20)

                        // Reading Progress Card
                        progressSection

                        // Shelf & Display Style Controls
                        shelfArrangementSection

                        // Real Spine / Cover Photo + Color Customization
                        appearanceSection

                        // Tropes
                        tropesSection

                        // Mein Exemplar & Verliehen
                        editionAndLendingSection

                        // Quotes & Notes
                        quotesSection

                        // Delete Button
                        Button(role: .destructive) {
                            showingDeleteConfirm = true
                        } label: {
                            Label("Buch aus Regal entfernen", systemImage: "trash")
                                .font(.system(size: 14, weight: .semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .novelyGlassCard(cornerRadius: 16, tint: .red.opacity(0.18))
                        }
                        .padding(.bottom, 30)
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 10)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Schließen") {
                        store.updateBook(book)
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Speichern") {
                        store.updateBook(book)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .confirmationDialog("Buch wirklich löschen?", isPresented: $showingDeleteConfirm, titleVisibility: .visible) {
                Button("Löschen", role: .destructive) {
                    store.deleteBook(book)
                    dismiss()
                }
            }
            .onChange(of: selectedCoverPhoto) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let filename = LibraryStorage.saveImageData(data, prefix: "cover") {
                        book.customCoverFilename = filename
                        store.updateBook(book)
                    }
                }
            }
            .onChange(of: selectedSpinePhoto) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let filename = LibraryStorage.saveImageData(data, prefix: "spine") {
                        book.customSpineFilename = filename
                        store.updateBook(book)
                    }
                }
            }
            .sheet(isPresented: $showingQuoteScanner) {
                QuoteOCRScannerView(book: book) { extractedQuote, pageNum in
                    store.addQuote(to: book.id, text: extractedQuote, pageNumber: pageNum)
                    book.quotes.insert(BookQuote(text: extractedQuote, pageNumber: pageNum), at: 0)
                }
            }
            .sheet(isPresented: $showingSpineScanner) {
                SpineScannerView(book: book) { imageData in
                    if let filename = LibraryStorage.saveImageData(imageData, prefix: "spine") {
                        book.customSpineFilename = filename
                        store.updateBook(book)
                    }
                }
            }
        }
    }

    // MARK: - Interactive 3D Book Stage

    private var interactive3DBookStage: some View {
        VStack(spacing: 10) {
            ZStack {
                // Soft floor shadow
                Ellipse()
                    .fill(.black.opacity(0.55))
                    .frame(width: 150, height: 22)
                    .blur(radius: 10)
                    .offset(y: 95)

                // 3D Composite: Spine + Cover + Page Edges
                HStack(spacing: 0) {
                    BookSpineView(book: book, scale: 1.35)
                        .opacity(rotationY < 10 ? 1 : 0.4)
                    BookCoverForwardView(book: book, scale: 1.35)
                }
                .rotation3DEffect(
                    .degrees(rotationY),
                    axis: (x: 0.08, y: 1, z: 0),
                    perspective: 0.45
                )
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            rotationY = max(-65, min(45, dragStartRotation + Double(value.translation.width) * 0.5))
                        }
                        .onEnded { _ in
                            dragStartRotation = rotationY
                        }
                )
            }
            .frame(height: 220)

            Label("Ziehen zum 3D-Drehen", systemImage: "rotate.3d")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(NovelyTheme.warmMutedText)
        }
    }

    // MARK: - Sections

    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Lesefortschritt")
                    .font(.system(size: 16, weight: .semibold, design: .serif))
                    .foregroundStyle(NovelyTheme.creamText)
                Spacer()
                Text("Seite \(book.currentPage) von \(book.pageCount) (\(book.progressPercent)%)")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(NovelyTheme.warmGold)
            }

            Slider(
                value: Binding(
                    get: { Double(book.currentPage) },
                    set: { book.currentPage = Int($0) }
                ),
                in: 0...Double(max(1, book.pageCount)),
                step: 1
            )
            .tint(NovelyTheme.terracotta)

            HStack(spacing: 10) {
                Button("+15 Seiten") {
                    let target = min(book.pageCount, book.currentPage + 15)
                    book.currentPage = target
                    store.logProgress(for: book.id, newPage: target)
                }
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(NovelyTheme.creamText)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .novelyGlassCapsule()

                Button("Als gelesen markieren") {
                    book.currentPage = book.pageCount
                    book.shelf = .read
                    book.dateFinished = Date()
                    store.logProgress(for: book.id, newPage: book.pageCount)
                }
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.black)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(NovelyTheme.creamText, in: Capsule())
            }
        }
        .padding(16)
        .novelyGlassCard(cornerRadius: 20)
    }

    private var shelfArrangementSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Regal & Aufstellung")
                .font(.system(size: 16, weight: .semibold, design: .serif))
                .foregroundStyle(NovelyTheme.creamText)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(ShelfCategory.allCases) { cat in
                        let active = book.shelf == cat
                        Button {
                            book.shelf = cat
                            store.updateBook(book)
                        } label: {
                            Text(cat.rawValue)
                                .font(.system(size: 13, weight: active ? .semibold : .regular))
                                .foregroundStyle(active ? .black : NovelyTheme.creamText)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(
                                    active ? NovelyTheme.creamText : Color.white.opacity(0.08),
                                    in: Capsule()
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            HStack(spacing: 8) {
                ForEach(BookDisplayStyle.allCases) { style in
                    let active = book.displayStyle == style
                    Button {
                        book.displayStyle = style
                        store.updateBook(book)
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: style.iconName)
                                .font(.system(size: 16))
                            Text(style.rawValue)
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .foregroundStyle(active ? NovelyTheme.creamText : NovelyTheme.warmMutedText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .novelyGlassCard(
                            cornerRadius: 14,
                            tint: active ? NovelyTheme.terracotta.opacity(0.32) : nil
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(16)
        .novelyGlassCard(cornerRadius: 20)
    }

    private var appearanceSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Rücken, Cover & Größe")
                .font(.system(size: 16, weight: .semibold, design: .serif))
                .foregroundStyle(NovelyTheme.creamText)

            HStack(spacing: 10) {
                Button {
                    showingSpineScanner = true
                } label: {
                    Label("Rücken scannen", systemImage: "camera.viewfinder")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(NovelyTheme.creamText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .novelyGlassCapsule(tint: NovelyTheme.terracotta.opacity(0.25))
                }
                .buttonStyle(.plain)

                PhotosPicker(selection: $selectedCoverPhoto, matching: .images) {
                    Label("Cover-Foto", systemImage: "photo")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(NovelyTheme.creamText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .novelyGlassCapsule()
                }
            }

            // Spine Color Palette
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(spineColorPresets, id: \.self) { hex in
                        Circle()
                            .fill(Color(hex: hex))
                            .frame(width: 30, height: 30)
                            .overlay(
                                Circle().strokeBorder(
                                    book.spineColorHex == hex ? NovelyTheme.warmGold : .white.opacity(0.25),
                                    lineWidth: book.spineColorHex == hex ? 2.5 : 1
                                )
                            )
                            .onTapGesture {
                                book.spineColorHex = hex
                                store.updateBook(book)
                            }
                    }
                }
            }

            HStack {
                Text("Buchhöhe: \(String(format: "%.1f cm", book.heightCm))")
                    .font(.system(size: 13))
                    .foregroundStyle(NovelyTheme.warmMutedText)
                Slider(value: $book.heightCm, in: 17...26, step: 0.5)
                    .tint(NovelyTheme.warmGold)
            }
        }
        .padding(16)
        .novelyGlassCard(cornerRadius: 20)
    }

    private var tropesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Tropes & Vibes")
                .font(.system(size: 16, weight: .semibold, design: .serif))
                .foregroundStyle(NovelyTheme.creamText)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(BuiltInTropes.all, id: \.self) { trope in
                        let selected = book.tropes.contains(trope)
                        Button {
                            if selected {
                                book.tropes.removeAll { $0 == trope }
                            } else {
                                book.tropes.append(trope)
                            }
                            store.updateBook(book)
                        } label: {
                            Text(trope)
                                .font(.system(size: 12, weight: selected ? .semibold : .regular))
                                .foregroundStyle(selected ? .black : NovelyTheme.creamText)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 7)
                                .background(
                                    selected ? NovelyTheme.warmGold : Color.white.opacity(0.08),
                                    in: Capsule()
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(16)
        .novelyGlassCard(cornerRadius: 20)
    }

    private var editionAndLendingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Mein Exemplar & Verliehen")
                .font(.system(size: 16, weight: .semibold, design: .serif))
                .foregroundStyle(NovelyTheme.creamText)

            Toggle("Signierte Ausgabe", isOn: $book.isSignedEdition)
                .tint(NovelyTheme.terracotta)
            Toggle("Sonderausgabe / Farbschnitt", isOn: $book.isSpecialEdition)
                .tint(NovelyTheme.terracotta)

            HStack {
                Text("Verliehen an")
                    .font(.system(size: 14))
                    .foregroundStyle(NovelyTheme.warmMutedText)
                TextField("Name (optional)", text: Binding(
                    get: { book.lentTo ?? "" },
                    set: {
                        book.lentTo = $0.isEmpty ? nil : $0
                        if !$0.isEmpty { book.lentDate = book.lentDate ?? Date() }
                    }
                ))
                .multilineTextAlignment(.trailing)
                .foregroundStyle(NovelyTheme.creamText)
            }
        }
        .padding(16)
        .novelyGlassCard(cornerRadius: 20)
    }

    private var quotesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Zitate & Notizen")
                    .font(.system(size: 16, weight: .semibold, design: .serif))
                    .foregroundStyle(NovelyTheme.creamText)
                Spacer()
                Button {
                    showingQuoteScanner = true
                } label: {
                    Label("Scannen", systemImage: "text.viewfinder")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(NovelyTheme.warmGold)
                }
            }

            HStack(spacing: 8) {
                TextField("Lieblingszitat eintippen...", text: $newQuoteText)
                    .font(.system(size: 14))
                    .padding(10)
                    .background(Color.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 12))
                Button {
                    guard !newQuoteText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                    let q = BookQuote(text: newQuoteText, pageNumber: Int(newQuotePage))
                    book.quotes.insert(q, at: 0)
                    store.updateBook(book)
                    newQuoteText = ""
                    newQuotePage = ""
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 26))
                        .foregroundStyle(NovelyTheme.terracotta)
                }
            }

            ForEach(book.quotes) { quote in
                VStack(alignment: .leading, spacing: 6) {
                    Text("„\(quote.text)“")
                        .font(.system(size: 15, weight: .regular, design: .serif))
                        .italic()
                        .foregroundStyle(NovelyTheme.creamText)
                    if let page = quote.pageNumber {
                        Text("Seite \(page)")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(NovelyTheme.warmMutedText)
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 14))
            }
        }
        .padding(16)
        .novelyGlassCard(cornerRadius: 20)
    }

    private func starImage(for index: Int) -> String {
        if book.rating >= Double(index) {
            return "star.fill"
        } else if book.rating >= Double(index) - 0.5 {
            return "star.leadinghalf.filled"
        }
        return "star"
    }
}
