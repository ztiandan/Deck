import XCTest
@testable import Deck

final class GestureRecognizerTests: XCTestCase {
    typealias Contact = GestureRecognizer.Contact
    private func finger(_ id: Int32, _ x: Float, _ y: Float = 0.5) -> Contact {
        Contact(id: id, x: x, y: y)
    }

    func testAllFourTipTapsAndRepeatedTapWithAnchorsStillDown() {
        let cases: [(GestureType, [Contact], Contact)] = [
            (.tipTapRight2F, [finger(1, 0.3)], finger(2, 0.7)),
            (.tipTapLeft2F, [finger(1, 0.7)], finger(2, 0.3)),
            (.tipTapRight3F, [finger(1, 0.3), finger(2, 0.5)], finger(3, 0.7)),
            (.tipTapLeft3F, [finger(1, 0.5), finger(2, 0.7)], finger(3, 0.3))
        ]
        for (type, anchors, tap) in cases {
            var recognizer = GestureRecognizer()
            XCTAssertNil(recognizer.process(contacts: anchors, timestamp: 0))
            XCTAssertNil(recognizer.process(contacts: anchors + [tap], timestamp: 0.2))
            XCTAssertEqual(recognizer.process(contacts: anchors, timestamp: 0.3), type)
            XCTAssertNil(recognizer.process(contacts: anchors, timestamp: 0.32))
            XCTAssertNil(recognizer.process(contacts: anchors + [tap], timestamp: 0.5))
            XCTAssertEqual(recognizer.process(contacts: anchors, timestamp: 0.6), type)
            XCTAssertNil(recognizer.process(contacts: [], timestamp: 0.7))
        }
    }

    func testSimultaneousTapsWithEveryReleaseOrderNeverBecomeTipTaps() {
        func permutations(_ ids: [Int32]) -> [[Int32]] {
            if ids.isEmpty { return [[]] }
            return ids.flatMap { id in permutations(ids.filter { $0 != id }).map { [id] + $0 } }
        }
        for count in [3, 4] {
            let fingers = (1...count).map { finger(Int32($0), Float($0) * 0.18) }
            for order in permutations(fingers.map(\.id)) {
                var recognizer = GestureRecognizer()
                // Natural contact onset has a small delay between fingers.
                for index in fingers.indices {
                    XCTAssertNil(recognizer.process(contacts: Array(fingers.prefix(index + 1)), timestamp: Double(index) * 0.02))
                }
                var remaining = fingers
                for (index, id) in order.enumerated() {
                    remaining.removeAll { $0.id == id }
                    let result = recognizer.process(contacts: remaining, timestamp: 0.16 + Double(index) * 0.025)
                    XCTAssertEqual(result, remaining.isEmpty ? (count == 4 ? .fourFingerTap : .threeFingerTap) : nil)
                }
                XCTAssertNil(recognizer.process(contacts: [], timestamp: 0.3))
            }
        }
    }

    func testFourFingerTapEndsWithEmptyFrame() {
        var recognizer = GestureRecognizer()
        let contacts = (1...4).map { finger(Int32($0), Float($0) * 0.18) }
        XCTAssertNil(recognizer.process(contacts: contacts, timestamp: 0))
        XCTAssertEqual(recognizer.process(contacts: [], timestamp: 0.12), .fourFingerTap)
    }

    func testSwipeOutAndBackIsNotTap() {
        var recognizer = GestureRecognizer()
        let start = (1...4).map { finger(Int32($0), Float($0) * 0.18) }
        let moved = start.map { finger($0.id, $0.x, 0.7) }
        XCTAssertNil(recognizer.process(contacts: start, timestamp: 0))
        XCTAssertNil(recognizer.process(contacts: moved, timestamp: 0.1))
        XCTAssertNil(recognizer.process(contacts: start, timestamp: 0.2))
        XCTAssertNil(recognizer.process(contacts: [], timestamp: 0.3))
    }

    func testFinalLiftPositionRejectsSwipe() {
        var recognizer = GestureRecognizer()
        let start = (1...4).map { finger(Int32($0), Float($0) * 0.18) }
        XCTAssertNil(recognizer.process(contacts: start, timestamp: 0))
        XCTAssertNil(recognizer.process(contacts: [], ending: start.map { finger($0.id, $0.x, 0.7) }, timestamp: 0.1))
    }

