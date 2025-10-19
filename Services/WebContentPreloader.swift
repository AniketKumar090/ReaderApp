import Foundation
import WebKit

/// Background service to preload and cache web content for bookmarked articles
final class WebContentPreloader: NSObject, WKNavigationDelegate {
    static let shared = WebContentPreloader()
    
    private var webView: WKWebView?
    private var currentArticle: Article?
    private var pendingArticles: [Article] = []
    private let webCache = WebContentCache.shared
    private var isLoading = false
    
    private override init() {
        super.init()
    }
    
    /// Preload web content for an article (to be called when bookmarking)
    func preloadContent(for article: Article) {
        // Check if already cached
        if webCache.hasCachedContent(for: article) {
            print("✅ Content already cached for: \(article.title ?? "Unknown")")
            return
        }
        
        // Check if we have a valid URL
        guard let urlString = article.url, let url = URL(string: urlString) else {
            print("❌ Invalid URL for article: \(article.title ?? "Unknown")")
            return
        }
        
        // Add to pending queue if already loading something
        if isLoading {
            if !pendingArticles.contains(where: { $0.id == article.id }) {
                pendingArticles.append(article)
                print("📝 Added to queue: \(article.title ?? "Unknown")")
            }
            return
        }
        
        // Start loading
        startLoading(article: article, url: url)
    }
    
    private func startLoading(article: Article, url: URL) {
        isLoading = true
        currentArticle = article
        
        print("🌐 Preloading content for: \(article.title ?? "Unknown")")
        
        // Create webview if needed
        if webView == nil {
            let config = WKWebViewConfiguration()
            config.websiteDataStore = .default()
            webView = WKWebView(frame: .zero, configuration: config)
            webView?.navigationDelegate = self
        }
        
        webView?.load(URLRequest(url: url))
    }
    
    // MARK: - WKNavigationDelegate
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        guard let article = currentArticle else {
            finishCurrentLoad()
            return
        }
        
        // Wait a moment for dynamic content to load
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            guard let self = self else { return }
            
            webView.evaluateJavaScript("document.documentElement.outerHTML") { result, error in
                guard let htmlContent = result as? String, error == nil else {
                    print("❌ Failed to extract HTML for: \(article.title ?? "Unknown")")
                    self.finishCurrentLoad()
                    return
                }
                
                self.webCache.cacheWebContent(for: article, htmlContent: htmlContent)
                print("💾 Successfully preloaded and cached: \(article.title ?? "Unknown")")
                
                self.finishCurrentLoad()
            }
        }
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("❌ Failed to preload: \(error.localizedDescription)")
        finishCurrentLoad()
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        print("❌ Failed provisional navigation: \(error.localizedDescription)")
        finishCurrentLoad()
    }
    
    private func finishCurrentLoad() {
        currentArticle = nil
        isLoading = false
        
        // Process next article in queue
        if !pendingArticles.isEmpty {
            let nextArticle = pendingArticles.removeFirst()
            if let urlString = nextArticle.url, let url = URL(string: urlString) {
                startLoading(article: nextArticle, url: url)
            } else {
                finishCurrentLoad()
            }
        }
    }
    
    /// Cancel all pending preloads
    func cancelAll() {
        pendingArticles.removeAll()
        webView?.stopLoading()
        currentArticle = nil
        isLoading = false
    }
}
