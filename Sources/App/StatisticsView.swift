import SwiftUI

struct StatisticsView: View {
    @EnvironmentObject private var store: LibraryStore
    @State private var displayedMonth = Date()

    private let weekdayHeaders = ["M", "D", "M", "D", "F", "S", "S"]

    private var monthTitle: String {
        let df = DateFormatter()
        df.locale = Locale(identifier: "de_DE")
        df.dateFormat = "MMMM"
        return df.string(from: displayedMonth)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                NovelyTheme.espressoBg.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 22) {
                        // 1. Streak & Reading Goal Hero Card (Novely Screenshot #6)
                        streakHeroCard

                        // 2. Book-Cover Reading Calendar (Novely Screenshot #5)
                        readingCalendarCard

                        // 3. Yearly Reading Goal Progress
                        yearlyGoalCard

                        // 4. "Was ist dein Regal wert?" Receipt Card
                        shelfValueReceiptCard

                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 10)
                }
            }
            .navigationTitle("Statistik")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Streak Hero Card (Exact Novely Screenshot #6 Vibe)

    private var streakHeroCard: some View {
        let streak = store.currentStreakDays
        let weekDots = store.weekReadingActivity()
        let todayPages = store.pagesReadToday
        let todayBook = store.lastBookReadToday

        return ZStack {
            RadialGradient(
                colors: [
                    NovelyTheme.terracotta.opacity(0.32),
                    Color(hex: "#181310")
                ],
                center: .center,
                startRadius: 15,
                endRadius: 190
            )

            VStack(spacing: 12) {
                Text("NEUER REKORD")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(2.0)
                    .foregroundStyle(NovelyTheme.terracotta)

                Text("\(streak)")
                    .font(.system(size: 74, weight: .bold, design: .serif))
                    .foregroundStyle(NovelyTheme.creamText)
                    .padding(.vertical, -8)

                Text("Lesetage in Folge")
                    .font(.system(size: 18, weight: .regular, design: .serif))
                    .italic()
                    .foregroundStyle(NovelyTheme.creamText.opacity(0.9))

                // 7-day M D M D F S S dots
                HStack(spacing: 14) {
                    ForEach(0..<7, id: \.self) { idx in
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
                .padding(.top, 8)

                if let book = todayBook, todayPages > 0 {
                    HStack(spacing: 10) {
                        BookCoverForwardView(book: book, scale: 0.25)
                        Text("+\(todayPages) Seiten heute in „\(book.title)“")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(NovelyTheme.creamText)
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .novelyGlassCapsule()
                    .padding(.top, 6)
                }
            }
            .padding(.vertical, 26)
            .padding(.horizontal, 16)
        }
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
        )
    }

    // MARK: - Monthly Reading Calendar with Book Covers (Novely Screenshot #5)

    private var readingCalendarCard: some View {
        let days = calendarDays(for: displayedMonth)
        return VStack(spacing: 14) {
            HStack {
                Button {
                    if let prev = Calendar.current.date(byAdding: .month, value: -1, to: displayedMonth) {
                        displayedMonth = prev
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .foregroundStyle(NovelyTheme.warmMutedText)
                        .padding(6)
                }
                Spacer()
                Text(monthTitle)
                    .font(.system(size: 24, weight: .regular, design: .serif))
                    .italic()
                    .foregroundStyle(NovelyTheme.creamText)
                Spacer()
                Button {
                    if let next = Calendar.current.date(byAdding: .month, value: 1, to: displayedMonth) {
                        displayedMonth = next
                    }
                } label: {
                    Image(systemName: "chevron.right")
                        .foregroundStyle(NovelyTheme.warmMutedText)
                        .padding(6)
                }
            }

            // Weekday labels
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 7), spacing: 8) {
                ForEach(0..<7, id: \.self) { idx in
                    Text(weekdayHeaders[idx])
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(NovelyTheme.warmMutedText)
                }

                ForEach(Array(days.enumerated()), id: \.offset) { _, dateOpt in
                    if let date = dateOpt {
                        let dayNum = Calendar.current.component(.day, from: date)
                        if let book = store.bookForCalendarDay(date) {
                            ZStack(alignment: .bottomTrailing) {
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .fill(Color(hex: book.spineColorHex))
                                    .overlay(
                                        VStack(spacing: 2) {
                                            Text(book.title)
                                                .font(.system(size: 6.5, weight: .bold, design: .serif))
                                                .foregroundStyle(Color(hex: book.spineTextColorHex))
                                                .multilineTextAlignment(.center)
                                                .lineLimit(2)
                                                .padding(.horizontal, 2)
                                        }
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6)
                                            .strokeBorder(Color(hex: book.spineAccentHex).opacity(0.65), lineWidth: 0.8)
                                    )

                                Text("\(dayNum)")
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 3)
                                    .padding(.vertical, 1)
                                    .background(.black.opacity(0.55), in: Capsule())
                                    .padding(2)
                            }
                            .frame(height: 54)
                        } else {
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(Color.white.opacity(0.04))
                                .frame(height: 54)
                                .overlay(
                                    Text("\(dayNum)")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundStyle(NovelyTheme.warmMutedText.opacity(0.55))
                                )
                        }
                    } else {
                        Color.clear.frame(height: 54)
                    }
                }
            }
        }
        .padding(16)
        .novelyGlassCard(cornerRadius: 24)
    }

    // MARK: - Yearly Reading Goal Card

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

            ProgressView(value: ratio)
                .tint(NovelyTheme.terracotta)

            Text("\(Int(ratio * 100))% erreicht · \(store.totalReadPages) Seiten insgesamt gelesen")
                .font(.system(size: 12))
                .foregroundStyle(NovelyTheme.warmMutedText)
        }
        .padding(16)
        .novelyGlassCard(cornerRadius: 20)
    }

    // MARK: - "Was ist dein Regal wert?" Receipt Card

    private var shelfValueReceiptCard: some View {
        let avgRatingBooks = store.books.filter { $0.rating > 0 }
        let avgRating = avgRatingBooks.isEmpty ? 0 : avgRatingBooks.map(\.rating).reduce(0, +) / Double(avgRatingBooks.count)

        return VStack(spacing: 12) {
            Text("WAS IST DEIN REGAL WERT?")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .tracking(1.6)
                .foregroundStyle(NovelyTheme.warmGold)

            Text(String(format: "%.2f €", store.totalShelfValue))
                .font(.system(size: 36, weight: .bold, design: .serif))
                .foregroundStyle(NovelyTheme.creamText)

            Divider().background(Color.white.opacity(0.15))

            HStack {
                receiptStat("Bücher gesamt", "\(store.books.count)")
                Spacer()
                receiptStat("Ø Bewertung", String(format: "%.1f ★", avgRating))
                Spacer()
                receiptStat("Zitate", "\(store.allQuotesWithBook.count)")
            }
        }
        .padding(18)
        .novelyGlassCard(cornerRadius: 22)
    }

    private func receiptStat(_ label: String, _ value: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 16, weight: .bold, design: .serif))
                .foregroundStyle(NovelyTheme.creamText)
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(NovelyTheme.warmMutedText)
        }
    }

    // MARK: - Calendar Helper

    private func calendarDays(for monthDate: Date) -> [Date?] {
        let cal = Calendar.current
        guard let range = cal.range(of: .day, in: .month, for: monthDate),
              let firstOfMonth = cal.date(from: cal.dateComponents([.year, .month], from: monthDate)) else {
            return []
        }
        let weekday = cal.component(.weekday, from: firstOfMonth) // 1=Sun, 2=Mon
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
