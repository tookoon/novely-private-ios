import AVFoundation
import PhotosUI
import SwiftUI
import Vision

// MARK: - 1. ISBN Barcode Scanner (AVFoundation)

struct ISBNScannerView: View {
    @Environment(\.dismiss) private var dismiss
    let onScanned: (String) -> Void
    @State private var manualISBN = ""

    var body: some View {
        ZStack {
            #if targetEnvironment(simulator)
            LinearGradient(colors: [Color(hex: "#1C1714"), Color(hex: "#0D0B09")], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            #else
            BarcodeCameraPreview { code in
                onScanned(code)
                dismiss()
            }
            .ignoresSafeArea()
            #endif

            VStack {
                HStack {
                    Button("Abbrechen") { dismiss() }
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(NovelyTheme.creamText)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .novelyGlassCapsule()
                    Spacer()
                }
                .padding()

                Text("ISBN-Barcode in den Rahmen")
                    .font(.system(size: 20, weight: .semibold, design: .serif))
                    .foregroundStyle(NovelyTheme.creamText)

                Spacer()

                RoundedRectangle(cornerRadius: 18)
                    .strokeBorder(NovelyTheme.warmGold, lineWidth: 2.5)
                    .frame(width: 270, height: 150)
                    .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 18))

                Spacer()

                // Manual fallback (also super handy in simulator)
                HStack {
                    TextField("ISBN eintippen (z. B. 9783423283977)", text: $manualISBN)
                        .keyboardType(.numberPad)
                        .padding(12)
                        .background(Color.black.opacity(0.6), in: RoundedRectangle(cornerRadius: 12))
                    Button("Suchen") {
                        guard !manualISBN.isEmpty else { return }
                        onScanned(manualISBN)
                        dismiss()
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(NovelyTheme.creamText, in: RoundedRectangle(cornerRadius: 12))
                }
                .padding()
            }
        }
    }
}

private struct BarcodeCameraPreview: UIViewControllerRepresentable {
    let onCode: (String) -> Void

    func makeUIViewController(context: Context) -> BarcodeScannerVC {
        let vc = BarcodeScannerVC()
        vc.onCode = onCode
        return vc
    }

    func updateUIViewController(_ uiViewController: BarcodeScannerVC, context: Context) {}
}

private final class BarcodeScannerVC: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    var onCode: ((String) -> Void)?
    private let session = AVCaptureSession()
    private var didEmit = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else { return }
        session.addInput(input)

        let output = AVCaptureMetadataOutput()
        guard session.canAddOutput(output) else { return }
        session.addOutput(output)
        output.setMetadataObjectsDelegate(self, queue: .main)
        output.metadataObjectTypes = [.ean13, .ean8]

        let preview = AVCaptureVideoPreviewLayer(session: session)
        preview.frame = view.bounds
        preview.videoGravity = .resizeAspectFill
        view.layer.addSublayer(preview)

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.session.startRunning()
        }
    }

    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        guard !didEmit,
              let obj = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              let str = obj.stringValue else { return }
        didEmit = true
        session.stopRunning()
        onCode?(str)
    }
}

// MARK: - 2. Book Spine Scanner (Novely Screenshot #3 Aesthetic)

struct SpineScannerView: View {
    @Environment(\.dismiss) private var dismiss
    let book: Book?
    let onCapturedSpine: (Data) -> Void

    @State private var pickerItem: PhotosPickerItem?

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "#2B211A"), Color(hex: "#140F0C")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 16) {
                HStack {
                    Button("Abbrechen") { dismiss() }
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(NovelyTheme.creamText)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .novelyGlassCapsule()
                    Spacer()
                }
                .padding(.horizontal)

                VStack(spacing: 4) {
                    Text("Buchrücken in den Rahmen")
                        .font(.system(size: 20, weight: .semibold, design: .serif))
                        .foregroundStyle(NovelyTheme.creamText)
                    Text("Oben und unten bündig mit dem Rahmen ausrichten")
                        .font(.system(size: 12))
                        .foregroundStyle(NovelyTheme.warmMutedText)
                }

                Spacer()

                // Glowing vertical spine bounding box
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.white.opacity(0.06))
                        .frame(width: 72, height: 340)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .strokeBorder(NovelyTheme.creamText, lineWidth: 2.5)
                                .shadow(color: NovelyTheme.warmGold.opacity(0.75), radius: 10)
                        )

                    if let book {
                        Text(book.title)
                            .font(.system(size: 14, weight: .medium, design: .serif))
                            .foregroundStyle(NovelyTheme.creamText.opacity(0.55))
                            .rotationEffect(.degrees(-90))
                            .frame(width: 300)
                    }
                }

                Spacer()

                PhotosPicker(selection: $pickerItem, matching: .images) {
                    Label("Buchrücken-Foto auswählen", systemImage: "photo.on.rectangle.angled")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 14)
                        .background(NovelyTheme.creamText, in: Capsule())
                }
                .padding(.bottom, 26)
            }
            .padding(.top, 12)
        }
        .onChange(of: pickerItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                    onCapturedSpine(data)
                    dismiss()
                }
            }
        }
    }
}

