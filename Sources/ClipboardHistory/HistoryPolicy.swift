import Foundation

struct Clip: Identifiable, Codable {
    var id = UUID()
    let date: Date
    let text: String?
    let image: Data?
}

struct HistoryPolicy {
    let limit: Int
    let retentionSeconds: TimeInterval?

    func retained(_ items: [Clip], now: Date = Date()) -> [Clip] {
        let valid = items.filter { item in
            guard let retentionSeconds else { return true }
            return now.timeIntervalSince(item.date) < retentionSeconds
        }
        return Array(valid.prefix(max(1, limit)))
    }
}
