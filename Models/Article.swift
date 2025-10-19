//
//  Article.swift
//  ReaderApp
//
//  Created by Assistant on 19/10/25.
//

import Foundation

struct NewsAPIResponse: Codable {
    let status: String
    let totalResults: Int?
    let articles: [Article]
}

struct ArticleSource: Codable, Equatable, Hashable {
    let id: String?
    let name: String?
}

struct Article: Codable, Equatable, Hashable {
    let source: ArticleSource?
    let author: String?
    let title: String?
    let description: String?
    let url: String?
    let urlToImage: String?
    let publishedAt: String?
    let content: String?

    var id: String { url ?? (title ?? UUID().uuidString) }
}


