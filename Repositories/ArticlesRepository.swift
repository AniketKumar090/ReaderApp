//
//  ArticlesRepository.swift
//  ReaderApp
//
//  Created by Assistant on 19/10/25.
//

import Foundation

protocol ArticlesRepositoryType {
    func fetchArticles(forceRefresh: Bool) async -> [Article]
}

final class ArticlesRepository: ArticlesRepositoryType {
    private let api: NewsAPIClient
    private let cacheURL: URL

    init(api: NewsAPIClient = .shared) {
        self.api = api
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.cacheURL = documents.appendingPathComponent("articles_cache.json")
    }

    func fetchArticles(forceRefresh: Bool) async -> [Article] {
        if !forceRefresh {
            if let cached = readCache() {
                return cached
            }
        }
        do {
            let articles = try await api.fetchTopHeadlines()
            writeCache(articles: articles)
            return articles
        } catch {
            return readCache() ?? []
        }
    }

    private func writeCache(articles: [Article]) {
        do {
            let data = try JSONEncoder().encode(articles)
            try data.write(to: cacheURL, options: .atomic)
        } catch {
            // ignore cache write errors
        }
    }

    private func readCache() -> [Article]? {
        guard let data = try? Data(contentsOf: cacheURL) else { return nil }
        return try? JSONDecoder().decode([Article].self, from: data)
    }
}


