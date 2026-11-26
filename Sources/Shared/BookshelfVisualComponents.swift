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
    public static let espressoBg = Color(hex: "#18120E")
    public static let cardDarkBg = Color(hex: "#231B16")
}

// MARK: - Deeply Recessed Photorealistic Wooden Bookcase Backdrop

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
                .overlay(Color.black.opacity(0.25))
            } else if settings.wallTheme.usesWoodTextureImage {
                GeometryReader { geo in
                    Image("WoodShelfTexture")
                        .resizable()
                        .scaledToFill()
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipped()
                }
                .overlay(
                    LinearGradient(
                        stops: [
                            .init(color: Color.black.opacity(0.42), location: 0.0),
                            .init(color: Color.clear, location: 0.20),
                            .init(color: Color.clear, location: 0.80),
                            .init(color: Color.black.opacity(0.55), location: 1.0)
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

                // Recessed wooden cabinet side-pillars
                HStack(spacing: 0) {
                    LinearGradient(
                        colors: [Color(hex: settings.woodFinish.sideHex), Color.black.opacity(0.45), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: 20)
                    Spacer()
                    LinearGradient(
                        colors: [.clear, Color.black.opacity(0.45), Color(hex: settings.woodFinish.sideHex)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: 20)
                }
            }

            // Soft gallery top spotlight
            if settings.warmSpotlightsEnabled {
                RadialGradient(
                    colors: [
                        Color(hex: "#FFD99B").opacity(0.18),
                        Color.clear
                    ],
                    center: .top,
                    startRadius: 20,
                    endRadius: 360
                )
                .allowsHitTesting(false)
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Delicate Draped Fairy Light String with Real Swagged Wire Cord

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
            let dip: CGFloat = compact ? 6.5 : 11.5

            ZStack {
                // Fine dark-copper swagged wire cord
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
                    Color(hex: "#1F1610").opacity(0.9),
                    style: StrokeStyle(lineWidth: compact ? 0.9 : 1.15, lineCap: .round)
                )

                // Warm bokeh fairy bulbs along the cord
                ForEach(0..<swags, id: \.self) { i in
                    let x0 = 4 + CGFloat(i) * (segW - 2)
                    let x1 = min(4 + CGFloat(i + 1) * (segW - 2), w - 4)
                    ForEach([0.22, 0.50, 0.78], id: \.self) { t in
                        let bx = x0 + (x1 - x0) * CGFloat(t)
                        let by = 1 + 2 * CGFloat(1 - t) * CGFloat(t) * (dip * 2.0)

                        ZStack {
                            Circle()
                                .fill(Color(hex: "#FFC766").opacity(0.42))
                                .frame(width: compact ? 11 : 17, height: compact ? 11 : 17)
                                .blur(radius: compact ? 3 : 5)

                            VStack(spacing: -0.5) {
                                Rectangle()
                                    .fill(Color(hex: "#2D2118"))
                                    .frame(width: compact ? 1.8 : 2.3, height: compact ? 1.8 : 2.4)
                                Ellipse()
                                    .fill(Color(hex: "#FFF6D9"))
                                    .frame(width: compact ? 3.5 : 4.8, height: compact ? 4.4 : 5.8)
                                    .shadow(color: Color(hex: "#FFB732"), radius: compact ? 2 : 3.5)
                            }
                        }
                        .position(x: bx, y: by + (compact ? 2.0 : 3.0))
                    }
                }
            }
        }
        .frame(height: compact ? 15 : 23)
        .allowsHitTesting(false)
    }
}

// MARK: - Photorealistic 3D Wooden Shelf Plank + Deep Ambient Occlusion Cast Shadow

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
            // 3D recessed top shelf surface (darker toward the back wall!)
            ZStack {
                Image("ShelfPlankTexture")
                    .resizable()
                    .scaledToFill()
                    .frame(height: compact ? 6 : 10)
                    .clipped()

                Color(hex: woodFinish.topHex).opacity(0.32)

                LinearGradient(
                    colors: [Color.black.opacity(0.55), Color.black.opacity(0.15), Color.white.opacity(0.14)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .frame(height: compact ? 6 : 10)
            .clipped()

            // Photorealistic horizontal wood grain front shelf lip
            ZStack {
                Image("ShelfPlankTexture")
                    .resizable()
                    .scaledToFill()
                    .frame(height: compact ? 10 : 14)
                    .clipped()

                Color(hex: woodFinish.frontHex).opacity(0.35)

                LinearGradient(
                    colors: [Color.white.opacity(0.12), Color.clear, Color.black.opacity(0.55)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .frame(height: compact ? 10 : 14)
            .clipShape(RoundedRectangle(cornerRadius: 2))
            .shadow(color: Color.black.opacity(0.72), radius: compact ? 4 : 8, x: 0, y: compact ? 3 : 6)

            // Deep ambient occlusion shadow cast downward onto the compartment below + fairy lights
            ZStack(alignment: .top) {
                LinearGradient(
                    colors: [Color.black.opacity(0.65), Color.black.opacity(0.22), Color.clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: compact ? 16 : 28)

                if fairyLightsEnabled {
                    DrapedFairyLightString(compact: compact)
                        .padding(.horizontal, 6)
                        .offset(y: -2)
                }
            }
        }
    }
}

// MARK: - Photorealistic 3D Book Spine

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
        case .serif: return .system(size: size, weight: .semibold, design: .serif)
        case .modern: return .system(size: size, weight: .bold, design: .rounded)
        case .condensed: return .system(size: size, weight: .medium, design: .serif).italic()
        case .ornate: return .system(size: size, weight: .heavy, design: .serif)
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
                RoundedRectangle(cornerRadius: 2.5 * scale, style: .continuous)
                    .fill(Color(hex: book.spineColorHex))

                // Soft warm overhead shelf illumination gradient
                LinearGradient(
                    colors: [.white.opacity(0.14), .clear, .black.opacity(0.28)],
                    startPoint: .top,
                    endPoint: .bottom
                )

                VStack {
                    Rectangle()
                        .fill(Color(hex: book.spineAccentHex).opacity(0.85))
                        .frame(height: max(2, 3.0 * scale))
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
                        .frame(height: max(2, 3.0 * scale))
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

            // Realistic cylindrical spine curve + recessed book hinge grooves
            LinearGradient(
                stops: [
                    .init(color: .black.opacity(0.40), location: 0.0),
                    .init(color: .white.opacity(0.22), location: 0.14),
                    .init(color: .white.opacity(0.03), location: 0.40),
                    .init(color: .black.opacity(0.12), location: 0.78),
                    .init(color: .black.opacity(0.48), location: 1.0)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )

            // Double hinge grooves
            HStack {
                Rectangle().fill(.black.opacity(0.25)).frame(width: 1).padding(.leading, 3.5 * scale)
                Spacer()
                Rectangle().fill(.black.opacity(0.25)).frame(width: 1).padding(.trailing, 3.5 * scale)
            }

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
        .clipShape(RoundedRectangle(cornerRadius: 2.5 * scale, style: .continuous))
        .shadow(color: .black.opacity(0.62), radius: 5 * scale, x: 3 * scale, y: 3 * scale)
        .offset(y: 4 * scale)
    }
}

// MARK: - Photorealistic Front-Facing Real Book Cover with 3D Page Block & Cast Shadow

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

        HStack(spacing: 0) {
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

                // Book hinge crease on left
                HStack(spacing: 0) {
                    LinearGradient(
                        colors: [.black.opacity(0.38), .white.opacity(0.20), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: 7 * scale)
                    Spacer()
                }

                // Warm top-down lighting + bottom shadow grounding
                LinearGradient(
                    colors: [.white.opacity(0.10), .clear, .black.opacity(0.26)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .frame(width: width, height: height)
            .clipShape(RoundedRectangle(cornerRadius: 3 * scale, style: .continuous))

            // Realistic 3D page block thickness on right edge!
            if scale >= 0.55 {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: book.isSpecialEdition
                                ? [Color(hex: book.spineAccentHex), Color(hex: book.spineColorHex)]
                                : [Color(hex: "#EDE4D3"), Color(hex: "#C8BDAA")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 2.5 * scale, height: height - 3 * scale)
                    .clipShape(RoundedRectangle(cornerRadius: 1))
            }
        }
        .shadow(color: .black.opacity(0.66), radius: 6 * scale, x: 3.5 * scale, y: 3.5 * scale)
        .offset(y: 4 * scale)
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
                        colors: [.white.opacity(0.20), .clear, .black.opacity(0.38)],
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
                .shadow(color: .black.opacity(0.55), radius: 3.5 * scale, x: 1 * scale, y: 2 * scale)
                .onTapGesture {
                    onTapBook?(book)
                }
            }
        }
        .offset(y: 4 * scale)
    }
}

// MARK: - Photorealistic Shelf Decor (Flat Sleeping Cat, Real Plant, Real Lit Candle, Snowman)

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
            ZStack(alignment: .bottom) {
                Ellipse()
                    .fill(Color.black.opacity(0.75))
                    .frame(width: 82 * scale, height: 9 * scale)
                    .blur(radius: 3.5 * scale)
                    .offset(y: 2 * scale)

                Image("DecorSleepingCat")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 96 * scale, height: 52 * scale)
                    .shadow(color: .black.opacity(0.45), radius: 3 * scale, x: 1 * scale, y: 2 * scale)
            }
            .offset(y: 7 * scale)
        case .monstera:
            let growthFactor = 0.68 + Double(min(5, max(1, plantStage))) * 0.075
            ZStack(alignment: .bottom) {
                Ellipse()
                    .fill(Color.black.opacity(0.68))
                    .frame(width: 44 * scale * growthFactor, height: 8 * scale)
                    .blur(radius: 3 * scale)
                    .offset(y: 2 * scale)

                Image("DecorPottedPlant")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 66 * scale * growthFactor, height: 76 * scale * growthFactor)
                    .shadow(color: .black.opacity(0.45), radius: 3.5 * scale, x: 1.5 * scale, y: 2 * scale)
            }
            .offset(y: 7 * scale)
        case .candle:
            ZStack(alignment: .bottom) {
                Ellipse()
                    .fill(Color.black.opacity(0.70))
                    .frame(width: 44 * scale, height: 7 * scale)
                    .blur(radius: 2.5 * scale)
                    .offset(y: 2 * scale)

                // Soft warm flame halo behind candle top
                Circle()
                    .fill(Color(hex: "#FFBE5C").opacity(0.38))
                    .frame(width: 36 * scale, height: 36 * scale)
                    .blur(radius: 9 * scale)
                    .offset(y: -46 * scale)

                Image("DecorCandle")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 48 * scale, height: 68 * scale)
                    .shadow(color: .black.opacity(0.45), radius: 3 * scale, x: 1.5 * scale, y: 2 * scale)
            }
            .offset(y: 7 * scale)
        case .snowman:
            ZStack(alignment: .bottom) {
                Ellipse()
                    .fill(Color.black.opacity(0.60))
                    .frame(width: 38 * scale, height: 7 * scale)
                    .blur(radius: 2.5 * scale)
                    .offset(y: 2 * scale)

                Image("DecorSnowman")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 52 * scale, height: 64 * scale)
                    .shadow(color: .black.opacity(0.42), radius: 3 * scale, x: 1.5 * scale, y: 2 * scale)
            }
            .offset(y: 6 * scale)
        case .snowGlobe:
            snowGlobeView
        case .coffeeMug:
            coffeeMugView
        }
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
        .shadow(color: .black.opacity(0.50), radius: 3 * scale, y: 2 * scale)
        .offset(y: 5 * scale)
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
        .shadow(color: .black.opacity(0.50), radius: 3 * scale, y: 2 * scale)
        .offset(y: 5 * scale)
    }
}

