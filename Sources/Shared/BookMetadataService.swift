import Foundation
import UIKit

// MARK: - Online Book Search Result (Apple Books + Google Books + Open Library)

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

    /// Searches Apple Books (DE) and Google Books, merging/enriching high-res covers and German synopses.
    public static func searchBooks(query: String) async -> [OnlineBookResult] {
        let cleaned = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return [] }

        let digitsOnly = cleaned.filter(\.isNumber)
        let isISBN = digitsOnly.count == 10 || digitsOnly.count == 13

        if isISBN {
            // ISBN lookup: Google Books is strongest for ISBN -> metadata, then enrich missing cover via Apple Books
            var googleResults = await searchGoogleBooks(query: "isbn:\(digitsOnly)")
            if googleResults.isEmpty {
                googleResults = await searchOpenLibrary(query: cleaned, isbnOverride: digitsOnly)
            }
            if let first = googleResults.first, first.coverURLString == nil {
                let apple = await searchAppleBooks(query: "\(first.title) \(first.author)", country: "de")
                if let betterCover = apple.first?.coverURLString {
                    googleResults[0] = OnlineBookResult(
                        title: first.title,
                        author: first.author,
                        isbn: first.isbn,
                        pageCount: first.pageCount,
                        publisher: first.publisher,
                        publishedYear: first.publishedYear,
                        bindingType: first.bindingType,
                        bookDescription: first.bookDescription.isEmpty ? (apple.first?.bookDescription ?? "") : first.bookDescription,
                        coverURLString: betterCover
                    )
                }
            }
            return googleResults
        }

        // Title / author search: query Apple Books DE + Google Books concurrently
        async let appleTask = searchAppleBooks(query: cleaned, country: "de")
        async let googleTask = searchGoogleBooks(query: cleaned)

        let appleResults = await appleTask
        let googleResults = await googleTask

        if !appleResults.isEmpty {
            // Enrich Apple Books hits with ISBN/pageCount from Google Books if titles align, else append Google hits
            var merged: [OnlineBookResult] = []
            for appleItem in appleResults {
                let normTitle = appleItem.title.lowercased()
                let match = googleResults.first { $0.title.lowercased().contains(normTitle) || normTitle.contains($0.title.lowercased()) }
                merged.append(OnlineBookResult(
                    title: appleItem.title,
                    author: appleItem.author,
                    isbn: match?.isbn ?? appleItem.isbn,
                    pageCount: match?.pageCount ?? appleItem.pageCount,
                    publisher: match?.publisher.isEmpty == false ? match!.publisher : appleItem.publisher,
                    publishedYear: appleItem.publishedYear.isEmpty ? (match?.publishedYear ?? "") : appleItem.publishedYear,
                    bindingType: appleItem.bindingType,
                    bookDescription: appleItem.bookDescription.isEmpty ? (match?.bookDescription ?? "") : appleItem.bookDescription,
                    coverURLString: appleItem.coverURLString ?? match?.coverURLString
                ))
            }
            for g in googleResults where !merged.contains(where: { $0.title.lowercased() == g.title.lowercased() }) {
                merged.append(g)
            }
            return Array(merged.prefix(10))
        }

        if !googleResults.isEmpty {
            return googleResults
        }
        return await searchOpenLibrary(query: cleaned, isbnOverride: nil)
    }

    // MARK: - Apple Books / iTunes Search API (High-Res 600x600 German Covers!)

    public static func searchAppleBooks(query: String, country: String = "de") async -> [OnlineBookResult] {
        let cleaned = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty,
              let encoded = cleaned.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://itunes.apple.com/search?media=ebook&country=\(country)&limit=8&term=\(encoded)") else {
            return []
        }

        do {
            var req = URLRequest(url: url)
            req.timeoutInterval = 8
            let (data, _) = try await URLSession.shared.data(for: req)
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let results = json["results"] as? [[String: Any]] else { return [] }

            return results.compactMap { item -> OnlineBookResult? in
                guard let title = item["trackName"] as? String else { return nil }
                let author = item["artistName"] as? String ?? "Unbekannt"
                let rawDesc = item["description"] as? String ?? ""
                let cleanDesc = stripBasicHTML(rawDesc)
                let releaseDate = item["releaseDate"] as? String ?? ""
                let year = String(releaseDate.prefix(4))
                let artwork100 = item["artworkUrl100"] as? String
                let highResArtwork = artwork100?
                    .replacingOccurrences(of: "100x100bb", with: "600x600bb")
                    .replacingOccurrences(of: "http://", with: "https://")

                return OnlineBookResult(
                    title: title,
                    author: author,
                    isbn: "",
                    pageCount: 360,
                    publisher: "",
                    publishedYear: year,
                    bindingType: "Gebunden",
                    bookDescription: cleanDesc,
                    coverURLString: highResArtwork
                )
            }
        } catch {
            return []
        }
    }

    private static func stripBasicHTML(_ html: String) -> String {
        guard !html.isEmpty else { return "" }
        var text = html
            .replacingOccurrences(of: "<br\\s*/?>", with: "\n", options: .regularExpression)
            .replacingOccurrences(of: "</p>", with: "\n\n", options: .caseInsensitive)
            .replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
        text = text
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&apos;", with: "'")
            .replacingOccurrences(of: "&#39;", with: "'")
            .replacingOccurrences(of: "&nbsp;", with: " ")
        while text.contains("\n\n\n") {
            text = text.replacingOccurrences(of: "\n\n\n", with: "\n\n")
        }
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Google Books

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
            var req = URLRequest(url: url)
            req.timeoutInterval = 8
            let (data, _) = try await URLSession.shared.data(for: req)
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
                            .replacingOccurrences(of: "zoom=1", with: "zoom=2")
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

    // MARK: - Open Library

    private static func searchOpenLibrary(query: String, isbnOverride: String?) async -> [OnlineBookResult] {
        guard let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://openlibrary.org/search.json?q=\(encoded)&limit=8") else {
            return []
        }
        do {
            var req = URLRequest(url: url)
            req.timeoutInterval = 8
            let (data, _) = try await URLSession.shared.data(for: req)
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

    // MARK: - Best Cover Downloader (Cover URL -> Apple Books DE -> Apple Books US -> Google Books -> Open Library)

    public static func downloadBestCover(
        title: String,
        author: String,
        isbn: String,
        coverURLString: String?
    ) async -> (filename: String, dominantHex: String?)? {
        var candidateURLs: [String] = []
        if let coverURLString, !coverURLString.isEmpty {
            candidateURLs.append(coverURLString)
        }

        // Try fast direct URL first
        if let hit = await tryDownloadFromURLStrings(candidateURLs) {
            return hit
        }

        // Query Apple Books DE (high-res 600x600 real covers)
        let query = "\(title) \(author)".trimmingCharacters(in: .whitespacesAndNewlines)
        let appleDE = await searchAppleBooks(query: query, country: "de")
        var fallbackURLs = appleDE.compactMap(\.coverURLString)

        if fallbackURLs.isEmpty {
            let appleUS = await searchAppleBooks(query: query, country: "us")
            fallbackURLs.append(contentsOf: appleUS.compactMap(\.coverURLString))
        }

        if let hit = await tryDownloadFromURLStrings(Array(fallbackURLs.prefix(2))) {
            return hit
        }

        // Fallback to Google Books / Open Library ISBN cover
        var secondaryURLs: [String] = []
        let cleanISBN = isbn.filter(\.isNumber)
        if cleanISBN.count == 10 || cleanISBN.count == 13 {
            let google = await searchGoogleBooks(query: "isbn:\(cleanISBN)")
            secondaryURLs.append(contentsOf: google.compactMap(\.coverURLString))
            secondaryURLs.append("https://covers.openlibrary.org/b/isbn/\(cleanISBN)-L.jpg?default=false")
        } else {
            let google = await searchGoogleBooks(query: query)
            secondaryURLs.append(contentsOf: google.compactMap(\.coverURLString))
        }

        return await tryDownloadFromURLStrings(secondaryURLs)
    }

    public static func downloadAndStoreCover(urlString: String?, isbn: String) async -> (filename: String, dominantHex: String?)? {
        await downloadBestCover(title: "", author: "", isbn: isbn, coverURLString: urlString)
    }

    private static func tryDownloadFromURLStrings(_ urlStrings: [String]) async -> (filename: String, dominantHex: String?)? {
        for urlString in urlStrings {
            guard let url = URL(string: urlString) else { continue }
            do {
                var req = URLRequest(url: url)
                req.timeoutInterval = 8
                let (data, response) = try await URLSession.shared.data(for: req)
                guard let http = response as? HTTPURLResponse,
                      (200...299).contains(http.statusCode),
                      data.count > 2500,
                      let image = UIImage(data: data),
                      image.size.width >= 60 else { continue }

                guard let jpegData = image.jpegData(compressionQuality: 0.88),
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
