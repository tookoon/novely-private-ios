import SwiftUI
import UIKit

// MARK: - iOS 26 Native Liquid Glass Modifiers

public extension View {
    /// Applies real native iOS 26 `.glassEffect()` when compiled & running on iOS 26+,
    /// with a lush specular dark-glass fallback on iOS 18.
    @ViewBuilder
    func novelyLiquidGlass<S: InsettableShape>(
        in shape: S,
        tint: Color? = nil,
        interactive: Bool = false
    ) -> some View {
        #if compiler(>=6.2)
        if #available(iOS 26.0, *) {
            if let tint {
                self.glassEffect(
                    interactive ? .regular.tint(tint).interactive() : .regular.tint(tint),
                    in: shape
                )
            } else {
                self.glassEffect(
                    interactive ? .regular.interactive() : .regular,
                    in: shape
                )
            }
        } else {
            self
                .background(.ultraThinMaterial, in: shape)
                .overlay(
                    shape.strokeBorder(
                        LinearGradient(
                            colors: [.white.opacity(0.28), .white.opacity(0.06)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.8
                    )
                )
        }
        #else
        self
            .background(.ultraThinMaterial, in: shape)
            .overlay(
                shape.strokeBorder(
                    LinearGradient(
                        colors: [.white.opacity(0.28), .white.opacity(0.06)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.8
                )
            )
        #endif
    }

    @ViewBuilder
    func novelyGlassCapsule(tint: Color? = nil, interactive: Bool = true) -> some View {
        self.novelyLiquidGlass(in: Capsule(), tint: tint, interactive: interactive)
    }

    @ViewBuilder
    func novelyGlassCard(cornerRadius: CGFloat = 22, tint: Color? = nil) -> some View {
        self.novelyLiquidGlass(in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous), tint: tint, interactive: false)
    }
}

// MARK: - Cozy Palette Constants

public enum NovelyTheme {
    public static let creamText = Color(hex: "#F4EDE2")
    public static let warmMutedText = Color(hex: "#B8AA99")
    public static let terracotta = Color(hex: "#D8684D")
    public static let warmGold = Color(hex: "#E6C27A")
    public static let espressoBg = Color(hex: "#14110F")
    public static let cardDarkBg = Color(hex: "#1E1916")
}

// MARK: - Wooden Shelf Plank with Realistic Grain & Fairy Lights

public struct WoodenShelfPlank: View {
    public let woodFinish: WoodFinish
    public let fairyLightsEnabled: Bool
    public let compact: Bool

    public init(woodFinish: WoodFinish, fairyLightsEnabled: Bool = true, compact: Bool = false) {
        self.woodFinish = woodFinish
        self.fairyLightsEnabled = fairyLightsEnabled
        self.compact = compact
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Top surface bevel (depth perspective)
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: woodFinish.topHex).opacity(0.72),
                            Color(hex: woodFinish.topHex)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(height: compact ? 5 : 8)
                .overlay(alignment: .bottom) {
                    Rectangle()
                        .fill(Color.white.opacity(0.14))
                        .frame(height: 0.7)
                }

            // Front edge of wooden plank
            ZStack {
                LinearGradient(
                    colors: [
                        Color(hex: woodFinish.frontHex),
                        Color(hex: woodFinish.frontHex).opacity(0.84),
                        Color.black.opacity(0.65)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )

                // Subtle horizontal wood grain streaks
                VStack(spacing: compact ? 2 : 3) {
                    Rectangle().fill(Color.black.opacity(0.14)).frame(height: 1)
                    Rectangle().fill(Color.white.opacity(0.04)).frame(height: 0.8)
                    Rectangle().fill(Color.black.opacity(0.10)).frame(height: 1)
                }
                .padding(.horizontal, 4)

                // Warm glowing fairy lights along the shelf lip
                if fairyLightsEnabled {
                    HStack {
                        ForEach(0..<(compact ? 7 : 11), id: \.self) { idx in
                            Spacer(minLength: 0)
                            Circle()
                                .fill(Color(hex: "#FFE6A7"))
                                .frame(width: compact ? 3 : 4.2, height: compact ? 3 : 4.2)
                                .shadow(color: Color(hex: "#FFBE5C").opacity(0.95), radius: compact ? 3 : 5)
                                .offset(y: idx.isMultiple(of: 2) ? 1.5 : -0.5)
                            Spacer(minLength: 0)
                        }
                    }
                    .padding(.horizontal, 8)
                }
            }
            .frame(height: compact ? 10 : 16)
            .clipShape(RoundedRectangle(cornerRadius: 2.5))
            .shadow(color: Color.black.opacity(0.68), radius: compact ? 5 : 9, x: 0, y: compact ? 4 : 7)

            // Warm under-shelf glow
            if fairyLightsEnabled {
                LinearGradient(
                    colors: [
                        Color(hex: "#FFB84D").opacity(0.18),
                        Color.clear
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: compact ? 8 : 14)
                .allowsHitTesting(false)
            }
        }
    }
}

// MARK: - Realistic 3D Book Spine

public struct BookSpineView: View {
    public let book: Book
    public let scale: CGFloat

    public init(book: Book, scale: CGFloat = 1.0) {
        self.book = book
        self.scale = scale
    }

    private var customSpineImage: UIImage? {
        guard let data = LibraryStorage.loadImageData(filename: book.customSpineFilename) else { return nil }
        return UIImage(data: data)
    }

    private var titleFont: Font {
        let size = max(8.5, 11.5 * scale)
        switch book.spineTypography {
        case .serif:
            return .system(size: size, weight: .semibold, design: .serif)
        case .modern:
            return .system(size: size, weight: .bold, design: .rounded)
        case .condensed:
            return .system(size: size, weight: .medium, design: .serif).italic()
        case .ornate:
            return .system(size: size, weight: .heavy, design: .serif)
        }
    }

    public var body: some View {
        let width = book.spineWidthPoints * scale
        let height = book.spineHeightPoints * scale

        ZStack {
            if let uiImage = customSpineImage {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: width, height: height)
                    .clipped()
            } else {
                // Base spine cloth/hardcover color
                RoundedRectangle(cornerRadius: 3 * scale, style: .continuous)
                    .fill(Color(hex: book.spineColorHex))

                // Decorative top & bottom foil bands
                VStack {
                    Rectangle()
                        .fill(Color(hex: book.spineAccentHex).opacity(0.85))
                        .frame(height: max(2, 3.5 * scale))
                        .padding(.top, 9 * scale)
                    Spacer()
                    if book.seriesIndex != nil {
                        Text("\(book.seriesIndex!)")
                            .font(.system(size: max(7, 8.5 * scale), weight: .bold, design: .serif))
                            .foregroundStyle(Color(hex: book.spineAccentHex))
                            .padding(.bottom, 2 * scale)
                    }
                    Rectangle()
                        .fill(Color(hex: book.spineAccentHex).opacity(0.85))
                        .frame(height: max(2, 3.5 * scale))
                        .padding(.bottom, 9 * scale)
                }

                // Vertical spine title (leaves extra room at bottom if series badge is shown)
                let verticalInset: CGFloat = book.seriesIndex != nil ? 46 * scale : 30 * scale
                Text(book.title)
                    .font(titleFont)
                    .foregroundStyle(Color(hex: book.spineTextColorHex))
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)
                    .frame(width: max(30, height - verticalInset), height: width - 4 * scale)
                    .rotationEffect(.degrees(-90))
                    .offset(y: book.seriesIndex != nil ? -5 * scale : 0)
            }

            // 3D cylindrical spine shading (left hinge highlight + right shadow)
            LinearGradient(
                stops: [
                    .init(color: .black.opacity(0.32), location: 0.0),
                    .init(color: .white.opacity(0.24), location: 0.14),
                    .init(color: .white.opacity(0.05), location: 0.38),
                    .init(color: .black.opacity(0.04), location: 0.72),
                    .init(color: .black.opacity(0.42), location: 1.0)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )

            // Lent-to borrower pill tag on spine
            if let borrower = book.lentTo, !borrower.isEmpty, scale >= 0.75 {
                VStack {
                    Spacer()
                    Text(borrower.prefix(6))
                        .font(.system(size: 7.5 * scale, weight: .bold))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 3)
                        .padding(.vertical, 1.5)
                        .background(NovelyTheme.warmGold, in: Capsule())
                        .padding(.bottom, 4 * scale)
                }
            }
        }
        .frame(width: width, height: height)
        .clipShape(RoundedRectangle(cornerRadius: 3 * scale, style: .continuous))
        .shadow(color: .black.opacity(0.5), radius: 3 * scale, x: 1.5 * scale, y: 2 * scale)
    }
}

