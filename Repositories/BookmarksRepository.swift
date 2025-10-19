//
//  BookmarksRepository.swift
//  ReaderApp
//
//  Created by Assistant on 19/10/25.
//

import Foundation
import WebKit

final class BookmarksRepository {
    static let shared = BookmarksRepository()

    private let fileURL: URL
    private var bookmarkedById: Set<String> = []
    private let queue = DispatchQueue(label: "bookmarks.repo.queue", qos: .userInitiated)

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
            bookmarkedById.remove(article.id)
        } else {
            bookmarkedById.insert(article.id)
        }
        save()
        
        // If we just bookmarked an article, try to cache its content
        if !wasBookmarked {
            cacheArticleContent(article)
        }
        
        // Post notification for UI updates
        BookmarkNotificationCenter.shared.postBookmarkChange(article: article, isBookmarked: bookmarkedById.contains(article.id))
    }
    
    private func cacheArticleContent(_ article: Article) {
        guard let urlString = article.url, let url = URL(string: urlString) else { return }
        
        // Create a temporary webview to load and cache the content
        let webView = WKWebView(frame: .zero)
        let webCache = WebContentCache.shared
        
        // Load the URL
        webView.load(URLRequest(url: url))
        
        // Wait for content to load, then cache it
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            webView.evaluateJavaScript("document.documentElement.outerHTML") { result, error in
                guard let htmlContent = result as? String, error == nil else {
                    print("Failed to cache content for article '\(article.title ?? "Unknown")': \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                
                webCache.cacheWebContent(for: article, htmlContent: htmlContent)
                print("Successfully cached content for bookmarked article: \(article.title ?? "Unknown")")
            }
        }
    }

    func allBookmarked(from articles: [Article]) -> [Article] {
        return articles.filter { bookmarkedById.contains($0.id) }
    }
    
    func preCacheAllBookmarkedArticles(from articles: [Article]) {
        let bookmarkedArticles = allBookmarked(from: articles)
        let webCache = WebContentCache.shared
        
        for article in bookmarkedArticles {
            // Only cache if not already cached
            if !webCache.hasCachedContent(for: article) {
                cacheArticleContent(article)
            }
        }
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