    func testTipTapRejectsMovingFingerMovingAnchorAndLongPress() {
        for mode in 0...2 {
            var recognizer = GestureRecognizer()
            let anchor = finger(1, 0.3), tap = finger(2, 0.7)
            XCTAssertNil(recognizer.process(contacts: [anchor], timestamp: 0))
            XCTAssertNil(recognizer.process(contacts: [anchor, tap], timestamp: 0.2))
            if mode < 2 {
                let moved = mode == 0 ? [anchor, finger(2, 0.85)] : [finger(1, 0.4), tap]
                XCTAssertNil(recognizer.process(contacts: moved, timestamp: 0.25))
                XCTAssertNil(recognizer.process(contacts: [anchor, tap], timestamp: 0.28))
            }
            XCTAssertNil(recognizer.process(contacts: [anchor], timestamp: mode == 2 ? 0.7 : 0.3))
        }
    }

    func testAdditionalFingerOrAnchorLiftCancelsTipTap() {
        var recognizer = GestureRecognizer()
        let anchor = finger(1, 0.3), tap = finger(2, 0.7)
        XCTAssertNil(recognizer.process(contacts: [anchor], timestamp: 0))
        XCTAssertNil(recognizer.process(contacts: [anchor, tap], timestamp: 0.2))
        XCTAssertNil(recognizer.process(contacts: [anchor, tap, finger(3, 0.5)], timestamp: 0.23))
        XCTAssertNil(recognizer.process(contacts: [anchor], timestamp: 0.3))
        XCTAssertNil(recognizer.process(contacts: [], timestamp: 0.35))
        XCTAssertNil(recognizer.process(contacts: [anchor], timestamp: 1))
        XCTAssertNil(recognizer.process(contacts: [anchor, tap], timestamp: 1.2))
        XCTAssertNil(recognizer.process(contacts: [], timestamp: 1.3))
    }

    func testResetDiscardsIncompleteGesture() {
        var recognizer = GestureRecognizer()
        XCTAssertNil(recognizer.process(contacts: [finger(1, 0.3)], timestamp: 0))
        XCTAssertNil(recognizer.process(contacts: [finger(1, 0.3), finger(2, 0.7)], timestamp: 0.2))
        recognizer.reset()
        XCTAssertNil(recognizer.process(contacts: [finger(1, 0.3)], timestamp: 0.3))
        XCTAssertNil(recognizer.process(contacts: [], timestamp: 0.35))
    }

    func testTwoFingerTapMiddleFingerTapAndFiveFingerTapDoNothing() {
        for count in [2, 5] {
            var recognizer = GestureRecognizer()
            let contacts = (1...count).map { finger(Int32($0), Float($0) * 0.15) }
            XCTAssertNil(recognizer.process(contacts: contacts, timestamp: 0))
            XCTAssertNil(recognizer.process(contacts: Array(contacts.prefix(1)), timestamp: 0.1))
            XCTAssertNil(recognizer.process(contacts: [], timestamp: 0.2))
        }
        var recognizer = GestureRecognizer()
        let anchors = [finger(1, 0.3), finger(2, 0.7)]
        XCTAssertNil(recognizer.process(contacts: anchors, timestamp: 0))
        XCTAssertNil(recognizer.process(contacts: anchors + [finger(3, 0.5)], timestamp: 0.2))
        XCTAssertNil(recognizer.process(contacts: anchors, timestamp: 0.3))
        XCTAssertNil(recognizer.process(contacts: [], timestamp: 0.35))
    }

    func testLiftAndRecontactIsNotSimultaneousTap() {
        var recognizer = GestureRecognizer()
        let contacts = [finger(1, 0.2), finger(2, 0.4), finger(3, 0.6)]
        XCTAssertNil(recognizer.process(contacts: contacts, timestamp: 0))
        XCTAssertNil(recognizer.process(contacts: Array(contacts.prefix(2)), timestamp: 0.04))
        XCTAssertNil(recognizer.process(contacts: contacts, timestamp: 0.07))
        XCTAssertNil(recognizer.process(contacts: [], timestamp: 0.12))
    }

    func testMalformedFrameResetsPendingGesture() {
        for timestamp in [Double.nan, Double.infinity] {
            var recognizer = GestureRecognizer()
            let contacts = [finger(1, 0.2), finger(2, 0.4), finger(3, 0.6)]
            XCTAssertNil(recognizer.process(contacts: contacts, timestamp: 0))
            XCTAssertNil(recognizer.process(contacts: contacts, timestamp: timestamp))
            XCTAssertNil(recognizer.process(contacts: [], timestamp: 0.2))
        }
        var recognizer = GestureRecognizer()
        XCTAssertNil(recognizer.process(contacts: [finger(1, .nan)], timestamp: 0))
        XCTAssertNil(recognizer.process(contacts: [], timestamp: 0.1))
    }
}