// MARK: - Front-Facing Book Cover on Shelf

public struct BookCoverForwardView: View {
    public let book: Book
    public let scale: CGFloat

    public init(book: Book, scale: CGFloat = 1.0) {
        self.book = book
        self.scale = scale
    }

    private var customCoverImage: UIImage? {
        guard let data = LibraryStorage.loadImageData(filename: book.customCoverFilename) else { return nil }
        return UIImage(data: data)
    }

    public var body: some View {
        let height = book.spineHeightPoints * scale
        let width = height * 0.67

        ZStack {
            if let uiImage = customCoverImage {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: width, height: height)
                    .clipped()
            } else {
                // Rich hardcover gradient
                LinearGradient(
                    colors: [
                        Color(hex: book.spineColorHex),
                        Color(hex: book.spineColorHex).opacity(0.78)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                // Ornate inner border frame
                RoundedRectangle(cornerRadius: 3 * scale)
                    .strokeBorder(Color(hex: book.spineAccentHex).opacity(0.55), lineWidth: max(0.8, 1.1 * scale))
                    .padding(6 * scale)

                VStack(spacing: 4 * scale) {
                    Spacer(minLength: 4 * scale)
                    Text(book.title)
                        .font(.system(size: max(8.5, 11.5 * scale), weight: .bold, design: .serif))
                        .foregroundStyle(Color(hex: book.spineTextColorHex))
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                        .minimumScaleFactor(0.65)
                        .padding(.horizontal, 7 * scale)

                    Rectangle()
                        .fill(Color(hex: book.spineAccentHex).opacity(0.8))
                        .frame(width: 18 * scale, height: 1.2 * scale)

                    Text(book.author)
                        .font(.system(size: max(6.5, 8.2 * scale), weight: .medium))
                        .foregroundStyle(Color(hex: book.spineTextColorHex).opacity(0.82))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .padding(.horizontal, 6 * scale)
                    Spacer(minLength: 4 * scale)
                }
            }

            // Realistic book hinge crease on left + gloss sheen
            HStack(spacing: 0) {
                LinearGradient(
                    colors: [.black.opacity(0.38), .white.opacity(0.22), .clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: 8 * scale)
                Spacer()
            }

            LinearGradient(
                colors: [.white.opacity(0.16), .clear, .black.opacity(0.18)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        .frame(width: width, height: height)
        .clipShape(RoundedRectangle(cornerRadius: 4 * scale, style: .continuous))
        .shadow(color: .black.opacity(0.55), radius: 5 * scale, x: 2 * scale, y: 3 * scale)
    }
}

// MARK: - Horizontal Book Stack

public struct BookStackView: View {
    public let books: [Book]
    public let scale: CGFloat
    public let onTapBook: ((Book) -> Void)?

    public init(books: [Book], scale: CGFloat = 1.0, onTapBook: ((Book) -> Void)? = nil) {
        self.books = books
        self.scale = scale
        self.onTapBook = onTapBook
    }

    public var body: some View {
        VStack(spacing: 1 * scale) {
            ForEach(books) { book in
                let stackWidth = min(116 * scale, max(84 * scale, book.spineHeightPoints * 0.82 * scale))
                let stackHeight = max(17 * scale, book.spineWidthPoints * 0.68 * scale)

                ZStack {
                    RoundedRectangle(cornerRadius: 2.5 * scale)
                        .fill(Color(hex: book.spineColorHex))

                    // Subtle top/bottom cylindrical shading
                    LinearGradient(
                        colors: [.white.opacity(0.22), .clear, .black.opacity(0.35)],
                        startPoint: .top,
                        endPoint: .bottom
                    )

                    // Left & right accent bands
                    HStack {
                        Rectangle()
                            .fill(Color(hex: book.spineAccentHex).opacity(0.85))
                            .frame(width: 3 * scale)
                            .padding(.leading, 8 * scale)
                        Spacer()
                        Text(book.title)
                            .font(.system(size: max(7, 9 * scale), weight: .semibold, design: .serif))
                            .foregroundStyle(Color(hex: book.spineTextColorHex))
                            .lineLimit(1)
                            .minimumScaleFactor(0.65)
                        Spacer()
                        Rectangle()
                            .fill(Color(hex: book.spineAccentHex).opacity(0.85))
                            .frame(width: 3 * scale)
                            .padding(.trailing, 8 * scale)
                    }
                }
                .frame(width: stackWidth, height: stackHeight)
                .clipShape(RoundedRectangle(cornerRadius: 2.5 * scale))
                .shadow(color: .black.opacity(0.45), radius: 2.5 * scale, x: 0, y: 1.5 * scale)
                .onTapGesture {
                    onTapBook?(book)
                }
            }
        }
    }
}

// MARK: - Cozy Shelf Decor Objects

public struct ShelfDecorView: View {
    public let kind: DecorKind
    public let scale: CGFloat

    public init(kind: DecorKind, scale: CGFloat = 1.0) {
        self.kind = kind
        self.scale = scale
    }

    public var body: some View {
        switch kind {
        case .candle:
            candleView
        case .monstera:
            monsteraView
        case .snowGlobe:
            snowGlobeView
        case .coffeeMug:
            coffeeMugView
        case .hourglass:
            hourglassView
        case .pinecones:
            pineconesView
        }
    }

    private var candleView: some View {
        VStack(spacing: 0) {
            // Flame glow
            ZStack {
                Circle()
                    .fill(Color(hex: "#FFB347").opacity(0.42))
                    .frame(width: 24 * scale, height: 24 * scale)
                    .blur(radius: 6 * scale)
                Ellipse()
                    .fill(
                        LinearGradient(
                            colors: [.white, Color(hex: "#FFD166"), Color(hex: "#F77F00")],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .frame(width: 6 * scale, height: 11 * scale)
            }
            .offset(y: 3 * scale)

            // Wax pillar
            RoundedRectangle(cornerRadius: 3 * scale)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "#F5ECD8"), Color(hex: "#D9C9AE"), Color(hex: "#B5A184")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: 22 * scale, height: 42 * scale)
                .overlay(alignment: .top) {
                    Ellipse()
                        .fill(Color(hex: "#FFF7E6"))
                        .frame(width: 20 * scale, height: 5 * scale)
                }

            // Brass holder base
            RoundedRectangle(cornerRadius: 2 * scale)
                .fill(Color(hex: "#8A6D3B"))
                .frame(width: 28 * scale, height: 5 * scale)
        }
        .shadow(color: .black.opacity(0.4), radius: 3 * scale, y: 2 * scale)
    }

    private var monsteraView: some View {
        VStack(spacing: -4 * scale) {
            ZStack {
                Image(systemName: "leaf.fill")
                    .font(.system(size: 24 * scale))
                    .foregroundStyle(Color(hex: "#2D6A4F"))
                    .rotationEffect(.degrees(-28))
                    .offset(x: -10 * scale, y: 4 * scale)
                Image(systemName: "leaf.fill")
                    .font(.system(size: 26 * scale))
                    .foregroundStyle(Color(hex: "#40916C"))
                    .rotationEffect(.degrees(22))
                    .offset(x: 9 * scale, y: 2 * scale)
                Image(systemName: "leaf.fill")
                    .font(.system(size: 22 * scale))
                    .foregroundStyle(Color(hex: "#52B788"))
                    .offset(y: -6 * scale)
            }
            .frame(height: 36 * scale)

            // Terracotta pot
            VStack(spacing: 0) {
                RoundedRectangle(cornerRadius: 2 * scale)
                    .fill(Color(hex: "#C06C47"))
                    .frame(width: 34 * scale, height: 7 * scale)
                RoundedRectangle(cornerRadius: 4 * scale)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "#B25E3B"), Color(hex: "#7D3E24")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 28 * scale, height: 24 * scale)
            }
        }
        .shadow(color: .black.opacity(0.45), radius: 3 * scale, y: 2 * scale)
    }

    private var snowGlobeView: some View {
        VStack(spacing: -2 * scale) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color(hex: "#B8D8E8").opacity(0.45), Color(hex: "#2B4C5E").opacity(0.65)],
                            center: .topLeading,
                            startRadius: 2,
                            endRadius: 20 * scale
                        )
                    )
                    .frame(width: 34 * scale, height: 34 * scale)
                    .overlay(
                        Circle().strokeBorder(.white.opacity(0.35), lineWidth: 1)
                    )

                Image(systemName: "tree.fill")
                    .font(.system(size: 13 * scale))
                    .foregroundStyle(Color(hex: "#2D5A3E"))
                    .offset(y: 4 * scale)

                Image(systemName: "sparkles")
                    .font(.system(size: 10 * scale))
                    .foregroundStyle(.white.opacity(0.85))
                    .offset(x: -5 * scale, y: -5 * scale)
            }

