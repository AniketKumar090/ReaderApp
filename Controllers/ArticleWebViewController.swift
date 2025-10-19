import UIKit
import WebKit

final class ArticleWebViewController: UIViewController, WKNavigationDelegate {
    private let webView = WKWebView(frame: .zero)
    private let url: URL
    private let article: Article
    private let bookmarkRepo = BookmarksRepository.shared
    private let webCache = WebContentCache.shared
    private var pageFullyLoaded = false
    private let activityIndicator = UIActivityIndicatorView(style: .large)

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
        title = "Article"
        webView.navigationDelegate = self
        setupWeb()
        setupActivityIndicator()
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
    
    private func setupActivityIndicator() {
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.hidesWhenStopped = true
        view.addSubview(activityIndicator)
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    private func setupBookmarkButton() {
        let isBookmarked = bookmarkRepo.isBookmarked(article)
        let imageName = isBookmarked ? "bookmark.fill" : "bookmark"
        let item = UIBarButtonItem(
            image: UIImage(systemName: imageName),
            style: .plain,
            target: self,
            action: #selector(toggleBookmark)
        )
        navigationItem.rightBarButtonItem = item
    }

    @objc private func toggleBookmark() {
        let wasBookmarked = bookmarkRepo.isBookmarked(article)
        bookmarkRepo.toggleBookmark(article)
        setupBookmarkButton()
        
        // If we just bookmarked and page is fully loaded, cache it immediately
        if !wasBookmarked && pageFullyLoaded {
            cacheCurrentWebContent()
        }
        
        // If we just unbookmarked, remove cached content
        if wasBookmarked {
            webCache.removeCachedContent(for: article)
            print("Removed cached content for unbookmarked article: \(article.title ?? "Unknown")")
        }
    }
    
    private func loadWebContent() {
        // First check if we have cached content
        if let cachedContent = webCache.getCachedWebContent(for: article) {
            print("✅ Loading cached content for article: \(article.title ?? "Unknown")")
            // Use the original URL as baseURL so relative resources can load
            webView.loadHTMLString(cachedContent, baseURL: url)
        } else {
            // No cache, try to load from URL
            print("🌐 Loading from URL: \(url)")
            activityIndicator.startAnimating()
            webView.load(URLRequest(url: url))
        }
    }
    
    private func cacheCurrentWebContent() {
        webView.evaluateJavaScript("document.documentElement.outerHTML") { [weak self] result, error in
            guard let self = self,
                  let htmlContent = result as? String,
                  error == nil else {
                print("❌ Failed to get HTML content: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            self.webCache.cacheWebContent(for: self.article, htmlContent: htmlContent)
            print("💾 Successfully cached content for: \(self.article.title ?? "Unknown")")
        }
    }
    
    // MARK: - WKNavigationDelegate
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        activityIndicator.stopAnimating()
        pageFullyLoaded = true
        
        // If article is bookmarked, cache the content now that it's fully loaded
        if bookmarkRepo.isBookmarked(article) {
            // Wait a moment for any dynamic content to load
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
                self?.cacheCurrentWebContent()
            }
        }
        
        print("✅ Page loaded successfully")
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        activityIndicator.stopAnimating()
        print("❌ WebView failed to load: \(error.localizedDescription)")
        showOfflineError()
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        activityIndicator.stopAnimating()
        print("❌ WebView provisional navigation failed: \(error.localizedDescription)")
        showOfflineError()
    }
    
    private func showOfflineError() {
        // Only show error if we don't have cached content
        if webCache.getCachedWebContent(for: article) == nil {
            let alert = UIAlertController(
                title: "Unable to Load",
                message: "This article is not available offline. Please connect to the internet, open this article, and bookmark it to read offline later.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
        }
    }
}
