import SwiftUI

struct ReadingRoomView: View {
    @EnvironmentObject private var store: LibraryStore
    @EnvironmentObject private var audioEngine: AmbientAudioEngine

    @State private var selectedRoom: ReadingRoomTheme = .winter
    @State private var selectedBookId: UUID?
    @State private var isRunning = false
    @State private var elapsedSeconds: Int = 0
    @State private var showingFinishSheet = false
    @State private var loggedPagesText = "25"

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var activeBook: Book? {
        if let id = selectedBookId, let found = store.books.first(where: { $0.id == id }) {
            return found
        }
        return store.currentlyReadingBooks.first ?? store.books.first
    }

    var body: some View {
        ZStack {
            // Full-screen bespoke cozy reading room artwork
            GeometryReader { geo in
                Image(selectedRoom.imageAssetName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
                    .animation(.easeInOut(duration: 0.6), value: selectedRoom)
            }
            .ignoresSafeArea()

            // Subtle ambient particles (snow / rain / warm embers)
            AmbientParticlesOverlay(theme: selectedRoom)
                .ignoresSafeArea()
                .allowsHitTesting(false)

            // Dark top & bottom readability vignette
            LinearGradient(
                stops: [
                    .init(color: .black.opacity(0.68), location: 0.0),
                    .init(color: .black.opacity(0.18), location: 0.36),
                    .init(color: .black.opacity(0.08), location: 0.62),
                    .init(color: .black.opacity(0.78), location: 1.0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 16) {
                // Top Header + Room Switcher
                VStack(spacing: 10) {
                    Text("Deine Lesezeit")
                        .font(.system(size: 15, weight: .medium, design: .serif))
                        .foregroundStyle(NovelyTheme.creamText.opacity(0.9))

                    HStack(spacing: 8) {
                        ForEach(ReadingRoomTheme.allCases) { room in
                            let active = selectedRoom == room
                            Button {
                                withAnimation(.easeInOut(duration: 0.35)) {
                                    selectedRoom = room
                                }
                            } label: {
                                HStack(spacing: 5) {
                                    Image(systemName: room.ambientIcon)
                                        .font(.system(size: 11))
                                    Text(room == .winter ? "Winter" : (room == .rainy ? "Regen" : "Kamin"))
                                        .font(.system(size: 12, weight: active ? .semibold : .regular))
                                }
                                .foregroundStyle(active ? NovelyTheme.creamText : NovelyTheme.warmMutedText)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 7)
                                .novelyGlassCapsule(tint: active ? NovelyTheme.terracotta.opacity(0.32) : nil)
                            }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("roomTheme_\(room == .winter ? "Winter" : (room == .rainy ? "Regen" : "Kamin"))")
                        }
                    }
                }
                .padding(.top, 12)

                // Large Serif Timer Display
                VStack(spacing: 6) {
                    Text(formattedTime(elapsedSeconds))
                        .font(.system(size: 56, weight: .light, design: .serif))
                        .monospacedDigit()
                        .foregroundStyle(NovelyTheme.creamText)
                        .shadow(color: .black.opacity(0.45), radius: 10, y: 3)

                    if let book = activeBook {
                        Menu {
                            ForEach(store.books) { b in
                                Button(b.title) {
                                    selectedBookId = b.id
                                }
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "book.closed.fill")
                                    .font(.system(size: 12))
                                Text(book.title)
                                    .font(.system(size: 14, weight: .medium))
                                    .lineLimit(1)
                                Image(systemName: "chevron.up.chevron.down")
                                    .font(.system(size: 10))
                            }
                            .foregroundStyle(NovelyTheme.warmGold)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .novelyGlassCapsule()
                        }
                    }
                }
                .padding(.top, 8)

                Spacer()

                // Bottom Controls: Ambient Sound + Play/Pause/Finish
                VStack(spacing: 14) {
                    // Offline Procedural Ambient Audio Mixer
                    HStack(spacing: 8) {
                        ForEach(AmbientSoundMode.allCases) { sound in
                            let active = audioEngine.mode == sound
                            Button {
                                audioEngine.select(sound)
                            } label: {
                                HStack(spacing: 5) {
                                    Image(systemName: sound.iconName)
                                        .font(.system(size: 12))
                                    Text(sound.rawValue)
                                        .font(.system(size: 12, weight: active ? .semibold : .regular))
                                }
                                .foregroundStyle(active ? .black : NovelyTheme.creamText)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(
                                    active ? NovelyTheme.warmGold : Color.white.opacity(0.08),
                                    in: Capsule()
                                )
                            }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("ambientSound_\(sound.rawValue)")
                        }
                    }
                    .padding(8)
                    .novelyGlassCapsule()

                    // Start / Pause & Finish Session buttons
                    HStack(spacing: 14) {
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                isRunning.toggle()
                            }
                        } label: {
                            Label(
                                isRunning ? "Pause" : (elapsedSeconds > 0 ? "Weiterlesen" : "Lesezeit starten"),
                                systemImage: isRunning ? "pause.fill" : "play.fill"
                            )
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(NovelyTheme.creamText, in: Capsule())
                        }

                        if elapsedSeconds > 0 {
                            Button {
                                isRunning = false
                                showingFinishSheet = true
                            } label: {
                                Label("Beenden", systemImage: "checkmark")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(NovelyTheme.creamText)
                                    .padding(.horizontal, 18)
                                    .padding(.vertical, 15)
                                    .novelyGlassCapsule(tint: NovelyTheme.terracotta.opacity(0.45))
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.bottom, 22)
            }
        }
        .onReceive(timer) { _ in
            if isRunning {
                elapsedSeconds += 1
            }
        }
        .sheet(isPresented: $showingFinishSheet) {
            finishSessionSheet
                .presentationDetents([.height(290)])
        }
    }

    private var finishSessionSheet: some View {
        ZStack {
            NovelyTheme.espressoBg.ignoresSafeArea()
            VStack(spacing: 18) {
                Text("Lesesession speichern")
                    .font(.system(size: 22, weight: .bold, design: .serif))
                    .foregroundStyle(NovelyTheme.creamText)
                    .padding(.top, 16)

                Text("Dauer: \(formattedTime(elapsedSeconds))")
                    .font(.system(size: 15))
                    .foregroundStyle(NovelyTheme.warmGold)

                HStack {
                    Text("Gelesene Seiten:")
                        .foregroundStyle(NovelyTheme.warmMutedText)
                    TextField("25", text: $loggedPagesText)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.center)
                        .frame(width: 80)
                        .padding(8)
                        .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
                }

                Button {
                    if let book = activeBook {
                        let delta = Int(loggedPagesText) ?? 10
                        store.logProgress(
                            for: book.id,
                            newPage: book.currentPage + delta,
                            durationSeconds: max(60, elapsedSeconds),
                            roomTheme: selectedRoom
                        )
                    }
                    elapsedSeconds = 0
                    showingFinishSheet = false
                } label: {
                    Text("Speichern & Streak aktualisieren")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(NovelyTheme.creamText, in: Capsule())
                }
                .padding(.horizontal, 24)
            }
        }
    }

    private func formattedTime(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}

// MARK: - Animated Cozy Particles Overlay (Snow, Rain, Fireplace Embers)

private struct AmbientParticlesOverlay: View {
    let theme: ReadingRoomTheme

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            Canvas { context, size in
                let count = theme == .rainy ? 42 : 28
                for i in 0..<count {
                    let seed = Double(i) * 1.6180339
                    switch theme {
                    case .winter:
                        let x = ((seed * 137.5).truncatingRemainder(dividingBy: 1.0) * size.width)
                            + sin(t * 0.8 + seed) * 14
                        let speed = 18.0 + (seed.truncatingRemainder(dividingBy: 1.0)) * 20.0
                        let y = (t * speed + seed * 90).truncatingRemainder(dividingBy: size.height)
                        let r = 1.5 + (seed.truncatingRemainder(dividingBy: 2.0))
                        context.fill(
                            Path(ellipseIn: CGRect(x: x, y: y, width: r * 2, height: r * 2)),
                            with: .color(.white.opacity(0.55))
                        )
                    case .rainy:
                        let x = (seed * 193.7).truncatingRemainder(dividingBy: 1.0) * size.width
                        let speed = 210.0 + (seed.truncatingRemainder(dividingBy: 1.0)) * 120.0
                        let y = (t * speed + seed * 120).truncatingRemainder(dividingBy: size.height)
                        var path = Path()
                        path.move(to: CGPoint(x: x, y: y))
                        path.addLine(to: CGPoint(x: x - 2, y: y + 14))
                        context.stroke(path, with: .color(Color(hex: "#B8D4E8").opacity(0.28)), lineWidth: 1)
                    case .fireplace:
                        let x = size.width * 0.5 + sin(t * 1.1 + seed * 5) * (size.width * 0.35)
                        let speed = 26.0 + (seed.truncatingRemainder(dividingBy: 1.0)) * 22.0
                        let y = size.height - ((t * speed + seed * 80).truncatingRemainder(dividingBy: size.height * 0.65))
                        let r = 1.2 + (seed.truncatingRemainder(dividingBy: 1.6))
                        context.fill(
                            Path(ellipseIn: CGRect(x: x, y: y, width: r * 2, height: r * 2)),
                            with: .color(Color(hex: "#FFB347").opacity(0.42))
                        )
                    }
                }
            }
        }
    }
}
