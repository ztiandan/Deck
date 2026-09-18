import XCTest
import AppKit
@testable import Deck

final class HostsPreviewTests: IsolatedDeckTestCase {
    private var hostsURL: URL { testDirectory.appendingPathComponent("hosts") }

    private func preview(_ menu: HostsPreviewMenu) throws -> HostsPreviewView {
        try XCTUnwrap(menu.items.first?.view as? HostsPreviewView)
    }

    func testEveryHoverOpeningReadsCurrentFileInsteadOfCachedProfileContent() throws {
        let first = "# actual system file\n127.0.0.1 first.test\n"
        let second = "::1 second.test\n192.0.2.1 third.test\n"
        try first.write(to: hostsURL, atomically: true, encoding: .utf8)
        let menu = HostsPreviewMenu(hostsURL: hostsURL)
        XCTAssertFalse(menu.items.isEmpty, "AppKit needs an item to open a submenu")
        menu.menuWillOpen(menu)
        XCTAssertEqual(try preview(menu).textView.string, first)
        try second.write(to: hostsURL, atomically: true, encoding: .utf8)
        menu.menuWillOpen(menu)
        XCTAssertEqual(try preview(menu).textView.string, second)
        XCTAssertEqual(menu.displayedContent, second)
        XCTAssertTrue(menu.items.last!.isEnabled)
    }

    func testFailedReadClearsPreviousContentAndDisablesCopy() throws {
        try "127.0.0.1 previous.test".write(to: hostsURL, atomically: true, encoding: .utf8)
        let menu = HostsPreviewMenu(hostsURL: hostsURL)
        menu.menuWillOpen(menu)
        try FileManager.default.removeItem(at: hostsURL)
        menu.menuWillOpen(menu)
        XCTAssertNil(menu.displayedContent)
        XCTAssertEqual(try preview(menu).textView.string, loc(.hostsReadFailed))
        XCTAssertFalse(menu.items.last!.isEnabled)
    }

    func testEmptyFileIsDistinguishedFromReadFailure() throws {
        try Data().write(to: hostsURL)
        let menu = HostsPreviewMenu(hostsURL: hostsURL)
        menu.menuWillOpen(menu)
        XCTAssertEqual(menu.displayedContent, "")
        XCTAssertEqual(try preview(menu).textView.string, loc(.hostsEmptyContent))
        XCTAssertTrue(menu.items.last!.isEnabled)
    }

    func testLongFileAndLongLinesAreScrollableWithoutLosingText() throws {
        let content = String(repeating: "192.0.2.1 " + String(repeating: "long-hostname.test ", count: 40) + "\n", count: 400)
        try content.write(to: hostsURL, atomically: true, encoding: .utf8)
        let menu = HostsPreviewMenu(hostsURL: hostsURL)
        menu.menuWillOpen(menu)
        let view = try preview(menu)
        XCTAssertEqual(view.textView.string, content)
        XCTAssertLessThanOrEqual(view.frame.height, 440)
        XCTAssertLessThanOrEqual(view.frame.width, 560)
        XCTAssertGreaterThan(view.textView.frame.height, view.scrollView.frame.height)
        XCTAssertGreaterThan(view.textView.frame.width, view.scrollView.frame.width)
        XCTAssertFalse(view.textView.isEditable)
    }

    func testNonUTF8ContentShowsReadFailure() throws {
        try Data([0xff, 0xfe, 0xff]).write(to: hostsURL)
        let menu = HostsPreviewMenu(hostsURL: hostsURL)
        menu.menuWillOpen(menu)
        XCTAssertNil(menu.displayedContent)
        XCTAssertEqual(try preview(menu).textView.string, loc(.hostsReadFailed))
    }
}
