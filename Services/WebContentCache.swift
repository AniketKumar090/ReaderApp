import Foundation

final class WebContentCache {
    static let shared = WebContentCache()
    
    private let cacheDirectory: URL
    private let fileManager = FileManager.default
    
    private init() {
        let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.cacheDirectory = documents.appendingPathComponent("WebContentCache")
        
        // Create cache directory if it doesn't exist
        if !fileManager.fileExists(atPath: cacheDirectory.path) {
            try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        }
    }
    
    func cacheWebContent(for article: Article, htmlContent: String) {
        let fileName = sanitizeFileName(article.id) + ".html"
        let fileURL = cacheDirectory.appendingPathComponent(fileName)
        
        do {
            try htmlContent.write(to: fileURL, atomically: true, encoding: .utf8)
            print("💾 Cached content at: \(fileURL.lastPathComponent)")
        } catch {
            print("❌ Failed to cache web content: \(error)")
        }
    }
    
    func getCachedWebContent(for article: Article) -> String? {
        let fileName = sanitizeFileName(article.id) + ".html"
        let fileURL = cacheDirectory.appendingPathComponent(fileName)
        
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return nil
        }
        
        do {
            let content = try String(contentsOf: fileURL, encoding: .utf8)
            return content
        } catch {
            print("❌ Failed to read cached web content: \(error)")
            return nil
        }
    }
    
    func hasCachedContent(for article: Article) -> Bool {
        let fileName = sanitizeFileName(article.id) + ".html"
        let fileURL = cacheDirectory.appendingPathComponent(fileName)
        return fileManager.fileExists(atPath: fileURL.path)
    }
    
    func removeCachedContent(for article: Article) {
        let fileName = sanitizeFileName(article.id) + ".html"
        let fileURL = cacheDirectory.appendingPathComponent(fileName)
        
        if fileManager.fileExists(atPath: fileURL.path) {
            try? fileManager.removeItem(at: fileURL)
        }
    }
    
    func clearCache() {
        do {
            let files = try fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil)
            for file in files {
                try fileManager.removeItem(at: file)
            }
            print("🗑️ Cache cleared")
        } catch {
            print("❌ Failed to clear web content cache: \(error)")
        }
    }
    
    // Helper to create safe filenames
    private func sanitizeFileName(_ string: String) -> String {
        let allowedCharacters = CharacterSet.alphanumerics
        return string.components(separatedBy: allowedCharacters.inverted).joined()
    }
}
