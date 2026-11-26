import SwiftUI

enum TimerStyleMode: String, CaseIterable, Identifiable {
    case countdown = "Timer"
    case stopwatch = "Stoppuhr"
    var id: String { rawValue }
}

struct ReadingRoomView: View {
    @EnvironmentObject private var store: LibraryStore
    @EnvironmentObject private var audioEngine: AmbientAudioEngine
    @Environment(\.scenePhase) private var scenePhase

    @Binding var externalBook: Book?

    @State private var selectedRoom: ReadingRoomTheme = .dogShelf
    @State private var selectedBookId: UUID?
    @State private var timerMode: TimerStyleMode = .countdown
    @State private var targetMinutes: Double = 30
    @State private var focusGuardEnabled = true
    @State private var isRunning = false
    @State private var elapsedSeconds: Int = 0
    @State private var leftAppWarning = false
    @State private var showingRoomPickerSheet = false
    @State private var showingSessionSetupSheet = false
    @State private var showingFinishSheet = false
    @State private var loggedPagesText = "25"

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var activeBook: Book? {
        if let ext = externalBook { return ext }
        if let id = selectedBookId, let found = store.books.first(where: { $0.id == id }) {
            return found
        }
        return store.currentlyReadingBooks.first ?? store.books.first
    }

    private var displayedSeconds: Int {
        if timerMode == .countdown {
            return max(0, Int(targetMinutes) * 60 - elapsedSeconds)
        }
        return elapsedSeconds
    }

