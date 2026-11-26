import Foundation
import SwiftUI
import WidgetKit

// MARK: - Shared App Group & Local Storage

public enum LibraryStorage {
    public static let appGroupID = "group.com.novelyprivate.app"
    private static let fileName = "novely_library_v2.json"

    public static var containerURL: URL {
        if let groupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) {
            return groupURL
        }
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }

    public static var snapshotURL: URL {
        containerURL.appendingPathComponent(fileName)
    }

    public static var imagesDirectoryURL: URL {
        let dir = containerURL.appendingPathComponent("BookImages", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    public static func loadSnapshot() -> LibrarySnapshot? {
        guard let data = try? Data(contentsOf: snapshotURL) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(LibrarySnapshot.self, from: data)
    }

    public static func saveSnapshot(_ snapshot: LibrarySnapshot) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(snapshot) else { return }
        try? data.write(to: snapshotURL, options: .atomic)
    }

    public static func saveImageData(_ data: Data, prefix: String) -> String? {
        let filename = "\(prefix)_\(UUID().uuidString).jpg"
        let url = imagesDirectoryURL.appendingPathComponent(filename)
        do {
            try data.write(to: url, options: .atomic)
            return filename
        } catch {
            return nil
        }
    }

    public static func loadImageData(filename: String?) -> Data? {
        guard let filename, !filename.isEmpty else { return nil }
        let url = imagesDirectoryURL.appendingPathComponent(filename)
        return try? Data(contentsOf: url)
    }
}

// MARK: - Library Store

@MainActor
public final class LibraryStore: ObservableObject {
    @Published public var books: [Book] = []
    @Published public var sessions: [ReadingSession] = []
    @Published public var decor: [ShelfDecorItem] = []
    @Published public var customShelves: [CustomShelf] = []
    @Published public var plantState: GrowingPlantState = GrowingPlantState()
    @Published public var settings: ShelfSettings = ShelfSettings()
    @Published public var customTropes: [String] = []
    @Published public var selectedShelf: ShelfCategory = .read
    @Published public var selectedCustomShelfId: UUID? = nil

    public init(forceDemoData: Bool = false) {
        if forceDemoData {
            loadDemoLibrary(markOnboarded: true)
        } else if let snapshot = LibraryStorage.loadSnapshot() {
            apply(snapshot: snapshot)
        } else {
            // Fresh install: prepare warm defaults and let onboarding choose Demo vs Empty!
            self.decor = Self.defaultDecor()
            self.settings = ShelfSettings(hasCompletedOnboarding: false)
        }
    }

    private func apply(snapshot: LibrarySnapshot) {
        self.books = snapshot.books
        self.sessions = snapshot.sessions
        self.decor = snapshot.decor.isEmpty ? Self.defaultDecor() : snapshot.decor
        self.customShelves = snapshot.customShelves
        self.plantState = snapshot.plantState
        self.settings = snapshot.settings
        self.customTropes = snapshot.customTropes
    }

    public func persist() {
        let snapshot = LibrarySnapshot(
            books: books,
            sessions: sessions,
            decor: decor,
            customShelves: customShelves,
            plantState: plantState,
            settings: settings,
            customTropes: customTropes
        )
        LibraryStorage.saveSnapshot(snapshot)
        WidgetCenter.shared.reloadAllTimelines()
    }

    public static func defaultDecor() -> [ShelfDecorItem] {
        [
            ShelfDecorItem(kind: .sleepingCat, rowIndex: 0, slotIndex: 2, isEnabled: true),
            ShelfDecorItem(kind: .monstera, rowIndex: 1, slotIndex: 0, isEnabled: true),
            ShelfDecorItem(kind: .candle, rowIndex: 0, slotIndex: 0, isEnabled: true),
            ShelfDecorItem(kind: .snowman, rowIndex: 2, slotIndex: 2, isEnabled: false),
            ShelfDecorItem(kind: .snowGlobe, rowIndex: 1, slotIndex: 2, isEnabled: false),
            ShelfDecorItem(kind: .coffeeMug, rowIndex: 2, slotIndex: 0, isEnabled: false)
        ]
    }

    // MARK: - Onboarding & Clean Empty Start

    public func startWithEmptyShelf() {
        books = []
        sessions = []
        decor = Self.defaultDecor()
        settings.hasCompletedOnboarding = true
        selectedShelf = .unread
        persist()
    }

    public func clearAllBooks() {
        books = []
        sessions = []
        persist()
    }

    // MARK: - Background Real Cover Hydration

    public func hydrateRealCoversIfNeeded() async {
        let targets = books.filter { $0.customCoverFilename == nil && !$0.isbn.isEmpty }
        for book in targets {
            if let result = await BookMetadataService.downloadAndStoreCover(urlString: book.coverURLString, isbn: book.isbn) {
                if let idx = books.firstIndex(where: { $0.id == book.id }) {
                    books[idx].customCoverFilename = result.filename
                    persist()
                }
            }
        }
    }

