//
//  BookmarksViewController.swift
//  ReaderApp
//
//  Created by Assistant on 19/10/25.
//

import UIKit

final class BookmarksViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    private let tableView = UITableView()
    private let repository = ArticlesRepository()
    private var allArticles: [Article] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Bookmarks"
        view.backgroundColor = .systemBackground
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(ArticleCell.self, forCellReuseIdentifier: ArticleCell.reuseId)
        tableView.dataSource = self
        tableView.delegate = self
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        Task {
            let articles = await repository.fetchArticles(forceRefresh: false)
            self.allArticles = BookmarksRepository.shared.allBookmarked(from: articles)
            self.tableView.reloadData()
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return allArticles.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ArticleCell.reuseId, for: indexPath) as! ArticleCell
        cell.configure(with: allArticles[indexPath.row], isBookmarked: true)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let article = allArticles[indexPath.row]
        
        // Check if we have cached content for this article
        let webCache = WebContentCache.shared
        if webCache.hasCachedContent(for: article) {
            // Use cached content even if offline
            if let urlString = article.url, let url = URL(string: urlString) {
                let vc = ArticleWebViewController(url: url, article: article)
                navigationController?.pushViewController(vc, animated: true)
            }
        } else if let urlString = article.url, let url = URL(string: urlString) {
            // Load from URL (will work if online)
            let vc = ArticleWebViewController(url: url, article: article)
            navigationController?.pushViewController(vc, animated: true)
        }
    }
}


