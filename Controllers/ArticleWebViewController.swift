//
//  ArticleWebViewController.swift
//  ReaderApp
//
//  Created by Assistant on 19/10/25.
//

import UIKit
import WebKit

final class ArticleWebViewController: UIViewController {
    private let webView = WKWebView(frame: .zero)
    private let url: URL
    private let article: Article
    private let bookmarkRepo = BookmarksRepository.shared
    private let webCache = WebContentCache.shared
    private var isContentCached = false

    init(url: URL, article: Article) {
        self.url = url
        self.article = article
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Web View"
        setupWeb()
        setupBookmarkButton()
        loadWebContent()
    }

    private func setupWeb() {
        webView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(webView)
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func setupBookmarkButton() {
        let item = UIBarButtonItem(image: UIImage(systemName: bookmarkRepo.isBookmarked(article) ? "bookmark.fill" : "bookmark"), style: .plain, target: self, action: #selector(toggleBookmark))
        navigationItem.rightBarButtonItem = item
    }

    @objc private func toggleBookmark() {
        bookmarkRepo.toggleBookmark(article)
        setupBookmarkButton()
        
        // Cache web content when bookmarked (additional caching from webview)
        if bookmarkRepo.isBookmarked(article) && !isContentCached {
            cacheCurrentWebContent()
        }
    }
    
    private func loadWebContent() {
        // Check if we have cached content for this article
        if let cachedContent = webCache.getCachedWebContent(for: article) {
            print("Loading cached content for article: \(article.title ?? "Unknown")")
            webView.loadHTMLString(cachedContent, baseURL: url)
            isContentCached = true
        } else {
            print("No cached content found, loading from URL: \(url)")
            // Load from URL
            webView.load(URLRequest(url: url))
        }
    }
    
    private func cacheCurrentWebContent() {
        // Wait a bit for the page to fully load before caching
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            self?.webView.evaluateJavaScript("document.documentElement.outerHTML") { [weak self] result, error in
                guard let self = self,
                      let htmlContent = result as? String,
                      error == nil else { 
                    print("Failed to get HTML content: \(error?.localizedDescription ?? "Unknown error")")
                    return 
                }
                
                print("Caching content for article: \(self.article.title ?? "Unknown")")
                self.webCache.cacheWebContent(for: self.article, htmlContent: htmlContent)
                self.isContentCached = true
            }
        }
    }
}


