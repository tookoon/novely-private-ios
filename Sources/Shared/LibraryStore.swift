import Foundation
import SwiftUI
import WidgetKit

// MARK: - Shared App Group & Local Storage

public enum LibraryStorage {
    public static let appGroupID = "group.com.novelyprivate.app"
    private static let fileName = "novely_library_v1.json"

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
    @Published public var settings: ShelfSettings = ShelfSettings()
    @Published public var customTropes: [String] = []
    @Published public var selectedShelf: ShelfCategory = .read

    public init(forceDemoData: Bool = false) {
        if forceDemoData {
            loadDemoLibrary()
        } else if let snapshot = LibraryStorage.loadSnapshot(), !snapshot.books.isEmpty {
            apply(snapshot: snapshot)
        } else {
            loadDemoLibrary()
        }
    }

    private func apply(snapshot: LibrarySnapshot) {
        self.books = snapshot.books
        self.sessions = snapshot.sessions
        self.decor = snapshot.decor
        self.settings = snapshot.settings
        self.customTropes = snapshot.customTropes
    }

    public func persist() {
        let snapshot = LibrarySnapshot(
            books: books,
            sessions: sessions,
            decor: decor,
            settings: settings,
            customTropes: customTropes
        )
        LibraryStorage.saveSnapshot(snapshot)
        WidgetCenter.shared.reloadAllTimelines()
    }

    // MARK: - CRUD Operations

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

