import Foundation

final class BookmarksRepository {
    static let shared = BookmarksRepository()

    private let fileURL: URL
    private var bookmarkedById: Set<String> = []

    private init() {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.fileURL = documents.appendingPathComponent("bookmarks.json")
        load()
    }

    func isBookmarked(_ article: Article) -> Bool {
        return bookmarkedById.contains(article.id)
    }

    func toggleBookmark(_ article: Article) {
        let wasBookmarked = bookmarkedById.contains(article.id)
        
        if wasBookmarked {
            // Unbookmarking
            bookmarkedById.remove(article.id)
            // Remove cached content
            WebContentCache.shared.removeCachedContent(for: article)
        } else {
            // Bookmarking
            bookmarkedById.insert(article.id)
            // Preload content in background
            WebContentPreloader.shared.preloadContent(for: article)
        }
        
        save()
        
        // Post notification for UI updates
        BookmarkNotificationCenter.shared.postBookmarkChange(
            article: article,
            isBookmarked: bookmarkedById.contains(article.id)
        )
    }

    func allBookmarked(from articles: [Article]) -> [Article] {
        return articles.filter { bookmarkedById.contains($0.id) }
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL) else { return }
        if let ids = try? JSONDecoder().decode([String].self, from: data) {
            bookmarkedById = Set(ids)
        }
    }

    private func save() {
        let ids = Array(bookmarkedById)
        if let data = try? JSONEncoder().encode(ids) {
            try? data.write(to: fileURL, options: .atomic)
        }
    }
}
