//
//  WebContentCache.swift
//  ReaderApp
//
//  Created by Assistant on 19/10/25.
//

import Foundation
import WebKit

final class WebContentCache {
    static let shared = WebContentCache()
    
    private let cacheDirectory: URL
    private let fileManager = FileManager.default
    
    private init() {
        let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.cacheDirectory = documents.appendingPathComponent("WebContentCache")
        
        // Create cache directory if it doesn't exist
        if !fileManager.fileExists(atPath: cacheDirectory.path) {
            try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        }
    }
    
    func cacheWebContent(for article: Article, htmlContent: String) {
        let fileName = "\(article.id.hashValue).html"
        let fileURL = cacheDirectory.appendingPathComponent(fileName)
        
        do {
            try htmlContent.write(to: fileURL, atomically: true, encoding: .utf8)
            print("Successfully cached content for article: \(article.title ?? "Unknown") at \(fileURL.path)")
        } catch {
            print("Failed to cache web content: \(error)")
        }
    }
    
    func getCachedWebContent(for article: Article) -> String? {
        let fileName = "\(article.id.hashValue).html"
        let fileURL = cacheDirectory.appendingPathComponent(fileName)
        
        guard fileManager.fileExists(atPath: fileURL.path) else { 
            print("No cached file found for article: \(article.title ?? "Unknown")")
            return nil 
        }
        
        do {
            let content = try String(contentsOf: fileURL, encoding: .utf8)
            print("Successfully loaded cached content for article: \(article.title ?? "Unknown")")
            return content
        } catch {
            print("Failed to read cached web content: \(error)")
            return nil
        }
    }
    
    func hasCachedContent(for article: Article) -> Bool {
        let fileName = "\(article.id.hashValue).html"
        let fileURL = cacheDirectory.appendingPathComponent(fileName)
        let exists = fileManager.fileExists(atPath: fileURL.path)
        print("Cached content exists for article '\(article.title ?? "Unknown")': \(exists)")
        return exists
    }
    
    func clearCache() {
        do {
            let files = try fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil)
            for file in files {
                try fileManager.removeItem(at: file)
            }
        } catch {
            print("Failed to clear web content cache: \(error)")
        }
    }
}
