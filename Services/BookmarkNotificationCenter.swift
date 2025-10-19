//
//  BookmarkNotificationCenter.swift
//  ReaderApp
//
//  Created by Assistant on 19/10/25.
//

import Foundation

extension Notification.Name {
    static let bookmarkDidChange = Notification.Name("bookmarkDidChange")
}

struct BookmarkNotification {
    let article: Article
    let isBookmarked: Bool
}

final class BookmarkNotificationCenter {
    static let shared = BookmarkNotificationCenter()
    
    private init() {}
    
    func postBookmarkChange(article: Article, isBookmarked: Bool) {
        let bookmarkInfo = BookmarkNotification(article: article, isBookmarked: isBookmarked)
        NotificationCenter.default.post(name: .bookmarkDidChange, object: bookmarkInfo)
    }
}
