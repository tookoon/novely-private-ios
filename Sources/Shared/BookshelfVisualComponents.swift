import SwiftUI
import UIKit

// MARK: - iOS 26 Native Liquid Glass Modifiers

public extension View {
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
    public static let creamText = Color(hex: "#F6F0E6")
    public static let warmMutedText = Color(hex: "#C5B8A6")
    public static let terracotta = Color(hex: "#D8684D")
    public static let warmGold = Color(hex: "#E8C379")
    public static let espressoBg = Color(hex: "#1A1411")
    public static let cardDarkBg = Color(hex: "#231B16")
}

// MARK: - Warm Real Wooden Bookshelf Cabinet Backdrop

public struct BookshelfCabinetBackdrop: View {
    public let settings: ShelfSettings

    public init(settings: ShelfSettings) {
        self.settings = settings
    }

    private var customWallImage: UIImage? {
        guard let data = LibraryStorage.loadImageData(filename: settings.customWallPhotoFilename) else { return nil }
        return UIImage(data: data)
    }

    public var body: some View {
        ZStack {
            if let uiImage = customWallImage {
                GeometryReader { geo in
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipped()
                }
                .overlay(Color.black.opacity(0.22))
            } else if settings.wallTheme.usesWoodTextureImage {
                GeometryReader { geo in
                    Image("WoodShelfTexture")
                        .resizable()
                        .scaledToFill()
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipped()
                }
                .overlay(
                    // Subtle warm readability vignette at very top & bottom for header/tabbar
                    LinearGradient(
                        stops: [
                            .init(color: Color(hex: "#1C120B").opacity(0.55), location: 0.0),
                            .init(color: Color.clear, location: 0.22),
                            .init(color: Color.clear, location: 0.80),
                            .init(color: Color(hex: "#140D08").opacity(0.55), location: 1.0)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            } else {
                LinearGradient(
                    colors: [
                        Color(hex: settings.wallTheme.topHex),
                        Color(hex: settings.wallTheme.bottomHex)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )

                // Recessed wooden cabinet side-pillars for real 3D bookshelf feel!
                HStack(spacing: 0) {
                    LinearGradient(
                        colors: [Color(hex: settings.woodFinish.sideHex), Color.black.opacity(0.35), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: 18)
                    Spacer()
                    LinearGradient(
                        colors: [.clear, Color.black.opacity(0.35), Color(hex: settings.woodFinish.sideHex)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: 18)
                }
            }

            // Warm top gallery spotlight
            if settings.warmSpotlightsEnabled {
                RadialGradient(
                    colors: [
                        Color(hex: "#FFD28A").opacity(0.22),
                        Color.clear
                    ],
                    center: .top,
                    startRadius: 15,
                    endRadius: 340
                )
                .allowsHitTesting(false)
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Draped Fairy Light String with Real Swagged Cord & Warm Bulbs

public struct DrapedFairyLightString: View {
    public let compact: Bool

    public init(compact: Bool = false) {
        self.compact = compact
    }

    public var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let swags = compact ? 3 : 4
            let segW = w / CGFloat(swags)
            let dip: CGFloat = compact ? 7 : 12

            ZStack {
                // Fine dark-bronze draped wire cord (catenary swags)
                Path { path in
                    path.move(to: CGPoint(x: 4, y: 1))
                    for i in 0..<swags {
                        let x0 = 4 + CGFloat(i) * (segW - 2)
                        let x1 = 4 + CGFloat(i + 1) * (segW - 2)
                        let midX = (x0 + x1) * 0.5
                        path.addQuadCurve(
                            to: CGPoint(x: min(x1, w - 4), y: 1),
                            control: CGPoint(x: midX, y: dip * 2.0)
                        )
                    }
                }
                .stroke(
                    Color(hex: "#2A1F18").opacity(0.88),
                    style: StrokeStyle(lineWidth: compact ? 1.0 : 1.35, lineCap: .round)
                )

                // Warm glowing fairy bulbs attached right onto the curved cord!
                ForEach(0..<swags, id: \.self) { i in
                    let x0 = 4 + CGFloat(i) * (segW - 2)
                    let x1 = min(4 + CGFloat(i + 1) * (segW - 2), w - 4)
                    ForEach([0.22, 0.50, 0.78], id: \.self) { t in
                        let bx = x0 + (x1 - x0) * CGFloat(t)
                        // Quadratic Bezier y(t) = 2(1-t)t * controlY + (1-t)^2 * y0 + t^2 * y1
                        let by = 1 + 2 * CGFloat(1 - t) * CGFloat(t) * (dip * 2.0)

                        ZStack {
                            // Soft golden light halo
                            Circle()
                                .fill(Color(hex: "#FFC45C").opacity(0.45))
                                .frame(width: compact ? 11 : 16, height: compact ? 11 : 16)
                                .blur(radius: compact ? 3 : 4.5)

                            // Tiny dark socket + bright warm bulb
                            VStack(spacing: -0.5) {
                                Rectangle()
                                    .fill(Color(hex: "#3B2D23"))
                                    .frame(width: compact ? 2 : 2.6, height: compact ? 2 : 2.8)
                                Ellipse()
                                    .fill(Color(hex: "#FFF3CC"))
                                    .frame(width: compact ? 3.8 : 5.2, height: compact ? 4.8 : 6.4)
                                    .shadow(color: Color(hex: "#FFB732"), radius: compact ? 2.5 : 4)
                            }
                        }
                        .position(x: bx, y: by + (compact ? 2.2 : 3.2))
                    }
                }
            }
        }
        .frame(height: compact ? 16 : 24)
        .allowsHitTesting(false)
    }
}

// MARK: - Wooden Shelf Plank with Realistic Wood Grain & Draped Fairy Lights

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
            // Top surface ledge (3D perspective depth where books & cat rest)
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: woodFinish.topHex).opacity(0.62),
                            Color(hex: woodFinish.topHex)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(height: compact ? 6 : 10)
                .overlay(alignment: .bottom) {
                    Rectangle()
                        .fill(Color.white.opacity(0.22))
                        .frame(height: 0.8)
                }

            // Thick front edge of wooden plank with realistic wood grain
            ZStack {
                LinearGradient(
                    colors: [
                        Color(hex: woodFinish.frontHex),
                        Color(hex: woodFinish.sideHex),
                        Color.black.opacity(0.55)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )

                VStack(spacing: compact ? 2 : 3.5) {
                    Rectangle().fill(Color.black.opacity(0.16)).frame(height: 1)
                    Rectangle().fill(Color.white.opacity(0.08)).frame(height: 0.7)
                    Rectangle().fill(Color.black.opacity(0.12)).frame(height: 1)
                }
                .padding(.horizontal, 6)
            }
            .frame(height: compact ? 11 : 17)
            .clipShape(RoundedRectangle(cornerRadius: 2.5))
            .shadow(color: Color.black.opacity(0.58), radius: compact ? 5 : 10, x: 0, y: compact ? 4 : 8)

            // Real draped fairy light string hanging right underneath the shelf edge!
            if fairyLightsEnabled {
                DrapedFairyLightString(compact: compact)
                    .padding(.horizontal, 6)
                    .offset(y: -2)
            } else {
                Spacer().frame(height: compact ? 4 : 8)
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
                RoundedRectangle(cornerRadius: 3 * scale, style: .continuous)
                    .fill(Color(hex: book.spineColorHex))

                // Subtle cloth/linen texture gradient
                LinearGradient(
                    colors: [.white.opacity(0.08), .clear, .black.opacity(0.14)],
                    startPoint: .top,
                    endPoint: .bottom
                )

                VStack {
                    Rectangle()
                        .fill(Color(hex: book.spineAccentHex).opacity(0.85))
                        .frame(height: max(2, 3.2 * scale))
                        .padding(.top, 9 * scale)
                    Spacer()
                    if let idx = book.seriesIndex {
                        Text("\(idx)")
                            .font(.system(size: max(7, 8.5 * scale), weight: .bold, design: .serif))
                            .foregroundStyle(Color(hex: book.spineAccentHex))
                            .padding(.bottom, 2 * scale)
                    }
                    Rectangle()
                        .fill(Color(hex: book.spineAccentHex).opacity(0.85))
                        .frame(height: max(2, 3.2 * scale))
                        .padding(.bottom, 9 * scale)
                }

                let verticalInset: CGFloat = book.seriesIndex != nil ? 48 * scale : 30 * scale
                Text(book.title)
                    .font(titleFont)
                    .foregroundStyle(Color(hex: book.spineTextColorHex))
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)
                    .frame(width: max(30, height - verticalInset), height: width - 4 * scale)
                    .rotationEffect(.degrees(-90))
                    .offset(y: book.seriesIndex != nil ? -5 * scale : 0)
            }

            // 3D cylindrical spine shading
            LinearGradient(
                stops: [
                    .init(color: .black.opacity(0.32), location: 0.0),
                    .init(color: .white.opacity(0.24), location: 0.14),
                    .init(color: .white.opacity(0.04), location: 0.40),
                    .init(color: .black.opacity(0.06), location: 0.72),
                    .init(color: .black.opacity(0.42), location: 1.0)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )

            // Lent-to borrower badge
            if let borrower = book.lentTo, !borrower.isEmpty, scale >= 0.75 {
                VStack {
                    Spacer()
                    Text(borrower.prefix(6))
                        .font(.system(size: 7.5 * scale, weight: .bold))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 3.5)
                        .padding(.vertical, 1.5)
                        .background(NovelyTheme.warmGold, in: Capsule())
                        .padding(.bottom, 4 * scale)
                }
            }
        }
        .frame(width: width, height: height)
        .clipShape(RoundedRectangle(cornerRadius: 3 * scale, style: .continuous))
        .shadow(color: .black.opacity(0.48), radius: 3.5 * scale, x: 2 * scale, y: 2.5 * scale)
    }
}

// MARK: - Front-Facing Real Book Cover on Shelf

public struct BookCoverForwardView: View {
    public let book: Book
    public let scale: CGFloat

    public init(book: Book, scale: CGFloat = 1.0) {
        self.book = book
        self.scale = scale
    }

    private var localCoverImage: UIImage? {
        guard let data = LibraryStorage.loadImageData(filename: book.customCoverFilename) else { return nil }
        return UIImage(data: data)
    }

    public var body: some View {
        let height = book.spineHeightPoints * scale
        let width = height * 0.67

        ZStack {
            if let uiImage = localCoverImage {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: width, height: height)
                    .clipped()
            } else if let urlStr = book.coverURLString, let url = URL(string: urlStr) {
                AsyncImage(url: url) { phase in
                    if case .success(let image) = phase {
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: width, height: height)
                            .clipped()
                    } else {
                        styledFallbackCover(width: width, height: height)
                    }
                }
            } else {
                styledFallbackCover(width: width, height: height)
            }

            // Realistic book hinge crease + subtle hardcover gloss
            HStack(spacing: 0) {
                LinearGradient(
                    colors: [.black.opacity(0.36), .white.opacity(0.22), .clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: 8 * scale)
                Spacer()
            }

            LinearGradient(
                colors: [.white.opacity(0.14), .clear, .black.opacity(0.16)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        .frame(width: width, height: height)
        .clipShape(RoundedRectangle(cornerRadius: 4 * scale, style: .continuous))
        .shadow(color: .black.opacity(0.52), radius: 5 * scale, x: 2 * scale, y: 3 * scale)
    }

    @ViewBuilder
    private func styledFallbackCover(width: CGFloat, height: CGFloat) -> some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(hex: book.spineColorHex),
                    Color(hex: book.spineColorHex).opacity(0.76)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

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

                    LinearGradient(
                        colors: [.white.opacity(0.22), .clear, .black.opacity(0.35)],
                        startPoint: .top,
                        endPoint: .bottom
                    )

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

// MARK: - Illustrated Cozy Shelf Decor (Sleeping Cat, Potted Plant, Snowman, Candle)

public struct ShelfDecorView: View {
    public let kind: DecorKind
    public let scale: CGFloat
    public let plantStage: Int

    public init(kind: DecorKind, scale: CGFloat = 1.0, plantStage: Int = 5) {
        self.kind = kind
        self.scale = scale
        self.plantStage = plantStage
    }

    public var body: some View {
        switch kind {
        case .sleepingCat:
            Image("DecorSleepingCat")
                .resizable()
                .scaledToFit()
                .frame(width: 82 * scale, height: 54 * scale)
                .shadow(color: .black.opacity(0.55), radius: 4 * scale, x: 0, y: 3 * scale)
                .offset(y: 3 * scale)
        case .monstera:
            let growthFactor = 0.68 + Double(min(5, max(1, plantStage))) * 0.075
            Image("DecorPottedPlant")
                .resizable()
                .scaledToFit()
                .frame(width: 66 * scale * growthFactor, height: 76 * scale * growthFactor)
                .shadow(color: .black.opacity(0.50), radius: 4 * scale, x: 0, y: 3 * scale)
                .offset(y: 2 * scale)
        case .snowman:
            Image("DecorSnowman")
                .resizable()
                .scaledToFit()
                .frame(width: 52 * scale, height: 64 * scale)
                .shadow(color: .black.opacity(0.48), radius: 3.5 * scale, x: 0, y: 3 * scale)
                .offset(y: 2 * scale)
        case .candle:
            candleView
        case .snowGlobe:
            snowGlobeView
        case .coffeeMug:
            coffeeMugView
        }
    }

    private var candleView: some View {
        VStack(spacing: 0) {
            ZStack {
                Circle()
                    .fill(Color(hex: "#FFB347").opacity(0.5))
                    .frame(width: 28 * scale, height: 28 * scale)
                    .blur(radius: 7 * scale)
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

            RoundedRectangle(cornerRadius: 3 * scale)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "#F8F0DF"), Color(hex: "#DFCEB4"), Color(hex: "#BAA586")],
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

            RoundedRectangle(cornerRadius: 2 * scale)
                .fill(Color(hex: "#8A6D3B"))
                .frame(width: 28 * scale, height: 5 * scale)
        }
        .shadow(color: .black.opacity(0.45), radius: 3 * scale, y: 2 * scale)
    }

    private var snowGlobeView: some View {
        VStack(spacing: -2 * scale) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color(hex: "#C8E4F2").opacity(0.55), Color(hex: "#2B4C5E").opacity(0.7)],
                            center: .topLeading,
                            startRadius: 2,
                            endRadius: 20 * scale
                        )
                    )
                    .frame(width: 36 * scale, height: 36 * scale)
                    .overlay(Circle().strokeBorder(.white.opacity(0.4), lineWidth: 1))
                Image(systemName: "tree.fill")
                    .font(.system(size: 13 * scale))
                    .foregroundStyle(Color(hex: "#2D5A3E"))
                    .offset(y: 4 * scale)
                Image(systemName: "sparkles")
                    .font(.system(size: 10 * scale))
                    .foregroundStyle(.white.opacity(0.9))
                    .offset(x: -5 * scale, y: -5 * scale)
            }
            RoundedRectangle(cornerRadius: 3 * scale)
                .fill(Color(hex: "#4A2E1E"))
                .frame(width: 28 * scale, height: 10 * scale)
        }
        .shadow(color: .black.opacity(0.45), radius: 3 * scale, y: 2 * scale)
    }

    private var coffeeMugView: some View {
        VStack(spacing: 2 * scale) {
            Image(systemName: "wind")
                .font(.system(size: 10 * scale))
                .foregroundStyle(.white.opacity(0.55))
                .rotationEffect(.degrees(-90))
            HStack(spacing: -2 * scale) {
                RoundedRectangle(cornerRadius: 4 * scale)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "#E6DDD0"), Color(hex: "#B5A897")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 24 * scale, height: 24 * scale)
                Circle()
                    .strokeBorder(Color(hex: "#C4B9A9"), lineWidth: 3 * scale)
                    .frame(width: 11 * scale, height: 11 * scale)
            }
        }
        .shadow(color: .black.opacity(0.45), radius: 3 * scale, y: 2 * scale)
    }
}

