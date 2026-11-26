import Foundation
import SwiftUI

// MARK: - Shelf Category

public enum ShelfCategory: String, Codable, CaseIterable, Identifiable, Hashable {
    case unread = "Ungelesen"
    case reading = "Aktuell"
    case read = "Gelesen"
    case wishlist = "Wunschliste"
    case lent = "Verliehen"

    public var id: String { rawValue }

    public var iconName: String {
        switch self {
        case .unread: return "books.vertical"
        case .reading: return "book.pages"
        case .read: return "checkmark.seal"
        case .wishlist: return "heart"
        case .lent: return "person.2"
        }
    }
}

// MARK: - Book Display Style on Shelf

public enum BookDisplayStyle: String, Codable, CaseIterable, Identifiable {
    case spine = "Buchrücken"
    case coverForward = "Cover vorne"
    case stacked = "Liegender Stapel"

    public var id: String { rawValue }

    public var iconName: String {
        switch self {
        case .spine: return "rectangle.portrait"
        case .coverForward: return "book.closed"
        case .stacked: return "square.stack.3d.up"
        }
    }
}

// MARK: - Spine Typography Style

public enum SpineTypography: String, Codable, CaseIterable, Identifiable {
    case serif = "Serif"
    case modern = "Modern"
    case condensed = "Klassisch"
    case ornate = "Fantasy"

    public var id: String { rawValue }
}

// MARK: - Book Quote

public struct BookQuote: Identifiable, Codable, Hashable {
    public var id: UUID
    public var text: String
    public var pageNumber: Int?
    public var dateAdded: Date
    public var note: String?

    public init(
        id: UUID = UUID(),
        text: String,
        pageNumber: Int? = nil,
        dateAdded: Date = Date(),
        note: String? = nil
    ) {
        self.id = id
        self.text = text
        self.pageNumber = pageNumber
        self.dateAdded = dateAdded
        self.note = note
    }
}

// MARK: - Book Model

public struct Book: Identifiable, Codable, Hashable {
    public var id: UUID
    public var title: String
    public var author: String
    public var isbn: String
    public var publisher: String
    public var pageCount: Int
    public var currentPage: Int
    public var heightCm: Double
    public var shelf: ShelfCategory
    public var displayStyle: BookDisplayStyle
    public var spineColorHex: String
    public var spineAccentHex: String
    public var spineTextColorHex: String
    public var spineTypography: SpineTypography
    public var coverURLString: String?
    public var customSpineFilename: String?
    public var customCoverFilename: String?
    public var rating: Double // 0.0 ... 5.0 in 0.5 steps
    public var seriesName: String?
    public var seriesIndex: Int?
    public var seriesTotal: Int?
    public var tropes: [String]
    public var notes: String
    public var quotes: [BookQuote]
    public var purchasePrice: Double?
    public var lentTo: String?
    public var lentDate: Date?
    public var isSignedEdition: Bool
    public var isSpecialEdition: Bool
    public var dateAdded: Date
    public var dateStarted: Date?
    public var dateFinished: Date?
    public var sortOrder: Int

    public init(
        id: UUID = UUID(),
        title: String,
        author: String,
        isbn: String = "",
        publisher: String = "",
        pageCount: Int = 320,
        currentPage: Int = 0,
        heightCm: Double = 21.0,
        shelf: ShelfCategory = .unread,
        displayStyle: BookDisplayStyle = .spine,
        spineColorHex: String = "#2C3E50",
        spineAccentHex: String = "#D4AF37",
        spineTextColorHex: String = "#F4EFE6",
        spineTypography: SpineTypography = .serif,
        coverURLString: String? = nil,
        customSpineFilename: String? = nil,
        customCoverFilename: String? = nil,
        rating: Double = 0.0,
        seriesName: String? = nil,
        seriesIndex: Int? = nil,
        seriesTotal: Int? = nil,
        tropes: [String] = [],
        notes: String = "",
        quotes: [BookQuote] = [],
        purchasePrice: Double? = nil,
        lentTo: String? = nil,
        lentDate: Date? = nil,
        isSignedEdition: Bool = false,
        isSpecialEdition: Bool = false,
        dateAdded: Date = Date(),
        dateStarted: Date? = nil,
        dateFinished: Date? = nil,
        sortOrder: Int = 0
    ) {
        self.id = id
        self.title = title
        self.author = author
        self.isbn = isbn
        self.publisher = publisher
        self.pageCount = max(1, pageCount)
        self.currentPage = min(max(0, currentPage), max(1, pageCount))
        self.heightCm = min(max(16.0, heightCm), 28.0)
        self.shelf = shelf
        self.displayStyle = displayStyle
        self.spineColorHex = spineColorHex
        self.spineAccentHex = spineAccentHex
        self.spineTextColorHex = spineTextColorHex
        self.spineTypography = spineTypography
        self.coverURLString = coverURLString
        self.customSpineFilename = customSpineFilename
        self.customCoverFilename = customCoverFilename
        self.rating = rating
        self.seriesName = seriesName
        self.seriesIndex = seriesIndex
        self.seriesTotal = seriesTotal
        self.tropes = tropes
        self.notes = notes
        self.quotes = quotes
        self.purchasePrice = purchasePrice
        self.lentTo = lentTo
        self.lentDate = lentDate
        self.isSignedEdition = isSignedEdition
        self.isSpecialEdition = isSpecialEdition
        self.dateAdded = dateAdded
        self.dateStarted = dateStarted
        self.dateFinished = dateFinished
        self.sortOrder = sortOrder
    }