// MARK: - 3. Quote OCR Scanner (Novely Screenshot #9 Aesthetic + Apple Vision OCR)

struct QuoteOCRScannerView: View {
    @Environment(\.dismiss) private var dismiss
    let book: Book?
    let onSaveQuote: (String, Int?) -> Void

    @State private var pickerItem: PhotosPickerItem?
    @State private var recognizedText: String = "Als Gregor Samsa eines Morgens aus unruhigen Träumen erwachte…"
    @State private var pageText: String = "5"
    @State private var isProcessing = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "#1E1916"), Color(hex: "#100D0B")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 20) {
                HStack {
                    Button("Abbrechen") { dismiss() }
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(NovelyTheme.creamText)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .novelyGlassCapsule()
                    Spacer()
                    Text("Zitat-Scanner")
                        .font(.system(size: 16, weight: .semibold, design: .serif))
                        .foregroundStyle(NovelyTheme.creamText)
                    Spacer()
                    Color.clear.frame(width: 80, height: 1)
                }
                .padding(.horizontal)

                // Floating Dark Serif Quote Card (Novely Screenshot #9)
                VStack(alignment: .leading, spacing: 14) {
                    if let book {
                        Text("\(book.title) — \(book.author) · Seite \(pageText.isEmpty ? "?" : pageText)")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(NovelyTheme.warmGold)
                    }

                    TextEditor(text: $recognizedText)
                        .font(.system(size: 20, weight: .regular, design: .serif))
                        .italic()
                        .foregroundStyle(NovelyTheme.creamText)
                        .scrollContentBackground(.hidden)
                        .frame(minHeight: 130, maxHeight: 180)

                    HStack {
                        Text("Seite:")
                            .font(.system(size: 13))
                            .foregroundStyle(NovelyTheme.warmMutedText)
                        TextField("5", text: $pageText)
                            .keyboardType(.numberPad)
                            .frame(width: 60)
                            .padding(6)
                            .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
                        Spacer()
                        if isProcessing {
                            ProgressView().tint(NovelyTheme.warmGold)
                        }
                    }
                }
                .padding(20)
                .novelyGlassCard(cornerRadius: 24)
                .padding(.horizontal, 18)

                Spacer()

                VStack(spacing: 12) {
                    PhotosPicker(selection: $pickerItem, matching: .images) {
                        Label("Buchseite per OCR auslesen", systemImage: "text.viewfinder")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(NovelyTheme.creamText)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .novelyGlassCapsule(tint: NovelyTheme.terracotta.opacity(0.32))
                    }

                    Button {
                        let cleaned = recognizedText.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !cleaned.isEmpty else { return }
                        onSaveQuote(cleaned, Int(pageText))
                        dismiss()
                    } label: {
                        Text("Zitat speichern")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(NovelyTheme.creamText, in: Capsule())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
            .padding(.top, 12)
        }
        .onChange(of: pickerItem) { _, newItem in
            Task {
                guard let data = try? await newItem?.loadTransferable(type: Data.self),
                      let uiImage = UIImage(data: data),
                      let cgImage = uiImage.cgImage else { return }
                await runVisionOCR(on: cgImage)
            }
        }
    }

    private func runVisionOCR(on cgImage: CGImage) async {
        isProcessing = true
        defer { isProcessing = false }

        let text: String = await withCheckedContinuation { continuation in
            let request = VNRecognizeTextRequest { req, _ in
                let observations = req.results as? [VNRecognizedTextObservation] ?? []
                let lines = observations.compactMap { $0.topCandidates(1).first?.string }
                continuation.resume(returning: lines.joined(separator: " "))
            }
            request.recognitionLanguages = ["de-DE", "en-US"]
            request.recognitionLevel = .accurate

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            try? handler.perform([request])
        }

        if !text.isEmpty {
            recognizedText = text
        }
    }
}