// MARK: - Complete Shelf Tier (Books + Stacks + Movable Decor + Wooden Plank + Draped Fairy Lights)

public struct BookshelfTierView: View {
    public let books: [Book]
    public let decorItems: [ShelfDecorItem]
    public let woodFinish: WoodFinish
    public let fairyLightsEnabled: Bool
    public let scale: CGFloat
    public let plantStage: Int
    public let isEditing: Bool
    public let onTapBook: ((Book) -> Void)?
    public let onMoveBook: ((Book, Int) -> Void)?
    public let onCycleStyle: ((Book) -> Void)?
    public let onShiftDecor: ((ShelfDecorItem, Int) -> Void)?

    public init(
        books: [Book],
        decorItems: [ShelfDecorItem] = [],
        woodFinish: WoodFinish,
        fairyLightsEnabled: Bool = true,
        scale: CGFloat = 1.0,
        plantStage: Int = 5,
        isEditing: Bool = false,
        onTapBook: ((Book) -> Void)? = nil,
        onMoveBook: ((Book, Int) -> Void)? = nil,
        onCycleStyle: ((Book) -> Void)? = nil,
        onShiftDecor: ((ShelfDecorItem, Int) -> Void)? = nil
    ) {
        self.books = books
        self.decorItems = decorItems
        self.woodFinish = woodFinish
        self.fairyLightsEnabled = fairyLightsEnabled
        self.scale = scale
        self.plantStage = plantStage
        self.isEditing = isEditing
        self.onTapBook = onTapBook
        self.onMoveBook = onMoveBook
        self.onCycleStyle = onCycleStyle
        self.onShiftDecor = onShiftDecor
    }