// MARK: - Complete Shelf Tier (Lit Compartment + Books + Stacks + Movable Decor + Real Wood Plank)

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
    public let onReorderBook: ((UUID, UUID) -> Void)?
    public let onMoveBookToRowEnd: ((UUID, UUID?) -> Void)?
    public let onDropDecor: ((UUID, Int) -> Void)?

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
        onShiftDecor: ((ShelfDecorItem, Int) -> Void)? = nil,
        onReorderBook: ((UUID, UUID) -> Void)? = nil,
        onMoveBookToRowEnd: ((UUID, UUID?) -> Void)? = nil,
        onDropDecor: ((UUID, Int) -> Void)? = nil
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
        self.onReorderBook = onReorderBook
        self.onMoveBookToRowEnd = onMoveBookToRowEnd
        self.onDropDecor = onDropDecor
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
            ZStack(alignment: .bottom) {
                // Soft warm compartment light glow behind books
                RadialGradient(
                    colors: [Color(hex: "#FFCA7A").opacity(0.14), Color.clear],
                    center: .center,
                    startRadius: 10,
                    endRadius: 170 * scale
                )
                .frame(height: 118 * scale)
                .allowsHitTesting(false)

                HStack(alignment: .bottom, spacing: 3.5 * scale) {
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
                .padding(.horizontal, 14 * scale)
                .frame(minHeight: 112 * scale, alignment: .bottom)
            }
            .contentShape(Rectangle())
            .dropDestination(for: String.self) { items, location in
                guard let payload = items.first else { return false }
                if payload.hasPrefix("book:"),
                   let draggedUUID = UUID(uuidString: String(payload.dropFirst(5))) {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                        onMoveBookToRowEnd?(draggedUUID, books.last?.id)
                    }
                    return true
                }
                if payload.hasPrefix("decor:"),
                   let decorUUID = UUID(uuidString: String(payload.dropFirst(6))) {
                    let slot = location.x < 125 ? 0 : (location.x < 250 ? 1 : 2)
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                        onDropDecor?(decorUUID, slot)
                    }
                    return true
                }
                return false
            }
            .zIndex(2)

            WoodenShelfPlank(
                woodFinish: woodFinish,
                fairyLightsEnabled: fairyLightsEnabled,
                compact: scale < 0.75
            )
            .padding(.horizontal, 8 * scale)
            .zIndex(1)
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
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(book.title)
            .accessibilityAddTraits(.isButton)
            .accessibilityIdentifier("bookItem_\(book.title)")
            .draggable("book:\(book.id.uuidString)")
            .dropDestination(for: String.self) { items, _ in
                guard let payload = items.first else { return false }
                if payload.hasPrefix("book:"),
                   let draggedUUID = UUID(uuidString: String(payload.dropFirst(5))) {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                        onReorderBook?(draggedUUID, book.id)
                    }
                    return true
                }
                if payload.hasPrefix("decor:"),
                   let decorUUID = UUID(uuidString: String(payload.dropFirst(6))) {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                        onDropDecor?(decorUUID, 1)
                    }
                    return true
                }
                return false
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
        .draggable("decor:\(item.id.uuidString)")
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