    var body: some View {
        ZStack {
            // Full-screen bespoke cozy reading room artwork (Cat, Dog, Rainy, Fireplace!)
            GeometryReader { geo in
                Image(selectedRoom.imageAssetName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
                    .animation(.easeInOut(duration: 0.55), value: selectedRoom)
            }
            .ignoresSafeArea()

            // Animated subtle snow / rain / fireplace embers
            AmbientParticlesOverlay(theme: selectedRoom)
                .ignoresSafeArea()
                .allowsHitTesting(false)

            // Soft top & bottom vignette so timer & controls stay ultra-legible without hiding the cozy art!
            LinearGradient(
                stops: [
                    .init(color: .black.opacity(0.62), location: 0.0),
                    .init(color: .clear, location: 0.28),
                    .init(color: .clear, location: 0.68),
                    .init(color: .black.opacity(0.75), location: 1.0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 12) {
                // Top Bar: "Deine Lesezeit" + "..." Room/Sound Personalizer (exact Reel 1 & 2 layout!)
                HStack {
                    Button {
                        showingSessionSetupSheet = true
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(NovelyTheme.creamText)
                            .padding(10)
                            .novelyGlassCapsule()
                    }
                    .accessibilityIdentifier("sessionSetupButton")

                    Spacer()

                    VStack(spacing: 2) {
                        Text("Deine Lesezeit")
                            .font(.system(size: 16, weight: .semibold, design: .serif))
                            .foregroundStyle(NovelyTheme.creamText)
                        if let book = activeBook {
                            Text(book.title)
                                .font(.system(size: 11.5, weight: .medium))
                                .foregroundStyle(NovelyTheme.warmGold)
                                .lineLimit(1)
                        }
                    }

                    Spacer()

                    Button {
                        showingRoomPickerSheet = true
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(NovelyTheme.creamText)
                            .padding(10)
                            .novelyGlassCapsule()
                    }
                    .accessibilityIdentifier("roomPickerButton")
                }
                .padding(.horizontal, 18)
                .padding(.top, 10)

                // Quick Room Switcher Pills (Katze / Hund / Regen / Kamin)
                HStack(spacing: 7) {
                    ForEach(ReadingRoomTheme.allCases) { room in
                        let active = selectedRoom == room
                        Button {
                            withAnimation(.easeInOut(duration: 0.35)) {
                                selectedRoom = room
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: room.ambientIcon)
                                    .font(.system(size: 11))
                                Text(room.rawValue)
                                    .font(.system(size: 12, weight: active ? .semibold : .regular))
                            }
                            .foregroundStyle(active ? NovelyTheme.creamText : NovelyTheme.creamText.opacity(0.75))
                            .padding(.horizontal, 11)
                            .padding(.vertical, 6)
                            .novelyGlassCapsule(tint: active ? NovelyTheme.terracotta.opacity(0.45) : Color.black.opacity(0.25))
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("roomTheme_\(room.rawValue)")
                    }
                }

                // Focus-Guard Warning Banner if user left the app!
                if leftAppWarning {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(NovelyTheme.warmGold)
                        Text("Fokus-Modus: Bleib in der App, damit deine Lesezeit weiterläuft!")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(NovelyTheme.creamText)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 9)
                    .novelyGlassCard(cornerRadius: 14, tint: NovelyTheme.terracotta.opacity(0.55))
                    .padding(.horizontal, 18)
                }

                Spacer()

                // Bottom Centered Clean Serif Timer + Controls (leaves cozy cat/dog scene completely visible!)
                VStack(spacing: 12) {
                    // Clean warm glass timer badge (exact Reel 1 & 2 vibe!)
                    VStack(spacing: 3) {
                        Text(formattedTime(displayedSeconds))
                            .font(.system(size: 38, weight: .medium, design: .serif))
                            .monospacedDigit()
                            .foregroundStyle(NovelyTheme.creamText)
                        if focusGuardEnabled {
                            Label("Fokus-Modus aktiv · Bleib in der App", systemImage: "lock.fill")
                                .font(.system(size: 10.5, weight: .semibold))
                                .foregroundStyle(NovelyTheme.warmGold)
                        }
                    }
                    .padding(.horizontal, 26)
                    .padding(.vertical, 10)
                    .novelyGlassCard(cornerRadius: 20, tint: Color.black.opacity(0.32))

                    HStack(spacing: 12) {
                        Button {
                            leftAppWarning = false
                            withAnimation(.spring(response: 0.3)) {
                                isRunning.toggle()
                            }
                        } label: {
                            Label(
                                isRunning ? "Pause" : (elapsedSeconds > 0 ? "Weiterlesen" : "Session starten"),
                                systemImage: isRunning ? "pause.fill" : "play.fill"
                            )
                            .font(.system(size: 15.5, weight: .semibold))
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(NovelyTheme.creamText, in: Capsule())
                        }

                        if elapsedSeconds > 0 {
                            Button {
                                isRunning = false
                                showingFinishSheet = true
                            } label: {
                                Label("Beenden", systemImage: "checkmark")
                                    .font(.system(size: 14.5, weight: .semibold))
                                    .foregroundStyle(NovelyTheme.creamText)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 14)
                                    .novelyGlassCapsule(tint: NovelyTheme.terracotta.opacity(0.5))
                            }
                        }
                    }
                    .padding(.horizontal, 22)
                }
                .padding(.bottom, 18)
            }
        }
        .onReceive(timer) { _ in
            if isRunning {
                elapsedSeconds += 1
                if timerMode == .countdown && displayedSeconds == 0 {
                    isRunning = false
                    showingFinishSheet = true
                }
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            // Exact Focus-Guard behavior requested by sister!
            if isRunning && focusGuardEnabled && newPhase != .active {
                isRunning = false
                leftAppWarning = true
            }
        }
        .sheet(isPresented: $showingSessionSetupSheet) {
            sessionSetupSheet
                .presentationDetents([.height(380)])
        }
        .sheet(isPresented: $showingRoomPickerSheet) {
            roomAndSoundSheet
                .presentationDetents([.height(380)])
        }
        .sheet(isPresented: $showingFinishSheet) {
            finishSessionSheet
                .presentationDetents([.height(290)])
        }
    }

    // MARK: - Session Setup Sheet (Timer / Stoppuhr + Fokus-Modus like Reel 1 & 2!)

    private var sessionSetupSheet: some View {
        ZStack {
            NovelyTheme.espressoBg.ignoresSafeArea()
            VStack(spacing: 18) {
                Text("Lesesession einstellen")
                    .font(.system(size: 20, weight: .bold, design: .serif))
                    .foregroundStyle(NovelyTheme.creamText)
                    .padding(.top, 16)

                Picker("Modus", selection: $timerMode) {
                    ForEach(TimerStyleMode.allCases) { m in
                        Text(m.rawValue).tag(m)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 28)

                if timerMode == .countdown {
                    VStack(spacing: 4) {
                        Text("\(Int(targetMinutes))")
                            .font(.system(size: 46, weight: .bold, design: .serif))
                            .foregroundStyle(NovelyTheme.creamText)
                        Text("Minuten")
                            .font(.system(size: 13))
                            .foregroundStyle(NovelyTheme.warmMutedText)
                        Slider(value: $targetMinutes, in: 10...120, step: 5)
                            .tint(NovelyTheme.terracotta)
                            .padding(.horizontal, 28)
                    }
                }

                Toggle(isOn: $focusGuardEnabled) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Fokus-Modus (In der App bleiben)")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(NovelyTheme.creamText)
                        Text("Stoppt den Timer, wenn du die App verlässt.")
                            .font(.system(size: 11.5))
                            .foregroundStyle(NovelyTheme.warmMutedText)
                    }
                }
                .tint(NovelyTheme.terracotta)
                .padding(.horizontal, 24)

                Button {
                    elapsedSeconds = 0
                    leftAppWarning = false
                    isRunning = true
                    showingSessionSetupSheet = false
                } label: {
                    Text("Session starten")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(NovelyTheme.creamText, in: Capsule())
                }
                .padding(.horizontal, 24)
            }
        }
    }

    // MARK: - Room & Sound Picker Sheet (Exact Reel 1 "..." Overlay!)

    private var roomAndSoundSheet: some View {
        ZStack {
            NovelyTheme.espressoBg.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    Text("Lesezimmer & Klang")
                        .font(.system(size: 20, weight: .bold, design: .serif))
                        .foregroundStyle(NovelyTheme.creamText)
                    Spacer()
                    Button("Fertig") { showingRoomPickerSheet = false }
                        .fontWeight(.semibold)
                }
                .padding(.top, 16)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(ReadingRoomTheme.allCases) { room in
                            let active = selectedRoom == room
                            Button {
                                selectedRoom = room
                            } label: {
                                VStack(spacing: 6) {
                                    Image(room.imageAssetName)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 82, height: 112)
                                        .clipShape(RoundedRectangle(cornerRadius: 14))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 14)
                                                .strokeBorder(active ? NovelyTheme.warmGold : .white.opacity(0.18), lineWidth: active ? 2.5 : 1)
                                        )
                                    Text(room.rawValue)
                                        .font(.system(size: 12, weight: active ? .bold : .regular))
                                        .foregroundStyle(NovelyTheme.creamText)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                Text("Hintergrundklang (100 % offline)")
                    .font(.system(size: 15, weight: .semibold, design: .serif))
                    .foregroundStyle(NovelyTheme.creamText)

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
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(active ? NovelyTheme.warmGold : Color.white.opacity(0.08), in: Capsule())
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("ambientSound_\(sound.rawValue)")
                    }
                }
                Spacer()
            }
            .padding(.horizontal, 18)
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

                Text("Gelesene Zeit: \(formattedTime(elapsedSeconds))")
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
                    Text("Speichern & Pflanze wachsen lassen 🌱")
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