    public var progress: Double {
        guard pageCount > 0 else { return 0 }
        return min(1.0, max(0.0, Double(currentPage) / Double(pageCount)))
    }

    public var progressPercent: Int {
        Int((progress * 100).rounded())
    }

    /// True physical thickness proportion on shelf (in points)
    public var spineWidthPoints: CGFloat {
        let clampedPages = min(max(Double(pageCount), 120), 1100)
        let normalized = (clampedPages - 120) / (1100 - 120)
        return CGFloat(24.0 + normalized * 24.0) // 24pt to 48pt
    }

    /// True physical height proportion on shelf (in points)
    public var spineHeightPoints: CGFloat {
        let clampedCm = min(max(heightCm, 17.0), 26.0)
        let normalized = (clampedCm - 17.0) / (26.0 - 17.0)
        return CGFloat(104.0 + normalized * 34.0) // 104pt to 138pt
    }
}

// MARK: - Reading Session

public struct ReadingSession: Identifiable, Codable, Hashable {
    public var id: UUID
    public var bookId: UUID
    public var date: Date
    public var durationSeconds: Int
    public var pagesRead: Int
    public var roomTheme: ReadingRoomTheme

    public init(
        id: UUID = UUID(),
        bookId: UUID,
        date: Date = Date(),
        durationSeconds: Int,
        pagesRead: Int,
        roomTheme: ReadingRoomTheme = .winter
    ) {
        self.id = id
        self.bookId = bookId
        self.date = date
        self.durationSeconds = durationSeconds
        self.pagesRead = pagesRead
        self.roomTheme = roomTheme
    }
}

// MARK: - Shelf Decor

public enum DecorKind: String, Codable, CaseIterable, Identifiable {
    case candle = "Kerze"
    case monstera = "Monstera"
    case snowGlobe = "Schneekugel"
    case coffeeMug = "Lesetasse"
    case hourglass = "Sanduhr"
    case pinecones = "Tannenzapfen"

    public var id: String { rawValue }

    public var symbolName: String {
        switch self {
        case .candle: return "flame.fill"
        case .monstera: return "leaf.fill"
        case .snowGlobe: return "snowflake"
        case .coffeeMug: return "cup.and.saucer.fill"
        case .hourglass: return "hourglass"
        case .pinecones: return "tree.fill"
        }
    }
}

public struct ShelfDecorItem: Identifiable, Codable, Hashable {
    public var id: UUID
    public var kind: DecorKind
    public var rowIndex: Int
    public var isEnabled: Bool

    public init(id: UUID = UUID(), kind: DecorKind, rowIndex: Int, isEnabled: Bool = true) {
        self.id = id
        self.kind = kind
        self.rowIndex = rowIndex
        self.isEnabled = isEnabled
    }
}

// MARK: - Themes & Reading Rooms

public enum ShelfWallTheme: String, Codable, CaseIterable, Identifiable {
    case forestVelvet = "Waldgrün"
    case darkEspresso = "Espresso"
    case burgundyLibrary = "Bordeaux"
    case midnightBlue = "Mitternacht"
    case warmSandstone = "Pergament"

    public var id: String { rawValue }

    public var topHex: String {
        switch self {
        case .forestVelvet: return "#1B2620"
        case .darkEspresso: return "#1A1411"
        case .burgundyLibrary: return "#291418"
        case .midnightBlue: return "#131926"
        case .warmSandstone: return "#332B24"
        }
    }

    public var bottomHex: String {
        switch self {
        case .forestVelvet: return "#0E1411"
        case .darkEspresso: return "#0F0B09"
        case .burgundyLibrary: return "#14090B"
        case .midnightBlue: return "#0A0D14"
        case .warmSandstone: return "#1C1713"
        }
    }
}

