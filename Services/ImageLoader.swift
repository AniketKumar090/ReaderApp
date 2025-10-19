import UIKit

final class ImageLoader {
    static let shared = ImageLoader()
    
    private let memoryCache = NSCache<NSString, UIImage>()
    private let diskCacheDirectory: URL
    private let fileManager = FileManager.default
    
    private init() {
        let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.diskCacheDirectory = documents.appendingPathComponent("ImageCache")
        
        // Create cache directory if it doesn't exist
        if !fileManager.fileExists(atPath: diskCacheDirectory.path) {
            try? fileManager.createDirectory(at: diskCacheDirectory, withIntermediateDirectories: true)
        }
        
        // Configure memory cache
        memoryCache.countLimit = 100 // Maximum 100 images in memory
        memoryCache.totalCostLimit = 50 * 1024 * 1024 // 50 MB
    }

    func loadImage(from urlString: String?, completion: @escaping (UIImage?) -> Void) {
        guard let urlString = urlString, let url = URL(string: urlString) else {
            completion(nil)
            return
        }
        
        let cacheKey = urlString as NSString
        
        // Check memory cache first
        if let cachedImage = memoryCache.object(forKey: cacheKey) {
            completion(cachedImage)
            return
        }
        
        // Check disk cache
        if let diskImage = loadImageFromDisk(urlString: urlString) {
            memoryCache.setObject(diskImage, forKey: cacheKey)
            completion(diskImage)
            return
        }
        
        // Download from network
        URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            guard let self = self,
                  let data = data,
                  error == nil,
                  let image = UIImage(data: data) else {
                DispatchQueue.main.async { completion(nil) }
                return
            }
            
            // Cache in memory
            self.memoryCache.setObject(image, forKey: cacheKey)
            
            // Cache on disk
            self.saveImageToDisk(image: image, urlString: urlString)
            
            DispatchQueue.main.async { completion(image) }
        }.resume()
    }
    
    private func loadImageFromDisk(urlString: String) -> UIImage? {
        let fileName = sanitizeFileName(urlString)
        let fileURL = diskCacheDirectory.appendingPathComponent(fileName)
        
        guard fileManager.fileExists(atPath: fileURL.path),
              let data = try? Data(contentsOf: fileURL),
              let image = UIImage(data: data) else {
            return nil
        }
        
        return image
    }
    
    private func saveImageToDisk(image: UIImage, urlString: String) {
        let fileName = sanitizeFileName(urlString)
        let fileURL = diskCacheDirectory.appendingPathComponent(fileName)
        
        guard let data = image.jpegData(compressionQuality: 0.8) else { return }
        
        try? data.write(to: fileURL, options: .atomic)
    }
    
    private func sanitizeFileName(_ string: String) -> String {
        let hash = string.hash
        return "\(abs(hash)).jpg"
    }
    
    func clearCache() {
        // Clear memory cache
        memoryCache.removeAllObjects()
        
        // Clear disk cache
        do {
            let files = try fileManager.contentsOfDirectory(at: diskCacheDirectory, includingPropertiesForKeys: nil)
            for file in files {
                try fileManager.removeItem(at: file)
            }
        } catch {
            print("Failed to clear image cache: \(error)")
        }
    }
}
