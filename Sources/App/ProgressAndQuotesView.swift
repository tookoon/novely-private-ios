import SwiftUI

struct ProgressAndQuotesView: View {
    @EnvironmentObject private var store: LibraryStore
    @State private var displayedMonth = Date()
    @State private var quickLogBook: Book?
    @State private var showingQuoteScanner = false

    private var monthFormatter: DateFormatter {
        let df = DateFormatter()
        df.locale = Locale(identifier: "de_DE")
        df.dateFormat = "MMMM"
        return df
    }

    private var yearFormatter: DateFormatter {
        let df = DateFormatter()
        df.dateFormat = "yyyy"
        return df
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [
                        Color(hex: store.settings.wallTheme.topHex),
                        NovelyTheme.espressoBg
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 22) {
                        monthlySummaryCard
                        currentlyReadingSection
                        quotesSection
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 12)
                }
            }
            .navigationTitle("Fortschritt")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingQuoteScanner = true
                    } label: {
                        Image(systemName: "text.viewfinder")
                            .foregroundStyle(NovelyTheme.creamText)
                    }
                }
            }
            .sheet(item: $quickLogBook) { book in
                QuickProgressSheet(book: book)
                    .environmentObject(store)
                    .presentationDetents([.medium])
            }
            .sheet(isPresented: $showingQuoteScanner) {
                QuoteOCRScannerView(book: store.currentlyReadingBooks.first ?? store.books.first) { quote, page in
                    if let target = store.currentlyReadingBooks.first ?? store.books.first {
                        store.addQuote(to: target.id, text: quote, pageNumber: page)
                    }
                }
            }
        }
    }

    // MARK: - Monthly Summary Card (Novely Screenshot #4 aesthetic)

    private var monthlySummaryCard: some View {
        let stats = store.monthlyStats(for: displayedMonth)
        return VStack(spacing: 16) {
            HStack {
                Button {
                    if let prev = Calendar.current.date(byAdding: .month, value: -1, to: displayedMonth) {
                        displayedMonth = prev
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(NovelyTheme.warmMutedText)
                        .padding(8)
                }

                Spacer()

                VStack(spacing: 2) {
                    Text(monthFormatter.string(from: displayedMonth))
                        .font(.system(size: 26, weight: .regular, design: .serif))
                        .italic()
                        .foregroundStyle(NovelyTheme.creamText)
                    Text(yearFormatter.string(from: displayedMonth))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(NovelyTheme.warmMutedText)
                }

                Spacer()

                Button {
                    if let next = Calendar.current.date(byAdding: .month, value: 1, to: displayedMonth) {
                        displayedMonth = next
                    }
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(NovelyTheme.warmMutedText)
                        .padding(8)
                }
            }

            HStack(spacing: 0) {
                metricColumn(value: "\(stats.booksCount)", label: "Bücher")
                Divider().frame(height: 36).background(Color.white.opacity(0.15))
                metricColumn(value: formattedNumber(stats.pagesCount), label: "Seiten")
                Divider().frame(height: 36).background(Color.white.opacity(0.15))
                metricColumn(value: "\(stats.readingDays)", label: "Lesetage")
            }
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 16)
        .novelyGlassCard(cornerRadius: 24)
    }

    private func metricColumn(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 28, weight: .semibold, design: .serif))
                .foregroundStyle(NovelyTheme.creamText)
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(NovelyTheme.warmMutedText)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Currently Reading Cards

    private var currentlyReadingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Liest du gerade")
                .font(.system(size: 20, weight: .semibold, design: .serif))
                .foregroundStyle(NovelyTheme.creamText)

            if store.currentlyReadingBooks.isEmpty {
                Text("Tippe im Regal auf ein Buch und setze es auf „Aktuell“, um deinen Fortschritt hier zu tracken.")
                    .font(.system(size: 14))
                    .foregroundStyle(NovelyTheme.warmMutedText)
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .novelyGlassCard(cornerRadius: 18)
            } else {
                ForEach(store.currentlyReadingBooks) { book in
                    HStack(spacing: 14) {
                        BookCoverForwardView(book: book, scale: 0.62)

                        VStack(alignment: .leading, spacing: 6) {
                            Text(book.title)
                                .font(.system(size: 17, weight: .bold, design: .serif))
                                .foregroundStyle(NovelyTheme.creamText)
                                .lineLimit(2)

                            Text(book.author)
                                .font(.system(size: 13))
                                .foregroundStyle(NovelyTheme.warmMutedText)

                            Text("Seite \(book.currentPage) von \(book.pageCount)")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(NovelyTheme.warmGold)

                            ProgressView(value: book.progress)
                                .tint(NovelyTheme.terracotta)
                                .padding(.top, 2)

                            HStack {
                                Spacer()
                                Button {
                                    quickLogBook = book
                                } label: {
                                    Text("Fortschritt")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(.black)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 7)
                                        .background(NovelyTheme.creamText, in: Capsule())
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.top, 4)
                        }
                    }
                    .padding(14)
                    .novelyGlassCard(cornerRadius: 20)
                }
            }
        }
    }

    // MARK: - Quotes Section

    private var quotesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Deine Zitate")
                    .font(.system(size: 20, weight: .semibold, design: .serif))
                    .foregroundStyle(NovelyTheme.creamText)
                Spacer()
                Button {
                    showingQuoteScanner = true
                } label: {
                    Label("OCR-Scan", systemImage: "text.viewfinder")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(NovelyTheme.warmGold)
                }
            }

            ForEach(Array(store.allQuotesWithBook.prefix(5)), id: \.1.id) { book, quote in
                VStack(alignment: .leading, spacing: 8) {
                    Text("„\(quote.text)“")
                        .font(.system(size: 16, weight: .regular, design: .serif))
                        .italic()
                        .foregroundStyle(NovelyTheme.creamText)

                    HStack {
                        Text("\(book.title) — \(book.author)")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(NovelyTheme.warmMutedText)
                        Spacer()
                        if let page = quote.pageNumber {
                            Text("S. \(page)")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(NovelyTheme.warmGold)
                        }
                    }
                }
                .padding(16)
                .novelyGlassCard(cornerRadius: 18)
            }
        }
    }

    private func formattedNumber(_ value: Int) -> String {
        let nf = NumberFormatter()
        nf.numberStyle = .decimal
        nf.locale = Locale(identifier: "de_DE")
        return nf.string(from: NSNumber(value: value)) ?? "\(value)"
    }
}

