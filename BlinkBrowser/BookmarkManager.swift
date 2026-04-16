import Foundation

class BookmarkManager {
    private let key = "blink_bookmarks"
    
    struct Bookmark: Codable {
        let id: String
        let url: String
        let title: String
        let createdAt: Date
    }
    
    var bookmarks: [Bookmark] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let items = try? JSONDecoder().decode([Bookmark].self, from: data) else { return [] }
        return items
    }
    
    func addBookmark(url: String, title: String) {
        var items = bookmarks
        guard !items.contains(where: { $0.url == url }) else { return }
        items.insert(Bookmark(id: UUID().uuidString, url: url, title: title, createdAt: Date()), at: 0)
        save(items)
    }
    
    func removeBookmark(url: String) {
        var items = bookmarks
        items.removeAll { $0.url == url }
        save(items)
    }
    
    func isBookmarked(url: String) -> Bool {
        bookmarks.contains { $0.url == url }
    }
    
    private func save(_ items: [Bookmark]) {
        if let data = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}

class HistoryManager {
    private let key = "blink_history"
    
    struct Entry: Codable {
        let id: String
        let url: String
        let title: String
        let visitedAt: Date
    }
    
    var entries: [Entry] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let items = try? JSONDecoder().decode([Entry].self, from: data) else { return [] }
        return items
    }
    
    func addEntry(url: String, title: String) {
        var items = entries
        items.insert(Entry(id: UUID().uuidString, url: url, title: title, visitedAt: Date()), at: 0)
        if items.count > 500 { items = Array(items.prefix(500)) }
        save(items)
    }
    
    func clear() {
        UserDefaults.standard.removeObject(forKey: key)
    }
    
    private func save(_ items: [Entry]) {
        if let data = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}
