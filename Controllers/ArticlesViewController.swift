//
//  ArticlesViewController.swift
//  ReaderApp
//
//  Created by Assistant on 19/10/25.
//

import UIKit

final class ArticlesViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchResultsUpdating {
    private let tableView = UITableView()
    private let refreshControl = UIRefreshControl()
    private let viewModel = ArticlesViewModel()
    private let searchController = UISearchController(searchResultsController: nil)
    private let bookmarkRepo = BookmarksRepository.shared

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Top Headlines"
        view.backgroundColor = .systemBackground
        setupTable()
        setupSearch()
        bind()
        Task { await viewModel.load(force: false) }
    }

    private func setupTable() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(ArticleCell.self, forCellReuseIdentifier: ArticleCell.reuseId)
        tableView.dataSource = self
        tableView.delegate = self
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        tableView.refreshControl = refreshControl
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func setupSearch() {
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search articles"
        searchController.searchResultsUpdater = self
        navigationItem.searchController = searchController
        definesPresentationContext = true
    }

    private func bind() {
        viewModel.onChange = { [weak self] in
            guard let self = self else { return }
            self.tableView.reloadData()
            if self.refreshControl.isRefreshing { self.refreshControl.endRefreshing() }
        }
        
        // Listen for bookmark changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleBookmarkChange),
            name: .bookmarkDidChange,
            object: nil
        )
    }
    
    @objc private func handleBookmarkChange(_ notification: Notification) {
        guard let bookmarkInfo = notification.object as? BookmarkNotification else { return }
        
        // Find the article in our current list and update its cell
        if let index = viewModel.visibleArticles.firstIndex(where: { $0.id == bookmarkInfo.article.id }) {
            let indexPath = IndexPath(row: index, section: 0)
            tableView.reloadRows(at: [indexPath], with: .none)
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func handleRefresh() {
        Task { await viewModel.load(force: true) }
    }

    // MARK: - UITableView
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.visibleArticles.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ArticleCell.reuseId, for: indexPath) as! ArticleCell
        let article = viewModel.visibleArticles[indexPath.row]
        cell.configure(with: article, isBookmarked: bookmarkRepo.isBookmarked(article))
        cell.onBookmarkTapped = { [weak self] in
            self?.bookmarkRepo.toggleBookmark(article)
            // No need to manually reload here, notification will handle it
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let article = viewModel.visibleArticles[indexPath.row]
        
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

    // MARK: - Search
    func updateSearchResults(for searchController: UISearchController) {
        viewModel.search(query: searchController.searchBar.text ?? "")
    }
}


