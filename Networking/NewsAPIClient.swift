//
//  NewsAPIClient.swift
//  ReaderApp
//
//  Created by Assistant on 19/10/25.
//

import Foundation

final class NewsAPIClient {
    static let shared = NewsAPIClient()

    private let session: URLSession
    private let baseURL = URL(string: "https://newsapi.org/v2")!
    private let apiKey = "eade34f6438d453182bbb30cc4d8309a"

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetchTopHeadlines(country: String = "us") async throws -> [Article] {
        var components = URLComponents(url: baseURL.appendingPathComponent("top-headlines"), resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "country", value: country),
            URLQueryItem(name: "apiKey", value: apiKey)
        ]
        let url = components.url!
        let (data, response) = try await session.data(from: url)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        let decoded = try JSONDecoder().decode(NewsAPIResponse.self, from: data)
        return decoded.articles
    }
}


