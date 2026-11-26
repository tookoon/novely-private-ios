import Foundation
import UIKit

// MARK: - Online Book Search Result (Google Books + Open Library)

public struct OnlineBookResult: Identifiable, Hashable {
    public let id = UUID()
    public let title: String
    public let author: String
    public let isbn: String
    public let pageCount: Int
    public let publisher: String
    public let publishedYear: String
    public let bindingType: String
    public let bookDescription: String
    public let coverURLString: String?
}

public enum BookMetadataService {

    /// Searches Google Books first (rich German metadata, real covers & Klappentext),
    /// then merges/falls back to Open Library if needed.
    public static func searchBooks(query: String) async -> [OnlineBookResult] {
        let cleaned = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return [] }

        let digitsOnly = cleaned.filter(\.isNumber)
        let isISBN = digitsOnly.count == 10 || digitsOnly.count == 13

        let googleResults = await searchGoogleBooks(query: isISBN ? "isbn:\(digitsOnly)" : cleaned)
        if !googleResults.isEmpty {
            return googleResults
        }
        return await searchOpenLibrary(query: cleaned, isbnOverride: isISBN ? digitsOnly : nil)
    }

    private static func searchGoogleBooks(query: String) async -> [OnlineBookResult] {
        guard let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://www.googleapis.com/books/v1/volumes?q=\(encoded)&maxResults=8&langRestrict=de") else {
            return []
        }

        var items = await fetchGoogleVolumes(url: url)
        if items.isEmpty,
           let fallbackURL = URL(string: "https://www.googleapis.com/books/v1/volumes?q=\(encoded)&maxResults=8") {
            items = await fetchGoogleVolumes(url: fallbackURL)
        }
        return items
    }

    private static func fetchGoogleVolumes(url: URL) async -> [OnlineBookResult] {
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let items = json["items"] as? [[String: Any]] else { return [] }

            return items.compactMap { item -> OnlineBookResult? in
                guard let info = item["volumeInfo"] as? [String: Any],
                      let title = info["title"] as? String else { return nil }

                let authors = info["authors"] as? [String] ?? []
                let author = authors.joined(separator: ", ")
                let publisher = info["publisher"] as? String ?? ""
                let publishedDate = info["publishedDate"] as? String ?? ""
                let year = String(publishedDate.prefix(4))
                let pages = info["pageCount"] as? Int ?? 340
                let description = info["description"] as? String ?? ""

                var isbn = ""
                if let identifiers = info["industryIdentifiers"] as? [[String: Any]] {
                    isbn = (identifiers.first(where: { ($0["type"] as? String) == "ISBN_13" })?["identifier"] as? String)
                        ?? (identifiers.first?["identifier"] as? String)
                        ?? ""
                }

                var coverURL: String? = nil
                if let links = info["imageLinks"] as? [String: Any] {
                    let raw = (links["large"] as? String)
                        ?? (links["medium"] as? String)
                        ?? (links["thumbnail"] as? String)
                        ?? (links["smallThumbnail"] as? String)
                    if let raw {
                        coverURL = raw
                            .replacingOccurrences(of: "http://", with: "https://")
                            .replacingOccurrences(of: "&edge=curl", with: "")
                    }
                } else if !isbn.isEmpty {
                    coverURL = "https://covers.openlibrary.org/b/isbn/\(isbn)-L.jpg"
                }

                return OnlineBookResult(
                    title: title,
                    author: author.isEmpty ? "Unbekannt" : author,
                    isbn: isbn,
                    pageCount: max(20, pages),
                    publisher: publisher,
                    publishedYear: year,
                    bindingType: "Gebunden",
                    bookDescription: description,
                    coverURLString: coverURL
                )
            }
        } catch {
            return []
        }
    }

    private static func searchOpenLibrary(query: String, isbnOverride: String?) async -> [OnlineBookResult] {
        guard let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://openlibrary.org/search.json?q=\(encoded)&limit=8") else {
            return []
        }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let docs = json["docs"] as? [[String: Any]] else { return [] }

            return docs.compactMap { doc in
                guard let title = doc["title"] as? String else { return nil }
                let authors = doc["author_name"] as? [String]
                let isbns = doc["isbn"] as? [String]
                let isbn = isbnOverride ?? isbns?.first ?? ""
                let publishers = doc["publisher"] as? [String]
                let pages = doc["number_of_pages_median"] as? Int ?? 340
                let year = (doc["first_publish_year"] as? Int).map(String.init) ?? ""

                var coverURL: String? = nil
                if let coverId = doc["cover_i"] as? Int {
                    coverURL = "https://covers.openlibrary.org/b/id/\(coverId)-L.jpg"
                } else if !isbn.isEmpty {
                    coverURL = "https://covers.openlibrary.org/b/isbn/\(isbn)-L.jpg"
                }

                return OnlineBookResult(
                    title: title,
                    author: authors?.first ?? "Unbekannt",
                    isbn: isbn,
                    pageCount: max(20, pages),
                    publisher: publishers?.first ?? "",
                    publishedYear: year,
                    bindingType: "Gebunden",
                    bookDescription: "",
                    coverURLString: coverURL
                )
            }
        } catch {
            return []
        }
    }

    /// Downloads a real book cover image, saves it locally for offline & WidgetKit usage,
    /// and extracts a matching dark-rich dominant hex color for the book spine!
    public static func downloadAndStoreCover(urlString: String?, isbn: String) async -> (filename: String, dominantHex: String?)? {
        var candidates: [URL] = []
        if let urlString, let url = URL(string: urlString) {
            candidates.append(url)
        }
        let cleanISBN = isbn.filter(\.isNumber)
        if cleanISBN.count == 10 || cleanISBN.count == 13,
           let olURL = URL(string: "https://covers.openlibrary.org/b/isbn/\(cleanISBN)-L.jpg?default=false") {
            candidates.append(olURL)
        }

        for url in candidates {
            do {
                let (data, response) = try await URLSession.shared.data(from: url)
                guard let http = response as? HTTPURLResponse,
                      (200...299).contains(http.statusCode),
                      data.count > 2500,
                      let image = UIImage(data: data),
                      image.size.width >= 60 else { continue }

                guard let jpegData = image.jpegData(compressionQuality: 0.85),
                      let filename = LibraryStorage.saveImageData(jpegData, prefix: "cover") else {
                    continue
                }
                let dominantHex = extractDominantHex(from: image)
                return (filename, dominantHex)
            } catch {
                continue
            }
        }
        return nil
    }

    public static func extractDominantHex(from image: UIImage) -> String? {
        guard let cgImage = image.cgImage else { return nil }
        let width = 8
        let height = 8
        var pixelData = [UInt8](repeating: 0, count: width * height * 4)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(
            data: &pixelData,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        var rSum = 0, gSum = 0, bSum = 0, count = 0
        for i in stride(from: 0, to: pixelData.count, by: 4) {
            rSum += Int(pixelData[i])
            gSum += Int(pixelData[i + 1])
            bSum += Int(pixelData[i + 2])
            count += 1
        }
        guard count > 0 else { return nil }
        let r = min(220, max(28, rSum / count))
        let g = min(220, max(24, gSum / count))
        let b = min(220, max(24, bSum / count))
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}
