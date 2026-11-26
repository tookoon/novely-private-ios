import SwiftUI

struct StatisticsView: View {
    @EnvironmentObject private var store: LibraryStore
    @State private var displayedMonth = Date()
    @State private var renderedRecapImage: Image?

    private let weekdayHeaders = ["M", "D", "M", "D", "F", "S", "S"]

    private var monthTitle: String {
        let df = DateFormatter()
        df.locale = Locale(identifier: "de_DE")
        df.dateFormat = "MMMM"
        return df.string(from: displayedMonth)
    }

    private var yearTitle: String {
        let df = DateFormatter()
        df.dateFormat = "yyyy"
        return df.string(from: displayedMonth)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color(hex: "#291E17"), NovelyTheme.espressoBg],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // 1. Monthly Summary + Book-Cover Reading Calendar + "Monat teilen" (Exact Reel 1 & 2!)
                        readingCalendarCard

                        // 2. Streak Hero Card
                        streakHeroCard

                        // 3. Yearly Goal Card
                        yearlyGoalCard

                        // 4. "Was ist dein Regal wert?" Receipt Card
                        shelfValueReceiptCard

                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                }
            }
            .navigationTitle("Statistik")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Monthly Summary + Real Book-Cover Calendar (Exact Reel 1 & 2!)

    private var readingCalendarCard: some View {
        let stats = store.monthlyStats(for: displayedMonth)
        let days = calendarDays(for: displayedMonth)
        let cal = Calendar.current

        return VStack(spacing: 16) {
            HStack {
                Button {
                    if let prev = cal.date(byAdding: .month, value: -1, to: displayedMonth) {
                        displayedMonth = prev
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .foregroundStyle(NovelyTheme.warmMutedText)
                        .padding(6)
                }
                Spacer()
                VStack(spacing: 2) {
                    Text(monthTitle)
                        .font(.system(size: 26, weight: .regular, design: .serif))
                        .italic()
                        .foregroundStyle(NovelyTheme.creamText)
                    Text(yearTitle)
                        .font(.system(size: 11.5, weight: .medium))
                        .foregroundStyle(NovelyTheme.warmMutedText)
                }
                Spacer()
                Button {
                    if let next = cal.date(byAdding: .month, value: 1, to: displayedMonth) {
                        displayedMonth = next
                    }
                } label: {
                    Image(systemName: "chevron.right")
                        .foregroundStyle(NovelyTheme.warmMutedText)
                        .padding(6)
                }
            }

            HStack(spacing: 0) {
                metricColumn(value: "\(stats.booksCount)", label: "Bücher")
                Divider().frame(height: 32).background(Color.white.opacity(0.15))
                metricColumn(value: formattedNumber(stats.pagesCount), label: "Seiten")
                Divider().frame(height: 32).background(Color.white.opacity(0.15))
                metricColumn(value: "\(stats.readingDays)", label: "Lesetage")
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 7), spacing: 8) {
                ForEach(0..<7, id: \.self) { idx in
                    Text(weekdayHeaders[idx])
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(NovelyTheme.warmMutedText)
                }

                ForEach(Array(days.enumerated()), id: \.offset) { _, dateOpt in
                    if let date = dateOpt {
                        let dayNum = cal.component(.day, from: date)
                        let isToday = cal.isDateInToday(date)
                        if let book = store.bookForCalendarDay(date) {
                            ZStack(alignment: .bottomTrailing) {
                                BookCoverForwardView(book: book, scale: 0.34)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 54)
                                    .clipShape(RoundedRectangle(cornerRadius: 6))

                                Text("\(dayNum)")
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 3.5)
                                    .padding(.vertical, 1)
                                    .background(.black.opacity(0.6), in: Capsule())
                                    .padding(2)
                            }
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .strokeBorder(isToday ? NovelyTheme.terracotta : .clear, lineWidth: 1.8)
                            )
                        } else {
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(Color.white.opacity(0.04))
                                .frame(height: 54)
                                .overlay(
                                    Text("\(dayNum)")
                                        .font(.system(size: 12, weight: isToday ? .bold : .medium))
                                        .foregroundStyle(isToday ? NovelyTheme.creamText : NovelyTheme.warmMutedText.opacity(0.55))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .strokeBorder(isToday ? NovelyTheme.terracotta : .clear, lineWidth: 1.8)
                                )
                        }
                    } else {
                        Color.clear.frame(height: 54)
                    }
                }
            }

            // "Monat teilen" Story Recap ShareLink (Reel 1!)
            let recapText = "Mein Lesemonat \(monthTitle) \(yearTitle): \(stats.booksCount) Bücher · \(formattedNumber(stats.pagesCount)) Seiten · \(stats.readingDays) Lesetage · \(store.currentStreakDays) Tage Streak 📚✨"
            HStack {
                Spacer()
                ShareLink(item: recapText) {
                    Label("Monat teilen", systemImage: "square.and.arrow.up")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(NovelyTheme.creamText)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .novelyGlassCapsule()
                }
            }
        }
        .padding(16)
        .novelyGlassCard(cornerRadius: 24)
    }

    private func metricColumn(value: String, label: String) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.system(size: 26, weight: .semibold, design: .serif))
                .foregroundStyle(NovelyTheme.creamText)
            Text(label)
                .font(.system(size: 11.5, weight: .medium))
                .foregroundStyle(NovelyTheme.warmMutedText)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Streak Hero Card

    private var streakHeroCard: some View {
        let streak = store.currentStreakDays
        let weekDots = store.weekReadingActivity()
        let todayPages = store.pagesReadToday
        let todayBook = store.lastBookReadToday

        return ZStack {
            RadialGradient(
                colors: [NovelyTheme.terracotta.opacity(0.32), Color(hex: "#181310")],
                center: .center,
                startRadius: 15,
                endRadius: 190
            )

            VStack(spacing: 10) {
                Text("NEUER REKORD")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(2.0)
                    .foregroundStyle(NovelyTheme.terracotta)

                Text("\(streak)")
                    .font(.system(size: 68, weight: .bold, design: .serif))
                    .foregroundStyle(NovelyTheme.creamText)
                    .padding(.vertical, -8)

                Text("Lesetage in Folge")
                    .font(.system(size: 17, weight: .regular, design: .serif))
                    .italic()
                    .foregroundStyle(NovelyTheme.creamText.opacity(0.9))

                HStack(spacing: 14) {
                    ForEach(0..<min(7, weekDots.count), id: \.self) { idx in
                        VStack(spacing: 6) {
                            Text(weekdayHeaders[idx])
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(NovelyTheme.warmMutedText)
                            Circle()
                                .fill(weekDots[idx] ? NovelyTheme.terracotta : Color.white.opacity(0.14))
                                .frame(width: 11, height: 11)
                                .shadow(color: weekDots[idx] ? NovelyTheme.terracotta.opacity(0.7) : .clear, radius: 4)
                        }
                    }
                }
                .padding(.top, 6)

                if let book = todayBook, todayPages > 0 {
                    HStack(spacing: 10) {
                        BookCoverForwardView(book: book, scale: 0.24)
                        Text("+\(todayPages) Seiten heute in „\(book.title)“")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(NovelyTheme.creamText)
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .novelyGlassCapsule()
                    .padding(.top, 4)
                }
            }
            .padding(.vertical, 24)
            .padding(.horizontal, 16)
        }
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
        )
    }

    // MARK: - Yearly Goal & Shelf Value Receipt

    private var yearlyGoalCard: some View {
        let readCount = store.books(for: .read).count
        let goal = max(1, store.settings.yearlyBookGoal)
        let ratio = min(1.0, Double(readCount) / Double(goal))

        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Jahresziel 2026")
                    .font(.system(size: 18, weight: .semibold, design: .serif))
                    .foregroundStyle(NovelyTheme.creamText)
                Spacer()
                Text("\(readCount) / \(goal) Bücher")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(NovelyTheme.warmGold)
            }

            ProgressView(value: ratio).tint(NovelyTheme.terracotta)

            Text("\(Int(ratio * 100))% erreicht · \(formattedNumber(store.totalReadPages)) Seiten · Ø \(Int(store.pagesPerHour)) S./Std.")
                .font(.system(size: 12))
                .foregroundStyle(NovelyTheme.warmMutedText)
        }
        .padding(16)
        .novelyGlassCard(cornerRadius: 20)
    }

    private var shelfValueReceiptCard: some View {
        let avgRatingBooks = store.books.filter { $0.rating > 0 }
        let avgRating = avgRatingBooks.isEmpty ? 0 : avgRatingBooks.map(\.rating).reduce(0, +) / Double(avgRatingBooks.count)

        return VStack(spacing: 12) {
            Text("WAS IST DEIN REGAL WERT?")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .tracking(1.6)
                .foregroundStyle(NovelyTheme.warmGold)

            Text(String(format: "%.2f €", store.totalShelfValue))
                .font(.system(size: 34, weight: .bold, design: .serif))
                .foregroundStyle(NovelyTheme.creamText)

            Divider().background(Color.white.opacity(0.15))

            HStack {
                receiptStat("Bücher", "\(store.books.count)")
                Spacer()
                receiptStat("Ø Bewertung", String(format: "%.1f ★", avgRating))
                Spacer()
                receiptStat("Pflanze", "Stufe \(store.plantGrowthStage)/5")
            }
        }
        .padding(18)
        .novelyGlassCard(cornerRadius: 22)
    }

    private func receiptStat(_ label: String, _ value: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 15.5, weight: .bold, design: .serif))
                .foregroundStyle(NovelyTheme.creamText)
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(NovelyTheme.warmMutedText)
        }
    }

    private func formattedNumber(_ value: Int) -> String {
        let nf = NumberFormatter()
        nf.numberStyle = .decimal
        nf.locale = Locale(identifier: "de_DE")
        return nf.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    private func calendarDays(for monthDate: Date) -> [Date?] {
        let cal = Calendar.current
        guard let range = cal.range(of: .day, in: .month, for: monthDate),
              let firstOfMonth = cal.date(from: cal.dateComponents([.year, .month], from: monthDate)) else {
            return []
        }
        let weekday = cal.component(.weekday, from: firstOfMonth)
        let leadingBlanks = (weekday + 5) % 7
        var result: [Date?] = Array(repeating: nil, count: leadingBlanks)
        for day in range {
            if let d = cal.date(byAdding: .day, value: day - 1, to: firstOfMonth) {
                result.append(d)
            }
        }
        return result
    }
}