// MARK: - Animated Cozy Particles Overlay

private struct AmbientParticlesOverlay: View {
    let theme: ReadingRoomTheme

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            Canvas { context, size in
                let count = theme == .rainyLibrary ? 40 : 24
                for i in 0..<count {
                    let seed = Double(i) * 1.6180339
                    switch theme {
                    case .catWinter:
                        let x = ((seed * 137.5).truncatingRemainder(dividingBy: 1.0) * size.width) + sin(t * 0.8 + seed) * 14
                        let speed = 18.0 + (seed.truncatingRemainder(dividingBy: 1.0)) * 20.0
                        let y = (t * speed + seed * 90).truncatingRemainder(dividingBy: size.height)
                        let r = 1.4 + (seed.truncatingRemainder(dividingBy: 1.8))
                        context.fill(Path(ellipseIn: CGRect(x: x, y: y, width: r * 2, height: r * 2)), with: .color(.white.opacity(0.55)))
                    case .rainyLibrary:
                        let x = (seed * 193.7).truncatingRemainder(dividingBy: 1.0) * size.width
                        let speed = 210.0 + (seed.truncatingRemainder(dividingBy: 1.0)) * 120.0
                        let y = (t * speed + seed * 120).truncatingRemainder(dividingBy: size.height)
                        var path = Path()
                        path.move(to: CGPoint(x: x, y: y))
                        path.addLine(to: CGPoint(x: x - 2, y: y + 14))
                        context.stroke(path, with: .color(Color(hex: "#B8D4E8").opacity(0.28)), lineWidth: 1)
                    case .fireplaceCabin, .dogShelf:
                        let x = size.width * 0.5 + sin(t * 0.7 + seed * 5) * (size.width * 0.42)
                        let speed = 18.0 + (seed.truncatingRemainder(dividingBy: 1.0)) * 16.0
                        let y = size.height - ((t * speed + seed * 80).truncatingRemainder(dividingBy: size.height * 0.7))
                        let r = 1.2 + (seed.truncatingRemainder(dividingBy: 1.5))
                        context.fill(Path(ellipseIn: CGRect(x: x, y: y, width: r * 2, height: r * 2)), with: .color(Color(hex: "#FFD17A").opacity(0.35)))
                    }
                }
            }
        }
    }
}
