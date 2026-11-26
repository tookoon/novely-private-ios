import SwiftUI
import WidgetKit

// MARK: - Shared Timeline Entry

struct NovelyWidgetEntry: TimelineEntry {
    let date: Date
    let snapshot: LibrarySnapshot
}

struct NovelyTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> NovelyWidgetEntry {
        NovelyWidgetEntry(date: Date(), snapshot: defaultPreviewSnapshot())
    }

    func getSnapshot(in context: Context, completion: @escaping (NovelyWidgetEntry) -> Void) {
        let snap = LibraryStorage.loadSnapshot() ?? defaultPreviewSnapshot()
        completion(NovelyWidgetEntry(date: Date(), snapshot: snap))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<NovelyWidgetEntry>) -> Void) {
        let snap = LibraryStorage.loadSnapshot() ?? defaultPreviewSnapshot()
        let entry = NovelyWidgetEntry(date: Date(), snapshot: snap)
        let nextRefresh = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date().addingTimeInterval(1800)
        completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
    }

    private func defaultPreviewSnapshot() -> LibrarySnapshot {
        LibrarySnapshot(
            books: [
                Book(title: "Iron Flame", author: "Rebecca Yarros", pageCount: 960, currentPage: 960, heightCm: 23.5, shelf: .read, spineColorHex: "#1E1A18", spineAccentHex: "#E2A648"),
                Book(title: "Das Lied der Krähen", author: "Leigh Bardugo", pageCount: 592, currentPage: 592, heightCm: 21.8, shelf: .read, spineColorHex: "#8C2622", spineAccentHex: "#191514"),
                Book(title: "Animal Farm", author: "George Orwell", pageCount: 144, currentPage: 144, heightCm: 19.5, shelf: .read, displayStyle: .coverForward, spineColorHex: "#3C4F3D", spineAccentHex: "#E3B873"),
                Book(title: "Yellowface", author: "R. F. Kuang", pageCount: 352, currentPage: 301, heightCm: 21.2, shelf: .reading, spineColorHex: "#E6BC2F", spineAccentHex: "#191716", spineTextColorHex: "#191716")
            ],
            decor: [ShelfDecorItem(kind: .monstera, rowIndex: 0, isEnabled: true)],
            settings: ShelfSettings()
        )
    }
}

// MARK: - 1. Home Screen Bookshelf Widget (Small, Medium, Large)

struct BookshelfWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: NovelyWidgetEntry

    private var readBooks: [Book] {
        let filtered = entry.snapshot.books.filter { $0.shelf == .read }
        return filtered.isEmpty ? entry.snapshot.books : filtered
    }

    var body: some View {
        let settings = entry.snapshot.settings
        ZStack(alignment: .bottomLeading) {
            VStack(spacing: family == .systemLarge ? 10 : 0) {
                if family == .systemLarge {
                    BookshelfTierView(
                        books: Array(readBooks.prefix(5)),
                        decorItem: ShelfDecorItem(kind: .monstera, rowIndex: 0, isEnabled: true),
                        woodFinish: settings.woodFinish,
                        fairyLightsEnabled: settings.fairyLightsEnabled,
                        scale: 0.72
                    )
                    BookshelfTierView(
                        books: Array(readBooks.dropFirst(5).prefix(6)),
                        decorItem: ShelfDecorItem(kind: .candle, rowIndex: 1, isEnabled: true),
                        woodFinish: settings.woodFinish,
                        fairyLightsEnabled: settings.fairyLightsEnabled,
                        scale: 0.72
                    )
                } else {
                    BookshelfTierView(
                        books: Array(readBooks.prefix(family == .systemSmall ? 3 : 6)),
                        decorItem: family == .systemMedium ? ShelfDecorItem(kind: .monstera, rowIndex: 0, isEnabled: true) : nil,
                        woodFinish: settings.woodFinish,
                        fairyLightsEnabled: settings.fairyLightsEnabled,
                        scale: family == .systemSmall ? 0.62 : 0.68
                    )
                }
            }
            .padding(.bottom, 16)

            Text("Gelesen · \(readBooks.count) Bücher")
                .font(.system(size: 11, weight: .semibold, design: .serif))
                .foregroundStyle(NovelyTheme.creamText.opacity(0.9))
                .padding(.horizontal, 10)
                .padding(.bottom, 4)
        }
        .containerBackground(for: .widget) {
            LinearGradient(
                colors: [Color(hex: settings.wallTheme.topHex), Color(hex: settings.wallTheme.bottomHex)],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .widgetURL(URL(string: "novelyprivate://shelf/Gelesen"))
    }
}

struct BookshelfHomeWidget: Widget {
    let kind = "BookshelfHomeWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: NovelyTimelineProvider()) { entry in
            BookshelfWidgetView(entry: entry)
        }
        .configurationDisplayName("Dein Bücherregal")
        .description("Zeigt dein echtes Bücherregal mit Buchrücken & Deko direkt auf dem Homescreen.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - 2. Currently Reading Widget (Home Screen & Lock Screen)

struct CurrentlyReadingWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: NovelyWidgetEntry

    private var currentBook: Book? {
        entry.snapshot.books.first(where: { $0.shelf == .reading }) ?? entry.snapshot.books.first
    }

    var body: some View {
        Group {
            if let book = currentBook {
                if family == .accessoryRectangular {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(book.title)
                            .font(.system(size: 12, weight: .bold))
                            .lineLimit(1)
                        ProgressView(value: book.progress)
                        Text("S. \(book.currentPage)/\(book.pageCount) (\(book.progressPercent)%)")
                            .font(.system(size: 10))
                    }
                } else {
                    HStack(spacing: 12) {
                        BookCoverForwardView(book: book, scale: family == .systemSmall ? 0.48 : 0.62)
                        VStack(alignment: .leading, spacing: 5) {
                            Text("LIEST GERADE")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(NovelyTheme.terracotta)
                            Text(book.title)
                                .font(.system(size: 15, weight: .bold, design: .serif))
                                .foregroundStyle(NovelyTheme.creamText)
                                .lineLimit(2)
                            Text("Seite \(book.currentPage) von \(book.pageCount)")
                                .font(.system(size: 11))
                                .foregroundStyle(NovelyTheme.warmMutedText)
                            ProgressView(value: book.progress)
                                .tint(NovelyTheme.terracotta)
                        }
                    }
                    .padding(4)
                }
            } else {
                Text("Kein aktuelles Buch")
                    .font(.caption)
                    .foregroundStyle(NovelyTheme.warmMutedText)
            }
        }
        .containerBackground(for: .widget) {
            Color(hex: "#181310")
        }
        .widgetURL(URL(string: "novelyprivate://shelf/Aktuell"))
    }
}

struct CurrentlyReadingWidget: Widget {
    let kind = "CurrentlyReadingWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: NovelyTimelineProvider()) { entry in
            CurrentlyReadingWidgetView(entry: entry)
        }
        .configurationDisplayName("Liest gerade")
        .description("Dein aktuelles Buch und Lesefortschritt auf einen Blick.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular])
    }
}

// MARK: - Widget Bundle Entry Point

@main
struct NovelyWidgetsBundle: WidgetBundle {
    var body: some Widget {
        BookshelfHomeWidget()
        CurrentlyReadingWidget()
    }
}
