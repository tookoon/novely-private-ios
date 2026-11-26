import AVFoundation
import PhotosUI
import SwiftUI
import Vision

// MARK: - 1. ISBN Barcode Scanner (Live AVFoundation Camera)

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

                HStack {
                    TextField("ISBN eintippen (z. B. 9783442341887)", text: $manualISBN)
                        .keyboardType(.numberPad)
                        .padding(12)
                        .background(Color.black.opacity(0.65), in: RoundedRectangle(cornerRadius: 12))
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

// MARK: - 2. Live Camera Book Spine Scanner with Auto-Crop (Exact Reel 2 Flow!)

struct SpineScannerView: View {
    @Environment(\.dismiss) private var dismiss
    let book: Book?
    let onCapturedSpine: (Data) -> Void

    @StateObject private var cameraController = SpineCameraController()
    @State private var capturedPreviewImage: UIImage?
    @State private var pickerItem: PhotosPickerItem?

    var body: some View {
        ZStack {
            if let previewImg = capturedPreviewImage {
                // Confirmation Preview ("Ins Regal stellen" / "Nochmal" like Reel 2!)
                Color(hex: "#120E0C").ignoresSafeArea()
                VStack(spacing: 24) {
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

                    Spacer()

                    Image(uiImage: previewImg)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 390)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .shadow(color: .black.opacity(0.65), radius: 14, y: 8)

                    Spacer()

                    VStack(spacing: 12) {
                        Button {
                            if let jpeg = previewImg.jpegData(compressionQuality: 0.88) {
                                onCapturedSpine(jpeg)
                            }
                            dismiss()
                        } label: {
                            Text("Ins Regal stellen")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.black)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 15)
                                .background(NovelyTheme.creamText, in: Capsule())
                        }

                        Button("Nochmal fotografieren") {
                            capturedPreviewImage = nil
                        }
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(NovelyTheme.warmMutedText)
                        .padding(.vertical, 6)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 26)
                }
                .padding(.top, 12)
            } else {
                // Live Camera + Glowing Vertical Spine Frame
                #if targetEnvironment(simulator)
                LinearGradient(colors: [Color(hex: "#2B211A"), Color(hex: "#140F0C")], startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
                #else
                SpineCameraPreviewView(controller: cameraController)
                    .ignoresSafeArea()
                #endif

                VStack(spacing: 16) {
                    HStack {
                        Button("Abbrechen") { dismiss() }
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(NovelyTheme.creamText)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .novelyGlassCapsule()
                        Spacer()
                        PhotosPicker(selection: $pickerItem, matching: .images) {
                            Image(systemName: "photo.on.rectangle")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(NovelyTheme.creamText)
                                .padding(10)
                                .novelyGlassCapsule()
                        }
                    }
                    .padding(.horizontal)

                    VStack(spacing: 4) {
                        Text("Buchrücken in den Rahmen")
                            .font(.system(size: 20, weight: .semibold, design: .serif))
                            .foregroundStyle(NovelyTheme.creamText)
                        Text("Oben und unten bündig mit dem Rahmen ausrichten")
                            .font(.system(size: 12))
                            .foregroundStyle(NovelyTheme.creamText.opacity(0.8))
                    }

                    Spacer()

                    // Glowing vertical spine frame
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.white.opacity(0.04))
                        .frame(width: 78, height: 350)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .strokeBorder(NovelyTheme.creamText, lineWidth: 2.5)
                                .shadow(color: NovelyTheme.warmGold.opacity(0.85), radius: 10)
                        )

                    Spacer()

                    // Shutter Button (captures live photo & auto-crops the spine!)
                    Button {
                        cameraController.captureCroppedSpine { img in
                            if let img {
                                capturedPreviewImage = img
                            }
                        }
                    } label: {
                        ZStack {
                            Circle()
                                .strokeBorder(.white, lineWidth: 4)
                                .frame(width: 74, height: 74)
                            Circle()
                                .fill(.white)
                                .frame(width: 60, height: 60)
                        }
                    }
                    .padding(.bottom, 26)
                }
                .padding(.top, 12)
            }
        }
        .onChange(of: pickerItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let img = UIImage(data: data) {
                    capturedPreviewImage = img
                }
            }
        }
    }
}

private final class SpineCameraController: NSObject, ObservableObject, AVCapturePhotoCaptureDelegate {
    let session = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private var completion: ((UIImage?) -> Void)?

    override init() {
        super.init()
        configure()
    }

    private func configure() {
        #if !targetEnvironment(simulator)
        session.beginConfiguration()
        session.sessionPreset = .photo
        if let device = AVCaptureDevice.default(for: .video),
           let input = try? AVCaptureDeviceInput(device: device),
           session.canAddInput(input) {
            session.addInput(input)
        }
        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
        }
        session.commitConfiguration()
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.session.startRunning()
        }
        #endif
    }

    func captureCroppedSpine(completion: @escaping (UIImage?) -> Void) {
        self.completion = completion
        #if targetEnvironment(simulator)
        completion(nil)
        #else
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: self)
        #endif
    }

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let data = photo.fileDataRepresentation(),
              let rawImg = UIImage(data: data) else {
            DispatchQueue.main.async { self.completion?(nil) }
            return
        }
        let normalized = normalizeOrientation(rawImg)
        let cropped = cropCenterVerticalSpine(normalized)
        DispatchQueue.main.async {
            self.completion?(cropped)
        }
    }

    private func normalizeOrientation(_ image: UIImage) -> UIImage {
        if image.imageOrientation == .up { return image }
        UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
        image.draw(in: CGRect(origin: .zero, size: image.size))
        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return result ?? image
    }

    /// Automatically crops the center vertical spine rectangle matching the on-screen frame!
    private func cropCenterVerticalSpine(_ image: UIImage) -> UIImage {
        guard let cg = image.cgImage else { return image }
        let w = CGFloat(cg.width)
        let h = CGFloat(cg.height)
        let cropW = w * 0.22
        let cropH = h * 0.56
        let rect = CGRect(x: (w - cropW) / 2.0, y: (h - cropH) / 2.0, width: cropW, height: cropH)
        guard let cut = cg.cropping(to: rect) else { return image }
        return UIImage(cgImage: cut, scale: image.scale, orientation: .up)
    }
}

private struct SpineCameraPreviewView: UIViewRepresentable {
    let controller: SpineCameraController

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: UIScreen.main.bounds)
        let layer = AVCaptureVideoPreviewLayer(session: controller.session)
        layer.frame = view.bounds
        layer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(layer)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}

// MARK: - 3. Quote OCR Scanner (Apple Vision OCR + Shareable Quote Card)

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
            LinearGradient(colors: [Color(hex: "#1E1916"), Color(hex: "#100D0B")], startPoint: .top, endPoint: .bottom)
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
                    ShareLink(item: "„\(recognizedText)“ — \(book?.title ?? "Novely")") {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundStyle(NovelyTheme.warmGold)
                            .padding(8)
                            .novelyGlassCapsule()
                    }
                }
                .padding(.horizontal)

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