// MARK: - Quick Progress Logger Sheet

struct QuickProgressSheet: View {
    @EnvironmentObject private var store: LibraryStore
    @Environment(\.dismiss) private var dismiss

    let book: Book
    @State private var currentPage: Double

    init(book: Book) {
        self.book = book
        _currentPage = State(initialValue: Double(book.currentPage))
    }

    var body: some View {
        ZStack {
            NovelyTheme.espressoBg.ignoresSafeArea()
            VStack(spacing: 20) {
                Capsule()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 40, height: 4)
                    .padding(.top, 10)

                Text(book.title)
                    .font(.system(size: 22, weight: .bold, design: .serif))
                    .foregroundStyle(NovelyTheme.creamText)

                Text("Seite \(Int(currentPage)) von \(book.pageCount)")
                    .font(.system(size: 32, weight: .bold, design: .serif))
                    .foregroundStyle(NovelyTheme.warmGold)

                Slider(value: $currentPage, in: 0...Double(max(1, book.pageCount)), step: 1)
                    .tint(NovelyTheme.terracotta)
                    .padding(.horizontal, 24)

                HStack(spacing: 12) {
                    ForEach([10, 25, 50], id: \.self) { delta in
                        Button("+\(delta) S.") {
                            currentPage = min(Double(book.pageCount), currentPage + Double(delta))
                        }
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(NovelyTheme.creamText)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 9)
                        .novelyGlassCapsule()
                    }
                }

                Spacer()

                Button {
                    store.logProgress(for: book.id, newPage: Int(currentPage))
                    dismiss()
                } label: {
                    Text("Fortschritt speichern")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(NovelyTheme.creamText, in: Capsule())
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
            }
        }
    }
}