    // MARK: - CRUD & Drag/Reorder Operations

    public func addBook(_ book: Book) {
        var newBook = book
        newBook.sortOrder = (books.map(\.sortOrder).max() ?? 0) + 1
        books.append(newBook)
        persist()
    }

    public func updateBook(_ book: Book) {
        guard let idx = books.firstIndex(where: { $0.id == book.id }) else { return }
        books[idx] = book
        persist()
    }

    public func deleteBook(_ book: Book) {
        books.removeAll { $0.id == book.id }
        sessions.removeAll { $0.bookId == book.id }
        persist()
    }

    public func moveBook(_ book: Book, direction: Int) {
        let shelfList = activeShelfBooks
        guard let currentPos = shelfList.firstIndex(where: { $0.id == book.id }) else { return }
        let targetPos = currentPos + direction
        guard shelfList.indices.contains(targetPos) else { return }
        let other = shelfList[targetPos]
        guard let idxA = books.firstIndex(where: { $0.id == book.id }),
              let idxB = books.firstIndex(where: { $0.id == other.id }) else { return }
        let tempOrder = books[idxA].sortOrder
        books[idxA].sortOrder = books[idxB].sortOrder
        books[idxB].sortOrder = tempOrder
        persist()
    }

    public func cycleDisplayStyle(for book: Book) {
        guard let idx = books.firstIndex(where: { $0.id == book.id }) else { return }
        let all = BookDisplayStyle.allCases
        if let cur = all.firstIndex(of: books[idx].displayStyle) {
            books[idx].displayStyle = all[(cur + 1) % all.count]
            persist()
        }
    }

    public func shiftDecor(_ item: ShelfDecorItem, slotDelta: Int = 0, rowDelta: Int = 0) {
        guard let idx = decor.firstIndex(where: { $0.id == item.id }) else { return }
        decor[idx].slotIndex = min(2, max(0, decor[idx].slotIndex + slotDelta))
        decor[idx].rowIndex = min(4, max(0, decor[idx].rowIndex + rowDelta))
        persist()
    }

    public func toggleDecor(_ kind: DecorKind, rowIndex: Int = 0) {
        if let idx = decor.firstIndex(where: { $0.kind == kind }) {
            decor[idx].isEnabled.toggle()
        } else {
            decor.append(ShelfDecorItem(kind: kind, rowIndex: rowIndex, slotIndex: 2, isEnabled: true))
        }
        persist()
    }

    public func addCustomShelf(name: String, iconName: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        customShelves.append(CustomShelf(name: trimmed, iconName: iconName))
        persist()
    }

    public func logProgress(for bookId: UUID, newPage: Int, durationSeconds: Int = 900, roomTheme: ReadingRoomTheme = .catWinter) {
        guard let idx = books.firstIndex(where: { $0.id == bookId }) else { return }
        let oldPage = books[idx].currentPage
        let clamped = min(max(0, newPage), books[idx].pageCount)
        let delta = max(0, clamped - oldPage)

        books[idx].currentPage = clamped
        if books[idx].dateStarted == nil && clamped > 0 {
            books[idx].dateStarted = Date()
        }
        if clamped >= books[idx].pageCount {
            books[idx].shelf = .read
            books[idx].dateFinished = Date()
        } else if clamped > 0 && books[idx].shelf == .unread {
            books[idx].shelf = .reading
        }

        if delta > 0 || durationSeconds > 0 {
            let session = ReadingSession(
                bookId: bookId,
                date: Date(),
                durationSeconds: durationSeconds,
                pagesRead: max(delta, 1),
                roomTheme: roomTheme
            )
            sessions.append(session)
        }
        persist()
    }

    public func addQuote(to bookId: UUID, text: String, pageNumber: Int?, isThought: Bool = false) {
        guard let idx = books.firstIndex(where: { $0.id == bookId }) else { return }
        let quote = BookQuote(text: text, pageNumber: pageNumber, isThought: isThought)
        books[idx].quotes.insert(quote, at: 0)
        persist()
    }

    // MARK: - Filtering & Derived Queries

    public var activeShelfBooks: [Book] {
        if let customId = selectedCustomShelfId {
            return books.filter { $0.customShelfIDs.contains(customId) }.sorted { $0.sortOrder < $1.sortOrder }
        }
        return books(for: selectedShelf)
    }

    public var activeShelfTitle: String {
        if let customId = selectedCustomShelfId,
           let custom = customShelves.first(where: { $0.id == customId }) {
            return custom.name
        }
        return selectedShelf.rawValue
    }

