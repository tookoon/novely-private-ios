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

// MARK: - Custom Shelf

public struct CustomShelf: Identifiable, Codable, Hashable {
    public var id: UUID
    public var name: String
    public var iconName: String

    public init(id: UUID = UUID(), name: String, iconName: String = "star.fill") {
        self.id = id
        self.name = name
        self.iconName = iconName
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

// MARK: - Daily Goal Mode

public enum DailyGoalMode: String, Codable, CaseIterable, Identifiable {
    case pages = "Seiten"
    case minutes = "Minuten"

    public var id: String { rawValue }
}

// MARK: - Growing Plant Gamification ("Zieh eine Pflanze groß")

public struct GrowingPlantState: Codable, Hashable {
    public var plantName: String
    public var isAdopted: Bool
    public var isBannerDismissed: Bool

    public init(plantName: String = "Monstera", isAdopted: Bool = false, isBannerDismissed: Bool = false) {
        self.plantName = plantName
        self.isAdopted = isAdopted
        self.isBannerDismissed = isBannerDismissed
    }
}

// MARK: - Book Quote

public struct BookQuote: Identifiable, Codable, Hashable {
    public var id: UUID
    public var text: String
    public var pageNumber: Int?
    public var dateAdded: Date
    public var note: String?
    public var isThought: Bool

    public init(
        id: UUID = UUID(),
        text: String,
        pageNumber: Int? = nil,
        dateAdded: Date = Date(),
        note: String? = nil,
        isThought: Bool = false
    ) {
        self.id = id
        self.text = text
        self.pageNumber = pageNumber
        self.dateAdded = dateAdded
        self.note = note
        self.isThought = isThought
    }
}

// MARK: - Book Model

public struct Book: Identifiable, Codable, Hashable {
    public var id: UUID
    public var title: String
    public var author: String
    public var isbn: String
    public var publisher: String
    public var publishedYear: String
    public var bindingType: String
    public var originalTitle: String
    public var bookDescription: String
    public var pageCount: Int
    public var currentPage: Int
    public var heightCm: Double
    public var shelf: ShelfCategory
    public var customShelfIDs: [UUID]
    public var displayStyle: BookDisplayStyle
    public var spineColorHex: String
    public var spineAccentHex: String
    public var spineTextColorHex: String
    public var spineTypography: SpineTypography
    public var coverURLString: String?
    public var customSpineFilename: String?
    public var customCoverFilename: String?
    public var rating: Double
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
        publishedYear: String = "",
        bindingType: String = "Gebunden",
        originalTitle: String = "",
        bookDescription: String = "",
        pageCount: Int = 320,
        currentPage: Int = 0,
        heightCm: Double = 21.0,
        shelf: ShelfCategory = .unread,
        customShelfIDs: [UUID] = [],
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
        self.publishedYear = publishedYear
        self.bindingType = bindingType
        self.originalTitle = originalTitle
        self.bookDescription = bookDescription
        self.pageCount = max(1, pageCount)
        self.currentPage = min(max(0, currentPage), max(1, pageCount))
        self.heightCm = min(max(16.0, heightCm), 28.0)
        self.shelf = shelf
        self.customShelfIDs = customShelfIDs
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

    public var spineWidthPoints: CGFloat {
        let clampedPages = min(max(Double(pageCount), 120), 1100)
        let normalized = (clampedPages - 120) / (1100 - 120)
        return CGFloat(24.0 + normalized * 24.0)
    }

    public var spineHeightPoints: CGFloat {
        let clampedCm = min(max(heightCm, 17.0), 26.0)
        let normalized = (clampedCm - 17.0) / (26.0 - 17.0)
        return CGFloat(104.0 + normalized * 34.0)
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
        roomTheme: ReadingRoomTheme = .catWinter
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
    case sleepingCat = "Katze"
    case monstera = "Pflanze"
    case candle = "Kerze"
    case snowman = "Schneemann"
    case snowGlobe = "Schneekugel"
    case coffeeMug = "Lesetasse"

    public var id: String { rawValue }

    public var symbolName: String {
        switch self {
        case .sleepingCat: return "cat.fill"
        case .monstera: return "leaf.fill"
        case .candle: return "flame.fill"
        case .snowman: return "snowflake"
        case .snowGlobe: return "sparkles"
        case .coffeeMug: return "cup.and.saucer.fill"
        }
    }
}

public struct ShelfDecorItem: Identifiable, Codable, Hashable {
    public var id: UUID
    public var kind: DecorKind
    public var rowIndex: Int
    /// 0 = left, 1 = middle, 2 = right (user can drag/shift freely!)
    public var slotIndex: Int
    public var isEnabled: Bool

    public init(id: UUID = UUID(), kind: DecorKind, rowIndex: Int, slotIndex: Int = 2, isEnabled: Bool = true) {
        self.id = id
        self.kind = kind
        self.rowIndex = rowIndex
        self.slotIndex = slotIndex
        self.isEnabled = isEnabled
    }
}

// MARK: - Warm Bookshelf Wall Themes (No longer pitch black!)

public enum ShelfWallTheme: String, Codable, CaseIterable, Identifiable {
    case warmOakCabinet = "Holzregal"
    case cozyCream = "Creme"
    case warmWalnut = "Walnuss"
    case sageLibrary = "Salbei"
    case espressoDark = "Dunkel"

    public var id: String { rawValue }

    public var topHex: String {
        switch self {
        case .warmOakCabinet: return "#5C402C"
        case .cozyCream: return "#CFC2AE"
        case .warmWalnut: return "#4E3626"
        case .sageLibrary: return "#384B40"
        case .espressoDark: return "#241C17"
        }
    }

    public var bottomHex: String {
        switch self {
        case .warmOakCabinet: return "#3A2618"
        case .cozyCream: return "#A89880"
        case .warmWalnut: return "#2B1C13"
        case .sageLibrary: return "#222E27"
        case .espressoDark: return "#14100E"
        }
    }

    public var usesWoodTextureImage: Bool {
        self == .warmOakCabinet
    }

    public var isLightTheme: Bool {
        self == .cozyCream
    }
}

public enum WoodFinish: String, Codable, CaseIterable, Identifiable {
    case oak = "Eiche"
    case walnut = "Walnuss"
    case honey = "Honigholz"
    case mahogany = "Mahagoni"

    public var id: String { rawValue }

    public var topHex: String {
        switch self {
        case .oak: return "#B48B5F"
        case .walnut: return "#7D563A"
        case .honey: return "#C79A63"
        case .mahogany: return "#69352B"
        }
    }

    public var frontHex: String {
        switch self {
        case .oak: return "#8C6843"
        case .walnut: return "#593A25"
        case .honey: return "#9E7342"
        case .mahogany: return "#47211A"
        }
    }

    public var sideHex: String {
        switch self {
        case .oak: return "#6E5032"
        case .walnut: return "#422A1B"
        case .honey: return "#7D5932"
        case .mahogany: return "#341611"
        }
    }
}

public enum ReadingRoomTheme: String, Codable, CaseIterable, Identifiable {
    case catWinter = "Katze"
    case dogShelf = "Hund"
    case rainyLibrary = "Regen"
    case fireplaceCabin = "Kamin"

    public var id: String { rawValue }

    public var imageAssetName: String {
        switch self {
        case .catWinter: return "ReadingRoomWinter"
        case .dogShelf: return "ReadingRoomDog"
        case .rainyLibrary: return "ReadingRoomRainy"
        case .fireplaceCabin: return "ReadingRoomFireplace"
        }
    }

    public var subtitle: String {
        switch self {
        case .catWinter: return "Schlafende Katze & Schneefall"
        case .dogShelf: return "Schlafender Hund auf dem Regal"
        case .rainyLibrary: return "Regentropfen am Bibliotheksfenster"
        case .fireplaceCabin: return "Prasselndes Kaminfeuer & Wärme"
        }
    }

    public var ambientIcon: String {
        switch self {
        case .catWinter: return "cat.fill"
        case .dogShelf: return "dog.fill"
        case .rainyLibrary: return "cloud.rain.fill"
        case .fireplaceCabin: return "flame.fill"
        }
    }
}

public struct ShelfSettings: Codable, Hashable {
    public var ownerName: String
    public var wallTheme: ShelfWallTheme
    public var woodFinish: WoodFinish
    public var customWallPhotoFilename: String?
    public var fairyLightsEnabled: Bool
    public var warmSpotlightsEnabled: Bool
    public var yearlyBookGoal: Int
    public var dailyGoalMode: DailyGoalMode
    public var dailyPagesGoal: Int
    public var dailyMinutesGoal: Int
    public var hasCompletedOnboarding: Bool

    public init(
        ownerName: String = "Mein",
        wallTheme: ShelfWallTheme = .warmOakCabinet,
        woodFinish: WoodFinish = .oak,
        customWallPhotoFilename: String? = nil,
        fairyLightsEnabled: Bool = true,
        warmSpotlightsEnabled: Bool = true,
        yearlyBookGoal: Int = 36,
        dailyGoalMode: DailyGoalMode = .pages,
        dailyPagesGoal: Int = 30,
        dailyMinutesGoal: Int = 25,
        hasCompletedOnboarding: Bool = false
    ) {
        self.ownerName = ownerName
        self.wallTheme = wallTheme
        self.woodFinish = woodFinish
        self.customWallPhotoFilename = customWallPhotoFilename
        self.fairyLightsEnabled = fairyLightsEnabled
        self.warmSpotlightsEnabled = warmSpotlightsEnabled
        self.yearlyBookGoal = yearlyBookGoal
        self.dailyGoalMode = dailyGoalMode
        self.dailyPagesGoal = dailyPagesGoal
        self.dailyMinutesGoal = dailyMinutesGoal
        self.hasCompletedOnboarding = hasCompletedOnboarding
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
    public var customShelves: [CustomShelf]
    public var plantState: GrowingPlantState
    public var settings: ShelfSettings
    public var customTropes: [String]

    public init(
        books: [Book] = [],
        sessions: [ReadingSession] = [],
        decor: [ShelfDecorItem] = [],
        customShelves: [CustomShelf] = [],
        plantState: GrowingPlantState = GrowingPlantState(),
        settings: ShelfSettings = ShelfSettings(),
        customTropes: [String] = []
    ) {
        self.books = books
        self.sessions = sessions
        self.decor = decor
        self.customShelves = customShelves
        self.plantState = plantState
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
