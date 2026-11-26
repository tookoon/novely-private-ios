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
                Book(title: "Throne of Glass", author: "Sarah J. Maas", pageCount: 512, currentPage: 512, heightCm: 22.0, shelf: .read, displayStyle: .coverForward, spineColorHex: "#142738", spineAccentHex: "#D4AF37"),
                Book(title: "Yellowface", author: "R. F. Kuang", pageCount: 352, currentPage: 301, heightCm: 21.2, shelf: .reading, spineColorHex: "#E6BC2F", spineAccentHex: "#191716", spineTextColorHex: "#191716")
            ],
            decor: [
                ShelfDecorItem(kind: .sleepingCat, rowIndex: 0, slotIndex: 2, isEnabled: true),
                ShelfDecorItem(kind: .monstera, rowIndex: 1, slotIndex: 0, isEnabled: true)
            ],
            settings: ShelfSettings()
        )
    }
}

// MARK: - 1. Home Screen Bookshelf Widget (Warm Wooden Cabinet + Draped Fairy Lights + Real Covers + Cat!)

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
            VStack(spacing: family == .systemLarge ? 6 : 0) {
                if family == .systemLarge {
                    BookshelfTierView(
                        books: Array(readBooks.prefix(4)),
                        decorItems: [ShelfDecorItem(kind: .sleepingCat, rowIndex: 0, slotIndex: 2, isEnabled: true)],
                        woodFinish: settings.woodFinish,
                        fairyLightsEnabled: settings.fairyLightsEnabled,
                        scale: 0.68
                    )
                    BookshelfTierView(
                        books: Array(readBooks.dropFirst(4).prefix(5)),
                        decorItems: [ShelfDecorItem(kind: .monstera, rowIndex: 1, slotIndex: 0, isEnabled: true)],
                        woodFinish: settings.woodFinish,
                        fairyLightsEnabled: settings.fairyLightsEnabled,
                        scale: 0.68
                    )
                } else {
                    BookshelfTierView(
                        books: Array(readBooks.prefix(family == .systemSmall ? 2 : 5)),
                        decorItems: family == .systemMedium ? [ShelfDecorItem(kind: .sleepingCat, rowIndex: 0, slotIndex: 2, isEnabled: true)] : [],
                        woodFinish: settings.woodFinish,
                        fairyLightsEnabled: settings.fairyLightsEnabled,
                        scale: family == .systemSmall ? 0.58 : 0.65
                    )
                }
            }
            .padding(.bottom, 14)

            Text("Gelesen · \(readBooks.count) Bücher")
                .font(.system(size: 11, weight: .semibold, design: .serif))
                .foregroundStyle(NovelyTheme.creamText)
                .shadow(color: .black.opacity(0.6), radius: 2)
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
        .description("Zeigt dein warmes Holz-Bücherregal mit echten Covern, Katze & Lichterkette.")
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
            Color(hex: "#2B1E16")
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

@main
struct NovelyWidgetsBundle: WidgetBundle {
    var body: some Widget {
        BookshelfHomeWidget()
        CurrentlyReadingWidget()
    }
}