    public func books(for shelf: ShelfCategory) -> [Book] {
        if shelf == .lent {
            return books.filter { $0.shelf == .lent || ($0.lentTo != nil && !($0.lentTo?.isEmpty ?? true)) }
                .sorted { $0.sortOrder < $1.sortOrder }
        }
        return books.filter { $0.shelf == shelf }.sorted { $0.sortOrder < $1.sortOrder }
    }

    public var currentlyReadingBooks: [Book] {
        books.filter { $0.shelf == .reading }.sorted { $0.sortOrder < $1.sortOrder }
    }

    public var allQuotesWithBook: [(Book, BookQuote)] {
        books.flatMap { book in
            book.quotes.map { (book, $0) }
        }.sorted { $0.1.dateAdded > $1.1.dateAdded }
    }

    public var sortedSessions: [ReadingSession] {
        sessions.sorted { $0.date > $1.date }
    }

    /// Growing plant stage (1...5) based on total unique reading days!
    public var plantGrowthStage: Int {
        let cal = Calendar.current
        let uniqueDays = Set(sessions.map { cal.startOfDay(for: $0.date) }).count
        switch uniqueDays {
        case 0...1: return 1
        case 2...4: return 2
        case 5...9: return 3
        case 10...17: return 4
        default: return 5
        }
    }

    /// Estimated reading pace in pages per hour
    public var pagesPerHour: Double {
        let totalPages = sessions.reduce(0) { $0 + $1.pagesRead }
        let totalHours = Double(sessions.reduce(0) { $0 + $1.durationSeconds }) / 3600.0
        guard totalHours > 0.2, totalPages > 0 else { return 38.0 }
        return min(120.0, max(15.0, Double(totalPages) / totalHours))
    }

    public func estimatedRemainingTimeString(for book: Book) -> String {
        let remaining = max(0, book.pageCount - book.currentPage)
        guard remaining > 0 else { return "Fertig gelesen" }
        let hours = Double(remaining) / pagesPerHour
        let wholeHours = Int(hours)
        let mins = Int((hours - Double(wholeHours)) * 60)
        if wholeHours == 0 {
            return "Noch ca. \(max(5, mins)) Min."
        }
        return "Noch ca. \(wholeHours) Std. \(mins) Min."
    }

    // MARK: - Reading Statistics & Streaks

    public var currentStreakDays: Int {
        let cal = Calendar.current
        let uniqueDays = Set(sessions.map { cal.startOfDay(for: $0.date) })
        var streak = 0
        var checkDate = cal.startOfDay(for: Date())
        if !uniqueDays.contains(checkDate), let yesterday = cal.date(byAdding: .day, value: -1, to: checkDate) {
            checkDate = yesterday
        }
        while uniqueDays.contains(checkDate) {
            streak += 1
            guard let prev = cal.date(byAdding: .day, value: -1, to: checkDate) else { break }
            checkDate = prev
        }
        return streak
    }

    public var pagesReadToday: Int {
        let cal = Calendar.current
        return sessions.filter { cal.isDateInToday($0.date) }.reduce(0) { $0 + $1.pagesRead }
    }

    public var minutesReadToday: Int {
        let cal = Calendar.current
        return sessions.filter { cal.isDateInToday($0.date) }.reduce(0) { $0 + $1.durationSeconds } / 60
    }

    public var lastBookReadToday: Book? {
        let cal = Calendar.current
        guard let latest = sessions
            .filter({ cal.isDateInToday($0.date) })
            .sorted(by: { $0.date > $1.date })
            .first else { return currentlyReadingBooks.first }
        return books.first { $0.id == latest.bookId }
    }