    private var uprightBooks: [Book] {
        books.filter { $0.displayStyle != .stacked }
    }

    private var stackedBooks: [Book] {
        books.filter { $0.displayStyle == .stacked }
    }

    private var leftDecor: [ShelfDecorItem] {
        decorItems.filter { $0.isEnabled && $0.slotIndex == 0 }
    }

    private var middleDecor: [ShelfDecorItem] {
        decorItems.filter { $0.isEnabled && $0.slotIndex == 1 }
    }

    private var rightDecor: [ShelfDecorItem] {
        decorItems.filter { $0.isEnabled && $0.slotIndex >= 2 }
    }

    public var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .bottom, spacing: 5 * scale) {
                ForEach(leftDecor) { item in
                    decorInteractive(item)
                }

                if !stackedBooks.isEmpty {
                    BookStackView(books: stackedBooks, scale: scale, onTapBook: onTapBook)
                        .padding(.trailing, 3 * scale)
                }

                let splitIndex = uprightBooks.count / 2
                ForEach(Array(uprightBooks.enumerated()), id: \.element.id) { idx, book in
                    if idx == splitIndex {
                        ForEach(middleDecor) { item in
                            decorInteractive(item)
                        }
                    }
                    bookInteractive(book)
                }

                if uprightBooks.isEmpty {
                    ForEach(middleDecor) { item in
                        decorInteractive(item)
                    }
                }

                Spacer(minLength: 4 * scale)

                ForEach(rightDecor) { item in
                    decorInteractive(item)
                }
            }
            .padding(.horizontal, 16 * scale)
            .frame(minHeight: 118 * scale, alignment: .bottom)

            WoodenShelfPlank(
                woodFinish: woodFinish,
                fairyLightsEnabled: fairyLightsEnabled,
                compact: scale < 0.75
            )
            .padding(.horizontal, 6 * scale)
        }
    }

    @ViewBuilder
    private func bookInteractive(_ book: Book) -> some View {
        VStack(spacing: 4) {
            if isEditing {
                HStack(spacing: 4) {
                    Button {
                        withAnimation(.spring(response: 0.3)) { onMoveBook?(book, -1) }
                    } label: {
                        Image(systemName: "chevron.left.circle.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(NovelyTheme.creamText)
                    }
                    Button {
                        withAnimation(.spring(response: 0.3)) { onMoveBook?(book, 1) }
                    } label: {
                        Image(systemName: "chevron.right.circle.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(NovelyTheme.creamText)
                    }
                }
            }

            Group {
                if book.displayStyle == .coverForward {
                    BookCoverForwardView(book: book, scale: scale)
                } else {
                    BookSpineView(book: book, scale: scale)
                }
            }
            .onTapGesture {
                if isEditing {
                    withAnimation(.spring(response: 0.3)) { onCycleStyle?(book) }
                } else {
                    onTapBook?(book)
                }
            }
            .contextMenu {
                Button {
                    onCycleStyle?(book)
                } label: {
                    Label("Ansicht wechseln (Rücken/Cover/Stapel)", systemImage: "arrow.triangle.2.circlepath")
                }
                Button {
                    onMoveBook?(book, -1)
                } label: {
                    Label("Nach links schieben", systemImage: "arrow.left")
                }
                Button {
                    onMoveBook?(book, 1)
                } label: {
                    Label("Nach rechts schieben", systemImage: "arrow.right")
                }
                Button {
                    onTapBook?(book)
                } label: {
                    Label("Details & Bearbeiten", systemImage: "info.circle")
                }
            }
        }
    }

    @ViewBuilder
    private func decorInteractive(_ item: ShelfDecorItem) -> some View {
        VStack(spacing: 2) {
            if isEditing {
                HStack(spacing: 4) {
                    Button {
                        withAnimation(.spring(response: 0.3)) { onShiftDecor?(item, -1) }
                    } label: {
                        Image(systemName: "arrow.left.circle.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(NovelyTheme.warmGold)
                    }
                    Button {
                        withAnimation(.spring(response: 0.3)) { onShiftDecor?(item, 1) }
                    } label: {
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(NovelyTheme.warmGold)
                    }
                }
            }
            ShelfDecorView(kind: item.kind, scale: scale, plantStage: plantStage)
        }
        .gesture(
            DragGesture(minimumDistance: 24)
                .onEnded { value in
                    if value.translation.width > 24 {
                        withAnimation(.spring(response: 0.35)) { onShiftDecor?(item, 1) }
                    } else if value.translation.width < -24 {
                        withAnimation(.spring(response: 0.35)) { onShiftDecor?(item, -1) }
                    }
                }
        )
    }
}