public enum WoodFinish: String, Codable, CaseIterable, Identifiable {
    case walnut = "Walnuss"
    case oak = "Eiche"
    case mahogany = "Mahagoni"
    case ebony = "Ebenholz"

    public var id: String { rawValue }

    public var topHex: String {
        switch self {
        case .walnut: return "#6E4B32"
        case .oak: return "#9E7850"
        case .mahogany: return "#5C2C24"
        case .ebony: return "#342E2B"
        }
    }

    public var frontHex: String {
        switch self {
        case .walnut: return "#4A311F"
        case .oak: return "#735536"
        case .mahogany: return "#3B1A15"
        case .ebony: return "#1F1B19"
        }
    }
}

public enum ReadingRoomTheme: String, Codable, CaseIterable, Identifiable {
    case winter = "Winter im Lesezimmer"
    case rainy = "Regnerische Bibliothek"
    case fireplace = "Kaminzimmer"

    public var id: String { rawValue }

    public var imageAssetName: String {
        switch self {
        case .winter: return "ReadingRoomWinter"
        case .rainy: return "ReadingRoomRainy"
        case .fireplace: return "ReadingRoomFireplace"
        }
    }

    public var subtitle: String {
        switch self {
        case .winter: return "Leiser Schneefall & Kerzenschein"
        case .rainy: return "Regentropfen am Bibliotheksfenster"
        case .fireplace: return "Prasselndes Kaminfeuer & Wärme"
        }
    }

    public var ambientIcon: String {
        switch self {
        case .winter: return "snowflake"
        case .rainy: return "cloud.rain.fill"
        case .fireplace: return "flame.fill"
        }
    }
}

public struct ShelfSettings: Codable, Hashable {
    public var ownerName: String
    public var wallTheme: ShelfWallTheme
    public var woodFinish: WoodFinish
    public var fairyLightsEnabled: Bool
    public var warmSpotlightsEnabled: Bool
    public var yearlyBookGoal: Int
    public var dailyPagesGoal: Int
    public var dailyMinutesGoal: Int

    public init(
        ownerName: String = "Mein",
        wallTheme: ShelfWallTheme = .forestVelvet,
        woodFinish: WoodFinish = .walnut,
        fairyLightsEnabled: Bool = true,
        warmSpotlightsEnabled: Bool = true,
        yearlyBookGoal: Int = 36,
        dailyPagesGoal: Int = 30,
        dailyMinutesGoal: Int = 25
    ) {
        self.ownerName = ownerName
        self.wallTheme = wallTheme
        self.woodFinish = woodFinish
        self.fairyLightsEnabled = fairyLightsEnabled
        self.warmSpotlightsEnabled = warmSpotlightsEnabled
        self.yearlyBookGoal = yearlyBookGoal
        self.dailyPagesGoal = dailyPagesGoal
        self.dailyMinutesGoal = dailyMinutesGoal
    }

    public var displayTitle: String {
        if ownerName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || ownerName == "Mein" {
            return "Mein Regal"
        }
        return ownerName.hasSuffix("s") ? "\(ownerName)’ Regal" : "\(ownerName)s Regal"
    }
}

// MARK: - Root Persisted Snapshot

public struct LibrarySnapshot: Codable {
    public var books: [Book]
    public var sessions: [ReadingSession]
    public var decor: [ShelfDecorItem]
    public var settings: ShelfSettings
    public var customTropes: [String]

    public init(
        books: [Book] = [],
        sessions: [ReadingSession] = [],
        decor: [ShelfDecorItem] = [],
        settings: ShelfSettings = ShelfSettings(),
        customTropes: [String] = []
    ) {
        self.books = books
        self.sessions = sessions
        self.decor = decor
        self.settings = settings
        self.customTropes = customTropes
    }
}

// MARK: - Color Hex Helper

public extension Color {
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&int)
        let r, g, b: UInt64
        switch cleaned.count {
        case 6:
            (r, g, b) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (44, 34, 28)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255.0,
            green: Double(g) / 255.0,
            blue: Double(b) / 255.0,
            opacity: 1.0
        )
    }
}

// MARK: - Built-in Popular Tropes

public enum BuiltInTropes {
    public static let all: [String] = [
        "Enemies to Lovers", "Found Family", "Slow Burn", "Dark Academia",
        "Morally Grey", "Chosen One", "Friends to Lovers", "Grumpy × Sunshine",
        "Forced Proximity", "Plot Twist", "Unreliable Narrator", "Magic Academy",
        "Heist", "Dystopie", "Second Chance", "Royalty", "Dragons",
        "Psychological Thriller", "Klassiker", "Philosophie", "Cozy Mystery",
        "Fake Dating", "Time Travel", "Fae", "Coming of Age", "Survival"
    ]
}