    public func logProgress(for bookId: UUID, newPage: Int, durationSeconds: Int = 900, roomTheme: ReadingRoomTheme = .winter) {
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

    public func addQuote(to bookId: UUID, text: String, pageNumber: Int?) {
        guard let idx = books.firstIndex(where: { $0.id == bookId }) else { return }
        let quote = BookQuote(text: text, pageNumber: pageNumber)
        books[idx].quotes.insert(quote, at: 0)
        persist()
    }

    public func toggleDecor(_ kind: DecorKind, rowIndex: Int = 0) {
        if let idx = decor.firstIndex(where: { $0.kind == kind }) {
            decor[idx].isEnabled.toggle()
        } else {
            decor.append(ShelfDecorItem(kind: kind, rowIndex: rowIndex, isEnabled: true))
        }
        persist()
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

    public var lastBookReadToday: Book? {
        let cal = Calendar.current
        guard let latest = sessions
            .filter({ cal.isDateInToday($0.date) })
            .sorted(by: { $0.date > $1.date })
            .first else { return currentlyReadingBooks.first }
        return books.first { $0.id == latest.bookId }
    }

    public func weekReadingActivity() -> [Bool] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let weekday = cal.component(.weekday, from: today) // 1=Sun, 2=Mon...
        let daysSinceMonday = (weekday + 5) % 7
        guard let monday = cal.date(byAdding: .day, value: -daysSinceMonday, to: today) else {
            return Array(repeating: false, count: 7)
        }
        let activeDays = Set(sessions.map { cal.startOfDay(for: $0.date) })
        return (0..<7).map { offset in
            guard let d = cal.date(byAdding: .day, value: offset, to: monday) else { return false }
            return activeDays.contains(d)
        }
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

    /// Parses Goodreads or StoryGraph CSV exports
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

    // MARK: - Rich Realistic German Demo Library

    public func loadDemoLibrary() {
        let cal = Calendar.current
        let now = Date()

        let b1 = Book(
            title: "Iron Flame",
            author: "Rebecca Yarros",
            isbn: "9783423283977",
            publisher: "dtv",
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
            notes: "Absolutes Jahreshighlight – das Ende hat mich zerstört!",
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
            notes: "Keine Trauernden. Keine Beerdigungen.",
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
            title: "Der Schatten des Windes",
            author: "Carlos Ruiz Zafón",
            isbn: "9783518458006",
            publisher: "Suhrkamp",
            pageCount: 564,
            currentPage: 564,
            heightCm: 21.0,
            shelf: .read,
            displayStyle: .spine,
            spineColorHex: "#263B4D",
            spineAccentHex: "#C9A86A",
            spineTextColorHex: "#EFE6D5",
            spineTypography: .serif,
            rating: 5.0,
            tropes: ["Dark Academia", "Klassiker", "Plot Twist"],
            purchasePrice: 16.00,
            dateFinished: cal.date(byAdding: .day, value: -20, to: now),
            sortOrder: 4
        )

        let b6 = Book(
            title: "The Seven Husbands of Evelyn Hugo",
            author: "Taylor Jenkins Reid",
            isbn: "9781501161933",
            publisher: "Atria",
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
            sortOrder: 5
        )

        let b7 = Book(
            title: "Book Lovers",
            author: "Emily Henry",
            isbn: "9780593334836",
            publisher: "Berkley",
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
            sortOrder: 6
        )

        let b8 = Book(
            title: "Happy Place",
            author: "Emily Henry",
            isbn: "9780593441275",
            publisher: "Berkley",
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
            sortOrder: 7
        )

        let b9 = Book(
            title: "Die Verwandlung",
            author: "Franz Kafka",
            isbn: "9783150099001",
            publisher: "Reclam",
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

        let b10 = Book(
            title: "Die stumme Patientin",
            author: "Alex Michaelides",
            isbn: "9783426524510",
            publisher: "Droemer",
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
            sortOrder: 9
        )

        let b11 = Book(
            title: "Animal Farm",
            author: "George Orwell",
            isbn: "9780141036137",
            publisher: "Penguin",
            pageCount: 144,
            currentPage: 144,
            heightCm: 18.5,
            shelf: .read,
            displayStyle: .spine,
            spineColorHex: "#3C4F3D",
            spineAccentHex: "#E3B873",
            spineTextColorHex: "#F4ECE0",
            spineTypography: .serif,
            rating: 5.0,
            tropes: ["Klassiker", "Dystopie"],
            purchasePrice: 11.00,
            dateFinished: cal.date(byAdding: .day, value: -10, to: now),
            sortOrder: 10
        )

        // Currently Reading
        let c1 = Book(
            title: "Yellowface",
            author: "R. F. Kuang",
            isbn: "9783847901594",
            publisher: "Eichborn",
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
            notes: "Wird auf jeden Fall nochmal gelesen.",
            quotes: [
                BookQuote(text: "Wird auf jeden Fall nochmal gelesen – so bissig und erschreckend realistisch.", pageNumber: 240, dateAdded: now)
            ],
            purchasePrice: 22.00,
            dateStarted: cal.date(byAdding: .day, value: -4, to: now),
            sortOrder: 11
        )

        let c2 = Book(
            title: "Onyx Storm",
            author: "Rebecca Yarros",
            isbn: "9783423284455",
            publisher: "dtv",
            pageCount: 823,
            currentPage: 253,
            heightCm: 23.6,
            shelf: .reading,
            displayStyle: .spine,
            spineColorHex: "#212026",
            spineAccentHex: "#B59C72",
            spineTextColorHex: "#ECE5D8",
            spineTypography: .ornate,
            rating: 0,
            seriesName: "Flammengeküsst",
            seriesIndex: 3,
            seriesTotal: 5,
            tropes: ["Enemies to Lovers", "Dragons", "Found Family"],
            purchasePrice: 29.00,
            isSpecialEdition: true,
            dateStarted: cal.date(byAdding: .day, value: -2, to: now),
            sortOrder: 12
        )

        // Unread (SuB)
        let u1 = Book(
            title: "Babel",
            author: "R. F. Kuang",
            isbn: "9783847901433",
            publisher: "Eichborn",
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
            sortOrder: 13
        )

        let u2 = Book(
            title: "Gödel, Escher, Bach",
            author: "Douglas R. Hofstadter",
            isbn: "9783608943382",
            publisher: "Klett-Cotta",
            pageCount: 844,
            currentPage: 0,
            heightCm: 24.0,
            shelf: .unread,
            displayStyle: .spine,
            spineColorHex: "#DFD5C5",
            spineAccentHex: "#B84231",
            spineTextColorHex: "#8C2A1E",
            spineTypography: .serif,
            tropes: ["Philosophie", "Klassiker"],
            purchasePrice: 34.00,
            sortOrder: 14
        )

        let u3 = Book(
            title: "Der geheime Garten",
            author: "Frances Hodgson Burnett",
            isbn: "9783458364900",
            publisher: "Insel",
            pageCount: 312,
            currentPage: 0,
            heightCm: 19.6,
            shelf: .unread,
            displayStyle: .coverForward,
            spineColorHex: "#2B4A38",
            spineAccentHex: "#DFC389",
            spineTextColorHex: "#F5EFE4",
            spineTypography: .serif,
            tropes: ["Klassiker", "Coming of Age"],
            purchasePrice: 14.00,
            sortOrder: 15
        )

        // Wishlist
        let w1 = Book(
            title: "Das Gold der Krähen",
            author: "Leigh Bardugo",
            isbn: "9783426525739",
            publisher: "Knaur",
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
            sortOrder: 16
        )

        // Lent book
        let l1 = Book(
            title: "Der Fremde",
            author: "Albert Camus",
            isbn: "9783499221897",
            publisher: "Rowohlt",
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
            lentTo: "Jonas",
            lentDate: cal.date(byAdding: .day, value: -11, to: now),
            sortOrder: 17
        )

        self.books = [b1, b2, b3, b4, b5, b6, b7, b8, b9, b10, b11, c1, c2, u1, u2, u3, w1, l1]

        // Generate 11-day streak + rich monthly calendar reading history
        var generatedSessions: [ReadingSession] = []
        let calendarBooks = [c1, c2, b1, b2, b3, b4, b9, b10]
        for dayOffset in 0..<22 {
            // Skip days 12 and 15 to show realistic gaps before the 11-day streak
            if dayOffset == 11 || dayOffset == 14 { continue }
            guard let date = cal.date(byAdding: .day, value: -dayOffset, to: now) else { continue }
            let book = calendarBooks[dayOffset % calendarBooks.count]
            let pages = dayOffset == 0 ? 112 : (35 + (dayOffset * 17) % 68)
            generatedSessions.append(
                ReadingSession(
                    bookId: book.id,
                    date: date,
                    durationSeconds: 1800 + (dayOffset % 4) * 600,
                    pagesRead: pages,
                    roomTheme: dayOffset % 3 == 0 ? .winter : (dayOffset % 3 == 1 ? .rainy : .fireplace)
                )
            )
        }
        self.sessions = generatedSessions

        self.decor = [
            ShelfDecorItem(kind: .candle, rowIndex: 0, isEnabled: true),
            ShelfDecorItem(kind: .monstera, rowIndex: 1, isEnabled: true),
            ShelfDecorItem(kind: .snowGlobe, rowIndex: 2, isEnabled: true),
            ShelfDecorItem(kind: .coffeeMug, rowIndex: 0, isEnabled: false),
            ShelfDecorItem(kind: .hourglass, rowIndex: 1, isEnabled: false),
            ShelfDecorItem(kind: .pinecones, rowIndex: 2, isEnabled: false)
        ]

        self.settings = ShelfSettings(
            ownerName: "Mein",
            wallTheme: .forestVelvet,
            woodFinish: .walnut,
            fairyLightsEnabled: true,
            warmSpotlightsEnabled: true,
            yearlyBookGoal: 36,
            dailyPagesGoal: 30,
            dailyMinutesGoal: 25
        )
        persist()
    }
}
