//
//  ArticlesViewModel.swift
//  ReaderApp
//
//  Created by Assistant on 19/10/25.
//

import Foundation

final class ArticlesViewModel {
    private let repository: ArticlesRepositoryType
    private(set) var allArticles: [Article] = []
    private(set) var visibleArticles: [Article] = []
    private(set) var isLoading: Bool = false

    var onChange: (() -> Void)?

    init(repository: ArticlesRepositoryType = ArticlesRepository()) {
        self.repository = repository
    }

    @MainActor
    func load(force: Bool = false) async {
        isLoading = true
        onChange?()
        let articles = await repository.fetchArticles(forceRefresh: force)
        allArticles = articles
        visibleArticles = articles
        isLoading = false
        onChange?()
        
        // Pre-cache content for all bookmarked articles
        BookmarksRepository.shared.preCacheAllBookmarkedArticles(from: articles)
    }

    func search(query: String) {
        guard !query.isEmpty else {
            visibleArticles = allArticles
            onChange?()
            return
        }
        let lower = query.lowercased()
        visibleArticles = allArticles.filter { ($0.title ?? "").lowercased().contains(lower) }
        onChange?()
    }
}


