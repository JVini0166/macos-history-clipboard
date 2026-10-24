import XCTest
@testable import ClipboardHistory

final class HistoryPolicyTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 10_000)

    private func clip(age: TimeInterval) -> Clip {
        Clip(date: now.addingTimeInterval(-age), text: "Example", image: nil)
    }

    func testDisabledExpirationKeepsOldItemsAndAppliesLimit() {
        let items = [clip(age: 10), clip(age: 500), clip(age: 9000)]
        let result = HistoryPolicy(limit: 2, retentionSeconds: nil).retained(items, now: now)
        XCTAssertEqual(result.map(\.id), Array(items.prefix(2)).map(\.id))
        XCTAssertEqual(HistoryPolicy(limit: 10, retentionSeconds: nil).retained(items, now: now).count, 3)
    }

    func testExpirationRemovesItemsAtBoundaryAndOlder() {
        let items = [clip(age: 299), clip(age: 300), clip(age: 301)]
        let result = HistoryPolicy(limit: 100, retentionSeconds: 300).retained(items, now: now)
        XCTAssertEqual(result.map(\.id), [items[0].id])
    }

    func testExpirationBeforeLimitPreservesValidItems() {
        let old = clip(age: 500)
        let recent = clip(age: 10)
        let result = HistoryPolicy(limit: 1, retentionSeconds: 300).retained([old, recent], now: now)
        XCTAssertEqual(result.map(\.id), [recent.id])
    }

    @MainActor
    func testSettingsPersistAndKeepCleanupDisabledByDefault() throws {
        let name = "ClipboardHistoryTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: name))
        defer { defaults.removePersistentDomain(forName: name) }
        let settings = LaunchSettings(defaults: defaults)
        XCTAssertEqual(settings.itemLimit, 100)
        XCTAssertFalse(settings.autoClearEnabled)
        settings.itemLimit = 25
        settings.autoClearEnabled = true
        settings.retentionSeconds = 3600
        let restored = LaunchSettings(defaults: defaults)
        XCTAssertEqual(restored.itemLimit, 25)
        XCTAssertTrue(restored.autoClearEnabled)
        XCTAssertEqual(restored.retentionSeconds, 3600)
    }
}
