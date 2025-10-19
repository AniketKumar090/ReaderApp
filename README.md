# ReaderApp: A News Reader with Offline Support

> **A modern iOS news reader app built with UIKit and Swift Concurrency.**  
> Fetches articles from NewsAPI.org, supports offline viewing, bookmarking, search, and pull-to-refresh.

---

## 📌 Table of Contents

- [Features](#-features)
- [Architecture](#-architecture)
- [Installation](#-installation)
- [Usage](#-usage)
- [Contributing](#-contributing)
- [License](#-license)
- [Acknowledgments](#-acknowledgments)

---

## ✅ Features

This app fulfills all the requirements outlined in the assignment:

### 1. Fetch Articles
- Uses `URLSession` to fetch top headlines from [NewsAPI.org](https://newsapi.org).
- Displays article title, author (or source name), and thumbnail image.
- Supports Light/Dark mode via `.systemBackground`.

### 2. Offline Caching
- **Articles**: Cached locally as JSON in the Documents directory using `ArticlesRepository`.
- **Web Content**: Full HTML of bookmarked articles is cached locally for offline reading via `WebContentCache`.
- When offline, the app seamlessly displays cached data.

### 3. Pull-to-Refresh
- Implemented with `UIRefreshControl` in the main feed (`ArticlesViewController`).

### 4. Search Articles
- Integrated `UISearchController` to filter articles by title in real-time.

### 5. Bookmark Articles (Bonus)
- Users can tap the bookmark icon on any article to save it.
- Bookmarked articles are persisted to disk and displayed in a dedicated “Bookmarks” tab.
- Tapping a bookmarked article opens its full content, even offline if cached.

---

## 🏗️ Architecture

The app follows a **clean, modular architecture** with clear separation of concerns:

```
ReaderApp/
├── Controllers/          # View Controllers (UIKit)
│   ├── ArticlesViewController.swift
│   ├── ArticleWebViewController.swift
│   └── BookmarksViewController.swift
│
├── Models/               # Data models
│   └── Article.swift
│
├── Networking/           # Network layer
│   └── NewsAPIClient.swift
│
├── Repositories/         # Data access layer
│   ├── ArticlesRepository.swift
│   └── BookmarksRepository.swift
│
├── Services/             # Utility services
│   ├── BookmarkNotificationCenter.swift
│   ├── ImageLoader.swift
│   └── WebContentCache.swift
│
├── ViewModels/           # Business logic & state management
│   └── ArticlesViewModel.swift
│
├── Views/                # Custom UI components
│   └── ArticleCell.swift
│
├── AppDelegate.swift     # App lifecycle
├── SceneDelegate.swift   # Scene lifecycle
├── Main.storyboard       # Storyboard
└── Info.plist            # App configuration
```

### Key Patterns Used:
- **MVVM**: `ArticlesViewModel` manages state and business logic for `ArticlesViewController`.
- **Repository Pattern**: `ArticlesRepository` and `BookmarksRepository` abstract data persistence and network calls.
- **Dependency Injection**: ViewModels and Repositories are injected with their dependencies (e.g., `NewsAPIClient`).
- **Swift Concurrency**: Uses `async/await` for all network and I/O operations.

---

## ⚙️ Installation

### Prerequisites

- Xcode 15 or later
- macOS Sonoma or later
- An active [NewsAPI.org](https://newsapi.org) account (free tier is sufficient)

### Steps

1. **Clone the Repository**
   ```bash
   git clone https://github.com/yourusername/ReaderApp.git
   cd ReaderApp
   ```

2. **Open in Xcode**
   ```bash
   open ReaderApp.xcodeproj
   ```

3. **Configure API Key**
   - Open `NewsAPIClient.swift`.
   - Replace the placeholder API key with your own:
     ```swift
     private let apiKey = "YOUR_API_KEY_HERE"
     ```
   - *Note: The current key `"eade34f6438d453182bbb30cc4d8309a"` may be expired or rate-limited.*

4. **Build and Run**
   - Select your device or simulator.
   - Click the ▶️ button or press `Cmd + R`.

---

## 🖥️ Usage

Once the app is running:

1. **Main Feed (Top Headlines)**:
   - Articles are fetched from NewsAPI.org.
   - Pull down to refresh.
   - Tap the bookmark icon to save an article.
   - Tap anywhere on the cell to view the full article in a web view.

2. **Search**:
   - Tap the search bar at the top.
   - Type to filter articles by title.

3. **Bookmarks Tab**:
   - Navigate to the “Bookmarks” tab.
   - View all saved articles.
   - Tap any article to read it — even offline if cached.

4. **Offline Mode**:
   - Enable airplane mode or disconnect from Wi-Fi.
   - The app will automatically display previously cached articles and web content.

---

## 🤝 Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository.
2. Create a new branch (`git checkout -b feature/YourFeature`).
3. Commit your changes (`git commit -am 'Add some feature'`).
4. Push to the branch (`git push origin feature/YourFeature`).
5. Open a Pull Request.

---

## 📄 License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

- Built for the **Bookxpert Team** iOS Assignment.
- Uses [NewsAPI.org](https://newsapi.org) for free news data.
- Inspired by clean architecture patterns and modern Swift practices.