            RoundedRectangle(cornerRadius: 3 * scale)
                .fill(Color(hex: "#4A2E1E"))
                .frame(width: 28 * scale, height: 10 * scale)
        }
        .shadow(color: .black.opacity(0.4), radius: 3 * scale, y: 2 * scale)
    }

    private var coffeeMugView: some View {
        VStack(spacing: 2 * scale) {
            Image(systemName: "wind")
                .font(.system(size: 10 * scale))
                .foregroundStyle(.white.opacity(0.45))
                .rotationEffect(.degrees(-90))
            HStack(spacing: -2 * scale) {
                RoundedRectangle(cornerRadius: 4 * scale)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "#D8CFC2"), Color(hex: "#A69B8C")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 24 * scale, height: 24 * scale)
                Circle()
                    .strokeBorder(Color(hex: "#B8AEA0"), lineWidth: 3 * scale)
                    .frame(width: 11 * scale, height: 11 * scale)
            }
        }
        .shadow(color: .black.opacity(0.4), radius: 3 * scale, y: 2 * scale)
    }

    private var hourglassView: some View {
        ZStack {
            Image(systemName: "hourglass")
                .font(.system(size: 32 * scale, weight: .light))
                .foregroundStyle(NovelyTheme.warmGold)
        }
        .shadow(color: .black.opacity(0.45), radius: 3 * scale, y: 2 * scale)
    }

    private var pineconesView: some View {
        HStack(spacing: 2 * scale) {
            Image(systemName: "aqi.medium")
                .font(.system(size: 18 * scale))
                .foregroundStyle(Color(hex: "#7F5539"))
            Image(systemName: "aqi.medium")
                .font(.system(size: 14 * scale))
                .foregroundStyle(Color(hex: "#9C6644"))
                .offset(y: 2 * scale)
        }
        .shadow(color: .black.opacity(0.45), radius: 2 * scale, y: 2 * scale)
    }
}