    public func currentWeekDates() -> [Date] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let weekday = cal.component(.weekday, from: today)
        let daysSinceMonday = (weekday + 5) % 7
        guard let monday = cal.date(byAdding: .day, value: -daysSinceMonday, to: today) else {
            return []
        }
        return (0..<7).compactMap { cal.date(byAdding: .day, value: $0, to: monday) }
    }

    public func weekReadingActivity() -> [Bool] {
        let cal = Calendar.current
        let activeDays = Set(sessions.map { cal.startOfDay(for: $0.date) })
        return currentWeekDates().map { activeDays.contains(cal.startOfDay(for: $0)) }
    }

    public func monthlyStats(for monthDate: Date) -> (booksCount: Int, pagesCount: Int, readingDays: Int) {
        let cal = Calendar.current
        let monthSessions = sessions.filter { cal.isDate($0.date, equalTo: monthDate, toGranularity: .month) }
        let pages = monthSessions.reduce(0) { $0 + $1.pagesRead }
        let days = Set(monthSessions.map { cal.startOfDay(for: $0.date) }).count
        let finishedInMonth = books.filter {
            guard let fin = $0.dateFinished else { return false }
            return cal.isDate(fin, equalTo: monthDate, toGranularity: .month)
        }.count
        let touchedBooks = Set(monthSessions.map(\.bookId)).count
        return (max(finishedInMonth, min(touchedBooks, 8)), pages, days)
    }

    public func bookForCalendarDay(_ date: Date) -> Book? {
        let cal = Calendar.current
        let daySessions = sessions.filter { cal.isDate($0.date, inSameDayAs: date) }
        guard let topSession = daySessions.max(by: { $0.pagesRead < $1.pagesRead }) else { return nil }
        return books.first { $0.id == topSession.bookId }
    }

    public var totalShelfValue: Double {
        books.compactMap(\.purchasePrice).reduce(0, +)
    }

    public var totalReadPages: Int {
        books.filter { $0.shelf == .read }.reduce(0) { $0 + $1.pageCount }
        + books.filter { $0.shelf == .reading }.reduce(0) { $0 + $1.currentPage }
    }

    public struct SeriesGroup: Identifiable {
        public var id: String { name }
        public let name: String
        public let ownedBooks: [Book]
        public let totalExpected: Int
        public var missingIndices: [Int] {
            let owned = Set(ownedBooks.compactMap(\.seriesIndex))
            return (1...max(totalExpected, owned.max() ?? 1)).filter { !owned.contains($0) }
        }
    }

    public var seriesGroups: [SeriesGroup] {
        let grouped = Dictionary(grouping: books.filter { !($0.seriesName ?? "").isEmpty }) { $0.seriesName! }
        return grouped.map { name, items in
            let sorted = items.sorted { ($0.seriesIndex ?? 0) < ($1.seriesIndex ?? 0) }
            let total = max(items.compactMap(\.seriesTotal).max() ?? items.count, items.count)
            return SeriesGroup(name: name, ownedBooks: sorted, totalExpected: total)
        }.sorted { $0.name < $1.name }
    }

    // MARK: - CSV & JSON Import/Export

    public func exportJSONData() -> Data? {
        let snapshot = LibrarySnapshot(
            books: books,
            sessions: sessions,
            decor: decor,
            customShelves: customShelves,
            plantState: plantState,
            settings: settings,
            customTropes: customTropes
        )
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted]
        return try? encoder.encode(snapshot)
    }

    public func importJSONData(_ data: Data) -> Bool {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let snapshot = try? decoder.decode(LibrarySnapshot.self, from: data) else { return false }
        apply(snapshot: snapshot)
        persist()
        return true
    }

    @discardableResult
    public func importGoodreadsCSV(_ csvText: String) -> Int {
        let lines = csvText.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        guard lines.count > 1 else { return 0 }
        let header = parseCSVLine(lines[0]).map { $0.lowercased() }
        let titleIdx = header.firstIndex(where: { $0.contains("title") }) ?? 1
        let authorIdx = header.firstIndex(where: { $0.contains("author") }) ?? 2
        let pagesIdx = header.firstIndex(where: { $0.contains("pages") })
        let shelfIdx = header.firstIndex(where: { $0.contains("exclusive shelf") || $0.contains("read status") })
        let ratingIdx = header.firstIndex(where: { $0.contains("my rating") || $0.contains("star rating") })

        let palette = ["#2B3A42", "#5D2E35", "#273C2C", "#4A3525", "#352A47", "#1F363D", "#6B3A2A"]
        var imported = 0
        for (i, line) in lines.dropFirst().enumerated() {
            let cols = parseCSVLine(line)
            guard cols.count > max(titleIdx, authorIdx) else { continue }
            let title = cols[titleIdx].trimmingCharacters(in: .whitespacesAndNewlines)
            let author = cols[authorIdx].trimmingCharacters(in: .whitespacesAndNewlines)
            guard !title.isEmpty else { continue }

            let pages = pagesIdx.flatMap { cols.indices.contains($0) ? Int(cols[$0]) : nil } ?? 340
            let rawShelf = shelfIdx.flatMap { cols.indices.contains($0) ? cols[$0].lowercased() : nil } ?? "read"
            let shelf: ShelfCategory = rawShelf.contains("currently") ? .reading : (rawShelf.contains("to-read") ? .unread : .read)
            let rating = ratingIdx.flatMap { cols.indices.contains($0) ? Double(cols[$0]) : nil } ?? 0

            let book = Book(
                title: title,
                author: author.isEmpty ? "Unbekannt" : author,
                pageCount: max(80, pages),
                currentPage: shelf == .read ? max(80, pages) : 0,
                heightCm: Double(19 + (i % 5)),
                shelf: shelf,
                spineColorHex: palette[i % palette.count],
                spineAccentHex: "#E6C78B",
                rating: rating,
                purchasePrice: 18.0
            )
            addBook(book)
            imported += 1
        }
        return imported
    }

    private func parseCSVLine(_ line: String) -> [String] {
        var result: [String] = []
        var current = ""
        var inQuotes = false
        for char in line {
            if char == "\"" {
                inQuotes.toggle()
            } else if char == "," && !inQuotes {
                result.append(current)
                current = ""
            } else {
                current.append(char)
            }
        }
        result.append(current)
        return result
    }

    // MARK: - Rich German Demo Library (with real ISBNs & synopses!)

    public func loadDemoLibrary(markOnboarded: Bool = true) {
        let cal = Calendar.current
        let now = Date()

        let b1 = Book(
            title: "Iron Flame",
            author: "Rebecca Yarros",
            isbn: "9783423283977",
            publisher: "dtv",
            publishedYear: "2023",
            bindingType: "Gebunden",
            originalTitle: "Iron Flame",
            bookDescription: "Jeder erwartete, dass Violet Sorrengail während ihres ersten Jahres am Basgiath War College sterben würde – Violet eingeschlossen. Doch das erste Jahr war nur der Anfang. Nun beginnt das wahre Training, und Geheimnisse, die jahrhundertelang verborgen lagen, drohen alles zu zerstören.",
            pageCount: 960,
            currentPage: 960,
            heightCm: 23.5,
            shelf: .read,
            displayStyle: .spine,
            spineColorHex: "#1E1A18",
            spineAccentHex: "#E2A648",
            spineTextColorHex: "#F5DEB3",
            spineTypography: .ornate,
            rating: 5.0,
            seriesName: "Flammengeküsst",
            seriesIndex: 2,
            seriesTotal: 5,
            tropes: ["Enemies to Lovers", "Dragons", "Magic Academy"],
            quotes: [
                BookQuote(text: "Ein Drache ohne seinen Reiter ist eine Tragödie. Ein Reiter ohne seinen Drachen ist tot.", pageNumber: 142, dateAdded: cal.date(byAdding: .day, value: -6, to: now)!)
            ],
            purchasePrice: 28.00,
            isSpecialEdition: true,
            dateFinished: cal.date(byAdding: .day, value: -5, to: now),
            sortOrder: 0
        )

        let b2 = Book(
            title: "Das Lied der Krähen",
            author: "Leigh Bardugo",
            isbn: "9783426525722",
            publisher: "Knaur",
            publishedYear: "2017",
            bindingType: "Taschenbuch",
            originalTitle: "Six of Crows",
            bookDescription: "Ketterdam: eine pulsierende Hafenstadt, in der alles käuflich ist. Niemand weiß das besser als das kriminelle Genie Kaz Brekker. Als ihm ein Auftrag angeboten wird, der ihn unermesslich reich machen könnte, stellt er eine Crew aus sechs gefährlichen Außenseitern zusammen.",
            pageCount: 592,
            currentPage: 592,
            heightCm: 21.8,
            shelf: .read,
            displayStyle: .spine,
            spineColorHex: "#8C2622",
            spineAccentHex: "#191514",
            spineTextColorHex: "#F7EDE2",
            spineTypography: .ornate,
            rating: 5.0,
            seriesName: "Krähen-Dilogie",
            seriesIndex: 1,
            seriesTotal: 2,
            tropes: ["Heist", "Found Family", "Morally Grey"],
            quotes: [
                BookQuote(text: "Keine Trauernden. Keine Beerdigungen.", pageNumber: 88, dateAdded: cal.date(byAdding: .day, value: -9, to: now)!)
            ],
            purchasePrice: 22.00,
            dateFinished: cal.date(byAdding: .day, value: -8, to: now),
            sortOrder: 1
        )

        let b3 = Book(
            title: "Throne of Glass",
            author: "Sarah J. Maas",
            isbn: "9783423716512",
            publisher: "dtv",
            publishedYear: "2013",
            bindingType: "Taschenbuch",
            originalTitle: "Throne of Glass",
            bookDescription: "Celaena Sardothien ist die berüchtigtste Assassinin von Adarlan. Als der Kronprinz ihr die Freiheit verspricht, falls sie für ihn ein tödliches Turnier gewinnt, stürzt sie sich in einen Wettkampf voller Intrigen und dunkler Magie.",
            pageCount: 512,
            currentPage: 512,
            heightCm: 22.4,
            shelf: .read,
            displayStyle: .coverForward,
            spineColorHex: "#142738",
            spineAccentHex: "#D4AF37",
            spineTextColorHex: "#F2E6C9",
            spineTypography: .ornate,
            rating: 4.5,
            seriesName: "Throne of Glass",
            seriesIndex: 1,
            seriesTotal: 7,
            tropes: ["Chosen One", "Royalty", "Slow Burn"],
            purchasePrice: 19.95,
            dateFinished: cal.date(byAdding: .day, value: -12, to: now),
            sortOrder: 2
        )

        let b4 = Book(
            title: "Fourth Wing",
            author: "Rebecca Yarros",
            isbn: "9783423283403",
            publisher: "dtv",
            publishedYear: "2023",
            bindingType: "Gebunden",
            originalTitle: "Fourth Wing",
            bookDescription: "Violet Sorrengail hat sich ihr ganzes Leben auf ein ruhiges Dasein unter Büchern vorbereitet. Doch ihre Mutter befiehlt ihr, dem berüchtigten Reiterquadranten beizutreten – wo Drachen sich keine schwachen Menschen aussuchen.",
            pageCount: 768,
            currentPage: 768,
            heightCm: 23.4,
            shelf: .read,
            displayStyle: .spine,
            spineColorHex: "#B57B3C",
            spineAccentHex: "#1E1814",
            spineTextColorHex: "#1D1610",
            spineTypography: .ornate,
            rating: 5.0,
            seriesName: "Flammengeküsst",
            seriesIndex: 1,
            seriesTotal: 5,
            tropes: ["Enemies to Lovers", "Dragons", "Forced Proximity"],
            purchasePrice: 28.00,
            isSignedEdition: true,
            dateFinished: cal.date(byAdding: .day, value: -16, to: now),
            sortOrder: 3
        )

        let b5 = Book(
            title: "The Seven Husbands of Evelyn Hugo",
            author: "Taylor Jenkins Reid",
            isbn: "9781501161933",
            publisher: "Atria",
            publishedYear: "2017",
            bindingType: "Taschenbuch",
            originalTitle: "The Seven Husbands of Evelyn Hugo",
            bookDescription: "Die legendäre Hollywood-Ikone Evelyn Hugo ist endlich bereit, die Wahrheit über ihr glamouröses und skandalöses Leben zu erzählen – und wählt ausgerechnet die unbekannte Journalistin Monique Grant dafür aus.",
            pageCount: 400,
            currentPage: 400,
            heightCm: 20.5,
            shelf: .read,
            displayStyle: .stacked,
            spineColorHex: "#174B3E",
            spineAccentHex: "#E3C57E",
            spineTextColorHex: "#FBF5E6",
            spineTypography: .serif,
            rating: 4.5,
            tropes: ["Slow Burn", "Plot Twist"],
            purchasePrice: 15.90,
            dateFinished: cal.date(byAdding: .day, value: -22, to: now),
            sortOrder: 4
        )

        let b6 = Book(
            title: "Book Lovers",
            author: "Emily Henry",
            isbn: "9780593334836",
            publisher: "Berkley",
            publishedYear: "2022",
            bindingType: "Taschenbuch",
            bookDescription: "Nora Stephens lebt für Bücher – als knallharte Literaturagentin in New York. Als ihre Schwester sie zu einem Sommerurlaub in eine kleine Bilderbuch-Stadt überredet, läuft sie dort ausgerechnet ihrem größten Rivalen Charlie Lastra über den Weg.",
            pageCount: 384,
            currentPage: 384,
            heightCm: 20.2,
            shelf: .read,
            displayStyle: .stacked,
            spineColorHex: "#C24658",
            spineAccentHex: "#F8D9B6",
            spineTextColorHex: "#FFF5EE",
            spineTypography: .modern,
            rating: 4.0,
            tropes: ["Enemies to Lovers", "Grumpy × Sunshine"],
            purchasePrice: 14.50,
            dateFinished: cal.date(byAdding: .day, value: -25, to: now),
            sortOrder: 5
        )

        let b7 = Book(
            title: "Happy Place",
            author: "Emily Henry",
            isbn: "9780593441275",
            publisher: "Berkley",
            publishedYear: "2023",
            bindingType: "Taschenbuch",
            bookDescription: "Harriet und Wyn waren seit dem College das perfekte Paar – bis sie sich vor sechs Monaten getrennt haben. Doch ihren besten Freunden haben sie es noch nicht gesagt, und nun steht der letzte gemeinsame Sommerurlaub in Maine bevor.",
            pageCount: 400,
            currentPage: 400,
            heightCm: 20.2,
            shelf: .read,
            displayStyle: .stacked,
            spineColorHex: "#E06A3E",
            spineAccentHex: "#FCE1A6",
            spineTextColorHex: "#FFF9F2",
            spineTypography: .modern,
            rating: 4.5,
            tropes: ["Second Chance", "Fake Dating"],
            purchasePrice: 14.50,
            dateFinished: cal.date(byAdding: .day, value: -27, to: now),
            sortOrder: 6
        )

        let b8 = Book(
            title: "Die stumme Patientin",
            author: "Alex Michaelides",
            isbn: "9783426524510",
            publisher: "Droemer",
            publishedYear: "2019",
            bindingType: "Taschenbuch",
            originalTitle: "The Silent Patient",
            bookDescription: "Alicia Berenson erschießt ihren Ehemann fünfmal ins Gesicht – und spricht danach nie wieder ein einziges Wort. Der forensische Psychotherapeut Theo Faber ist besessen davon, das Geheimnis ihres Schweigens zu lüften.",
            pageCount: 416,
            currentPage: 416,
            heightCm: 21.5,
            shelf: .read,
            displayStyle: .coverForward,
            spineColorHex: "#1C2930",
            spineAccentHex: "#87A4B0",
            spineTextColorHex: "#EAF0F2",
            spineTypography: .modern,
            rating: 4.5,
            tropes: ["Psychological Thriller", "Unreliable Narrator", "Plot Twist"],
            purchasePrice: 17.00,
            dateFinished: cal.date(byAdding: .day, value: -18, to: now),
            sortOrder: 7
        )

        let b9 = Book(
            title: "Die Verwandlung",
            author: "Franz Kafka",
            isbn: "9783150099001",
            publisher: "Reclam",
            publishedYear: "1915",
            bindingType: "Taschenbuch",
            bookDescription: "Eines Morgens erwacht der Handelsreisende Gregor Samsa in seinem Bett und stellt fest, dass er sich über Nacht in ein ungeheueres Ungeziefer verwandelt hat.",
            pageCount: 160,
            currentPage: 160,
            heightCm: 17.8,
            shelf: .read,
            displayStyle: .spine,
            spineColorHex: "#D4A73B",
            spineAccentHex: "#1E1B18",
            spineTextColorHex: "#1A1714",
            spineTypography: .condensed,
            rating: 4.5,
            tropes: ["Klassiker", "Philosophie"],
            quotes: [
                BookQuote(text: "Als Gregor Samsa eines Morgens aus unruhigen Träumen erwachte, fand er sich in seinem Bett zu einem ungeheueren Ungeziefer verwandelt.", pageNumber: 5, dateAdded: cal.date(byAdding: .day, value: -2, to: now)!)
            ],
            purchasePrice: 6.00,
            dateFinished: cal.date(byAdding: .day, value: -14, to: now),
            sortOrder: 8
        )

        // Currently Reading
        let c1 = Book(
            title: "Yellowface",
            author: "R. F. Kuang",
            isbn: "9783847901594",
            publisher: "Eichborn",
            publishedYear: "2023",
            bindingType: "Gebunden",
            originalTitle: "Yellowface",
            bookDescription: "Als die gefeierte Bestsellerautorin Athena Liu bei einem bizarren Unfall stirbt, stiehlt ihre erfolglose Rivalin June Hayward ihr unveröffentlichtes Manuskript – und veröffentlicht es unter eigenem Namen.",
            pageCount: 352,
            currentPage: 301,
            heightCm: 21.2,
            shelf: .reading,
            displayStyle: .coverForward,
            spineColorHex: "#E6BC2F",
            spineAccentHex: "#191716",
            spineTextColorHex: "#191716",
            spineTypography: .modern,
            rating: 4.5,
            tropes: ["Unreliable Narrator", "Psychological Thriller"],
            quotes: [
                BookQuote(text: "Wird auf jeden Fall nochmal gelesen – so bissig und erschreckend realistisch.", pageNumber: 240, dateAdded: now)
            ],
            purchasePrice: 22.00,
            dateStarted: cal.date(byAdding: .day, value: -4, to: now),
            sortOrder: 9
        )

        let c2 = Book(
            title: "Onyx Storm",
            author: "Rebecca Yarros",
            isbn: "9783423284455",
            publisher: "dtv",
            publishedYear: "2025",
            bindingType: "Gebunden",
            originalTitle: "Onyx Storm",
            bookDescription: "Nach fast achtzehn Monaten am Basgiath War College hat Violet Sorrengail keine Zeit mehr für Unterricht. Der Kampf hat wirklich begonnen – und Violet muss weit über die Grenzen von Navarre hinausreisen.",
            pageCount: 823,
            currentPage: 253,
            heightCm: 23.6,
            shelf: .reading,
            displayStyle: .spine,
            spineColorHex: "#212026",
            spineAccentHex: "#B59C72",
            spineTextColorHex: "#ECE5D8",
            spineTypography: .ornate,
            seriesName: "Flammengeküsst",
            seriesIndex: 3,
            seriesTotal: 5,
            tropes: ["Enemies to Lovers", "Dragons", "Found Family"],
            purchasePrice: 29.00,
            isSpecialEdition: true,
            dateStarted: cal.date(byAdding: .day, value: -2, to: now),
            sortOrder: 10
        )

        // Unread
        let u1 = Book(
            title: "Eine neue Erde",
            author: "Eckhart Tolle",
            isbn: "9783442341887",
            publisher: "Arkana",
            publishedYear: "2005",
            bindingType: "Gebunden",
            originalTitle: "A New Earth",
            bookDescription: "Ein Wegweiser für alle, die ihr Bewusstsein vertiefen und gleichzeitig verstehen möchten, wie persönliches Erwachen unsere Welt verändern kann.",
            pageCount: 347,
            currentPage: 0,
            heightCm: 21.5,
            shelf: .unread,
            displayStyle: .coverForward,
            spineColorHex: "#1E52A8",
            spineAccentHex: "#DCE8F7",
            spineTextColorHex: "#FFFFFF",
            spineTypography: .modern,
            purchasePrice: 22.00,
            sortOrder: 11
        )

        let u2 = Book(
            title: "Babel",
            author: "R. F. Kuang",
            isbn: "9783847901433",
            publisher: "Eichborn",
            publishedYear: "2023",
            bindingType: "Gebunden",
            bookDescription: "Oxford, 1836: Im Königlichen Institut für Übersetzung – genannt Babel – ist Sprache buchstäblich Magie. Doch Macht hat ihren Preis.",
            pageCount: 688,
            currentPage: 0,
            heightCm: 22.8,
            shelf: .unread,
            displayStyle: .spine,
            spineColorHex: "#2F353B",
            spineAccentHex: "#C9A25B",
            spineTextColorHex: "#F4EBDC",
            spineTypography: .serif,
            tropes: ["Dark Academia", "Magic Academy", "Found Family"],
            purchasePrice: 26.00,
            sortOrder: 12
        )

        // Wishlist
        let w1 = Book(
            title: "Das Gold der Krähen",
            author: "Leigh Bardugo",
            isbn: "9783426525739",
            publisher: "Knaur",
            publishedYear: "2018",
            bindingType: "Taschenbuch",
            originalTitle: "Crooked Kingdom",
            pageCount: 624,
            currentPage: 0,
            heightCm: 21.8,
            shelf: .wishlist,
            displayStyle: .spine,
            spineColorHex: "#203344",
            spineAccentHex: "#D8AE52",
            spineTextColorHex: "#F7EBD0",
            spineTypography: .ornate,
            seriesName: "Krähen-Dilogie",
            seriesIndex: 2,
            seriesTotal: 2,
            tropes: ["Heist", "Found Family"],
            purchasePrice: 22.00,
            sortOrder: 13
        )

        // Lent
        let l1 = Book(
            title: "Der Fremde",
            author: "Albert Camus",
            isbn: "9783499221897",
            publisher: "Rowohlt",
            publishedYear: "1942",
            bindingType: "Taschenbuch",
            pageCount: 160,
            currentPage: 160,
            heightCm: 19.0,
            shelf: .lent,
            displayStyle: .spine,
            spineColorHex: "#31495E",
            spineAccentHex: "#E8C58E",
            spineTextColorHex: "#F4EDE2",
            spineTypography: .serif,
            rating: 4.5,
            tropes: ["Klassiker", "Philosophie"],
            purchasePrice: 12.00,
            lentTo: "Gizem",
            lentDate: cal.date(byAdding: .day, value: -11, to: now),
            sortOrder: 14
        )

        self.books = [b1, b2, b3, b4, b5, b6, b7, b8, b9, c1, c2, u1, u2, w1, l1]

        var generatedSessions: [ReadingSession] = []
        let calendarBooks = [c1, c2, b1, b2, b3, b4, b8, b9]
        for dayOffset in 0..<22 {
            if dayOffset == 11 || dayOffset == 14 { continue }
            guard let date = cal.date(byAdding: .day, value: -dayOffset, to: now) else { continue }
            let book = calendarBooks[dayOffset % calendarBooks.count]
            let pages = dayOffset == 0 ? 48 : (28 + (dayOffset * 13) % 52)
            generatedSessions.append(
                ReadingSession(
                    bookId: book.id,
                    date: date,
                    durationSeconds: 1800 + (dayOffset % 4) * 900,
                    pagesRead: pages,
                    roomTheme: dayOffset % 3 == 0 ? .catWinter : (dayOffset % 3 == 1 ? .dogShelf : .fireplaceCabin)
                )
            )
        }
        self.sessions = generatedSessions
        self.decor = Self.defaultDecor()
        self.plantState = GrowingPlantState(plantName: "Monstera", isAdopted: true, isBannerDismissed: false)
        self.settings = ShelfSettings(
            ownerName: "Mein",
            wallTheme: .warmOakCabinet,
            woodFinish: .oak,
            fairyLightsEnabled: true,
            warmSpotlightsEnabled: true,
            yearlyBookGoal: 36,
            dailyGoalMode: .pages,
            dailyPagesGoal: 30,
            dailyMinutesGoal: 25,
            hasCompletedOnboarding: markOnboarded
        )
        persist()
    }
}
