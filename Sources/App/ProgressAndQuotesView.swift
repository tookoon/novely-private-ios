import SwiftUI

struct ProgressAndQuotesView: View {
    @EnvironmentObject private var store: LibraryStore
    var onStartReadingBook: ((Book) -> Void)?

    @State private var quickLogBook: Book?
    @State private var showingQuoteScanner = false
    @State private var showingGoalSheet = false

    private let weekdayHeaders = ["M", "D", "M", "D", "F", "S", "S"]

    private var monthName: String {
        let df = DateFormatter()
        df.locale = Locale(identifier: "de_DE")
        df.dateFormat = "MMMM"
        return df.string(from: Date())
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color(hex: "#2B1F18"), NovelyTheme.espressoBg],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        // 1. Weekly Book-Cover Strip + Streak + Daily Goal (exact Reel 1 & 2!)
                        weekOverviewCard

                        // 2. Currently Reading Cards with "Fortschritt" + "Lesen starten"
                        currentlyReadingSection

                        // 3. Lesetagebuch (Reading Diary / Past Sessions like Reel 1!)
                        readingDiarySection

                        // 4. Quotes Section
                        quotesSection

                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                }
            }
            .navigationTitle("Lesen")
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
            .sheet(isPresented: $showingGoalSheet) {
                DailyGoalEditorSheet()
                    .environmentObject(store)
                    .presentationDetents([.height(340)])
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

    // MARK: - Weekly Strip + Streak + Daily Goal (Exact Reel 1 & 2 Top Card)

    private var weekOverviewCard: some View {
        let weekDates = store.currentWeekDates()
        let cal = Calendar.current
        let goalValue = store.settings.dailyGoalMode == .pages ? store.settings.dailyPagesGoal : store.settings.dailyMinutesGoal
        let currentValue = store.settings.dailyGoalMode == .pages ? store.pagesReadToday : store.minutesReadToday
        let remaining = max(0, goalValue - currentValue)

        return VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(monthName)
                    .font(.system(size: 22, weight: .bold, design: .serif))
                    .foregroundStyle(NovelyTheme.creamText)
                Spacer()
                HStack(spacing: 5) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(NovelyTheme.terracotta)
                    Text("\(store.currentStreakDays) Lesetage in Folge")
                        .font(.system(size: 12.5, weight: .semibold))
                        .foregroundStyle(NovelyTheme.creamText)
                }
            }

            // 7-day M D M D F S S grid with real book covers!
            HStack(spacing: 6) {
                ForEach(Array(weekDates.enumerated()), id: \.offset) { idx, date in
                    let isToday = cal.isDateInToday(date)
                    let dayNum = cal.component(.day, from: date)
                    let dayBook = store.bookForCalendarDay(date)

                    VStack(spacing: 5) {
                        Text(weekdayHeaders[idx])
                            .font(.system(size: 10.5, weight: .semibold))
                            .foregroundStyle(isToday ? NovelyTheme.terracotta : NovelyTheme.warmMutedText)

                        ZStack {
                            if let book = dayBook {
                                BookCoverForwardView(book: book, scale: 0.30)
                                    .frame(width: 36, height: 48)
                                    .clipShape(RoundedRectangle(cornerRadius: 7))
                            } else {
                                RoundedRectangle(cornerRadius: 7)
                                    .fill(Color.white.opacity(0.06))
                                    .frame(width: 36, height: 48)
                                Text("\(dayNum)")
                                    .font(.system(size: 12, weight: isToday ? .bold : .medium))
                                    .foregroundStyle(isToday ? NovelyTheme.creamText : NovelyTheme.warmMutedText)
                            }
                        }
                        .overlay(
                            RoundedRectangle(cornerRadius: 7)
                                .strokeBorder(isToday ? NovelyTheme.terracotta : .clear, lineWidth: 1.8)
                        )
                    }
                    .frame(maxWidth: .infinity)
                }
            }

            Divider().background(Color.white.opacity(0.12))

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    if remaining == 0 {
                        Text("Tagesziel erreicht! 🎉")
                            .font(.system(size: 13.5, weight: .semibold))
                            .foregroundStyle(Color(hex: "#8CE99A"))
                    } else {
                        Text("Noch \(remaining) \(store.settings.dailyGoalMode.rawValue) bis zu deinem Tagesziel")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(NovelyTheme.creamText)
                    }
                    Text("\(currentValue) / \(goalValue) \(store.settings.dailyGoalMode.rawValue) heute")
                        .font(.system(size: 11.5))
                        .foregroundStyle(NovelyTheme.warmMutedText)
                }
                Spacer()
                Button {
                    showingGoalSheet = true
                } label: {
                    Text("Tagesziel")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(NovelyTheme.creamText)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .novelyGlassCapsule()
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .novelyGlassCard(cornerRadius: 22)
    }

    // MARK: - Currently Reading Cards ("Fortschritt" + "Lesen starten")

    private var currentlyReadingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Liest du gerade")
                .font(.system(size: 20, weight: .semibold, design: .serif))
                .foregroundStyle(NovelyTheme.creamText)

            if store.currentlyReadingBooks.isEmpty {
                Text("Tippe im Regal auf ein Buch und setze es auf „Aktuell“, um es hier zu tracken.")
                    .font(.system(size: 14))
                    .foregroundStyle(NovelyTheme.warmMutedText)
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .novelyGlassCard(cornerRadius: 18)
            } else {
                ForEach(store.currentlyReadingBooks) { book in
                    VStack(spacing: 12) {
                        HStack(spacing: 14) {
                            BookCoverForwardView(book: book, scale: 0.60)

                            VStack(alignment: .leading, spacing: 5) {
                                Text(book.title)
                                    .font(.system(size: 17, weight: .bold, design: .serif))
                                    .foregroundStyle(NovelyTheme.creamText)
                                    .lineLimit(2)

                                Text(book.author)
                                    .font(.system(size: 13))
                                    .foregroundStyle(NovelyTheme.warmMutedText)

                                Text("Seite \(book.currentPage) von \(book.pageCount) · \(store.estimatedRemainingTimeString(for: book))")
                                    .font(.system(size: 11.5, weight: .medium))
                                    .foregroundStyle(NovelyTheme.warmGold)

                                ProgressView(value: book.progress)
                                    .tint(NovelyTheme.terracotta)
                                    .padding(.top, 2)
                            }
                        }

                        HStack(spacing: 10) {
                            Button {
                                quickLogBook = book
                            } label: {
                                Text("Fortschritt")
                                    .font(.system(size: 13.5, weight: .semibold))
                                    .foregroundStyle(NovelyTheme.creamText)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .novelyGlassCapsule()
                            }
                            .buttonStyle(.plain)

                            Button {
                                onStartReadingBook?(book)
                            } label: {
                                Text("Lesen starten")
                                    .font(.system(size: 13.5, weight: .semibold))
                                    .foregroundStyle(.black)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(NovelyTheme.creamText, in: Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(14)
                    .novelyGlassCard(cornerRadius: 20)
                }
            }
        }
    }

    // MARK: - Lesetagebuch (Tagebuch from Reel 1!)

    private var readingDiarySection: some View {
        let df = DateFormatter()
        df.dateFormat = "dd.MM."

        return VStack(alignment: .leading, spacing: 10) {
            Text("Tagebuch")
                .font(.system(size: 20, weight: .semibold, design: .serif))
                .foregroundStyle(NovelyTheme.creamText)

            if store.sortedSessions.isEmpty {
                Text("Jede Lesesession und jeder Fortschritt, den du einträgst, landet hier.")
                    .font(.system(size: 13.5))
                    .foregroundStyle(NovelyTheme.warmMutedText)
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .novelyGlassCard(cornerRadius: 16)
            } else {
                VStack(spacing: 8) {
                    ForEach(Array(store.sortedSessions.prefix(6))) { session in
                        if let book = store.books.first(where: { $0.id == session.bookId }) {
                            HStack(spacing: 12) {
                                Text(df.string(from: session.date))
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(NovelyTheme.warmMutedText)
                                    .frame(width: 42, alignment: .leading)

                                BookCoverForwardView(book: book, scale: 0.24)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(book.title)
                                        .font(.system(size: 14, weight: .semibold, design: .serif))
                                        .foregroundStyle(NovelyTheme.creamText)
                                        .lineLimit(1)
                                    Text("\(max(1, session.durationSeconds / 60)) Minuten · +\(session.pagesRead) Seiten")
                                        .font(.system(size: 12))
                                        .foregroundStyle(NovelyTheme.warmMutedText)
                                }
                                Spacer()
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 9)
                            .novelyGlassCard(cornerRadius: 15)
                        }
                    }
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

            ForEach(Array(store.allQuotesWithBook.prefix(4)), id: \.1.id) { book, quote in
                VStack(alignment: .leading, spacing: 8) {
                    Text("„\(quote.text)“")
                        .font(.system(size: 15.5, weight: .regular, design: .serif))
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
                .padding(14)
                .novelyGlassCard(cornerRadius: 18)
            }
        }
    }
}

// MARK: - Daily Goal Editor Sheet (Pages or Minutes like Reel 2!)

struct DailyGoalEditorSheet: View {
    @EnvironmentObject private var store: LibraryStore
    @Environment(\.dismiss) private var dismiss

    @State private var mode: DailyGoalMode = .pages
    @State private var value: Double = 30

    var body: some View {
        ZStack {
            NovelyTheme.espressoBg.ignoresSafeArea()
            VStack(spacing: 18) {
                Text("Tagesziel")
                    .font(.system(size: 22, weight: .bold, design: .serif))
                    .foregroundStyle(NovelyTheme.creamText)
                    .padding(.top, 14)

                Picker("Modus", selection: $mode) {
                    ForEach(DailyGoalMode.allCases) { m in
                        Text(m.rawValue).tag(m)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 36)

                VStack(spacing: 4) {
                    Text("\(Int(value))")
                        .font(.system(size: 44, weight: .bold, design: .serif))
                        .foregroundStyle(NovelyTheme.creamText)
                    Text(mode.rawValue)
                        .font(.system(size: 13))
                        .foregroundStyle(NovelyTheme.warmMutedText)
                }

                Slider(value: $value, in: 5...150, step: 5)
                    .tint(NovelyTheme.terracotta)
                    .padding(.horizontal, 28)

                Button {
                    store.settings.dailyGoalMode = mode
                    if mode == .pages {
                        store.settings.dailyPagesGoal = Int(value)
                    } else {
                        store.settings.dailyMinutesGoal = Int(value)
                    }
                    store.persist()
                    dismiss()
                } label: {
                    Text("Speichern")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(NovelyTheme.creamText, in: Capsule())
                }
                .padding(.horizontal, 24)
            }
        }
        .onAppear {
            mode = store.settings.dailyGoalMode
            value = Double(mode == .pages ? store.settings.dailyPagesGoal : store.settings.dailyMinutesGoal)
        }
        .onChange(of: mode) { _, newMode in
            value = Double(newMode == .pages ? store.settings.dailyPagesGoal : store.settings.dailyMinutesGoal)
        }
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