// MARK: - Complete Shelf Tier (Books + Stacks + Decor + Wooden Plank)

public struct BookshelfTierView: View {
    public let books: [Book]
    public let decorItem: ShelfDecorItem?
    public let woodFinish: WoodFinish
    public let fairyLightsEnabled: Bool
    public let scale: CGFloat
    public let onTapBook: ((Book) -> Void)?

    public init(
        books: [Book],
        decorItem: ShelfDecorItem? = nil,
        woodFinish: WoodFinish,
        fairyLightsEnabled: Bool = true,
        scale: CGFloat = 1.0,
        onTapBook: ((Book) -> Void)? = nil
    ) {
        self.books = books
        self.decorItem = decorItem
        self.woodFinish = woodFinish
        self.fairyLightsEnabled = fairyLightsEnabled
        self.scale = scale
        self.onTapBook = onTapBook
    }

    private var uprightBooks: [Book] {
        books.filter { $0.displayStyle != .stacked }
    }

    private var stackedBooks: [Book] {
        books.filter { $0.displayStyle == .stacked }
    }

    public var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .bottom, spacing: 4 * scale) {
                if let decorItem, decorItem.isEnabled, decorItem.rowIndex % 2 == 0 {
                    ShelfDecorView(kind: decorItem.kind, scale: scale)
                        .padding(.trailing, 4 * scale)
                }

                if !stackedBooks.isEmpty {
                    BookStackView(books: stackedBooks, scale: scale, onTapBook: onTapBook)
                        .padding(.trailing, 4 * scale)
                }

                ForEach(uprightBooks) { book in
                    Group {
                        if book.displayStyle == .coverForward {
                            BookCoverForwardView(book: book, scale: scale)
                        } else {
                            BookSpineView(book: book, scale: scale)
                        }
                    }
                    .onTapGesture {
                        onTapBook?(book)
                    }
                }

                if let decorItem, decorItem.isEnabled, decorItem.rowIndex % 2 == 1 {
                    ShelfDecorView(kind: decorItem.kind, scale: scale)
                        .padding(.leading, 4 * scale)
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 14 * scale)
            .frame(minHeight: 112 * scale, alignment: .bottom)

            WoodenShelfPlank(
                woodFinish: woodFinish,
                fairyLightsEnabled: fairyLightsEnabled,
                compact: scale < 0.75
            )
            .padding(.horizontal, 4 * scale)
        }
    }
}
