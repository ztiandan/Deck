import Foundation

/// Value-only recognizer: frames can be replayed without posting system input events.
struct GestureRecognizer {
    struct Contact {
        let id: Int32
        let x: Float
        let y: Float
    }

    private struct Finger {
        let origin: Contact
        let began: Double
        var position: Contact
        var travel: Float = 0

        mutating func update(_ contact: Contact) {
            position = contact
            travel = max(travel, max(abs(contact.x - origin.x), abs(contact.y - origin.y)))
        }
    }

    private struct TipTap {
        let finger: Int32
        let anchors: Set<Int32>
        let type: GestureType
    }

    private var fingers: [Int32: Finger] = [:]
    private var candidate: TipTap?
    private var sessionStart: Double?
    private var peakCount = 0
    private var simultaneous = true
    private var sessionTravel: Float = 0
    private var hasLifted = false
    private var lastTimestamp: Double?
    private var lastTrigger: Double = -.infinity
    private let movementLimit: Float = 0.045

    mutating func reset() { self = Self() }

    /// `contacts` contains touching fingers; `ending` preserves the final positions on lift.
    mutating func process(contacts: [Contact], ending: [Contact] = [], timestamp: Double) -> GestureType? {
        guard timestamp.isFinite, (contacts + ending).allSatisfy({ $0.x.isFinite && $0.y.isFinite }) else {
            reset()
            return nil
        }
        if let lastTimestamp, timestamp < lastTimestamp { reset() }
        lastTimestamp = timestamp
        let ids = Set(contacts.map(\.id))
        let previousIDs = Set(fingers.keys)
        let added = ids.subtracting(previousIDs)
        let lifted = previousIDs.subtracting(ids)
        if !lifted.isEmpty { hasLifted = true }
        if hasLifted && !added.isEmpty { simultaneous = false }

        if sessionStart == nil && !ids.isEmpty { sessionStart = timestamp }
        for contact in contacts + ending {
            if fingers[contact.id] != nil {
                fingers[contact.id]?.update(contact)
            }
        }
        for id in added {
            guard let contact = contacts.first(where: { $0.id == id }) else { continue }
            fingers[id] = Finger(origin: contact, began: timestamp, position: contact)
            if timestamp - (sessionStart ?? timestamp) > 0.10 { simultaneous = false }
        }
        peakCount = max(peakCount, ids.count)
        sessionTravel = max(sessionTravel, fingers.values.map(\.travel).max() ?? 0)

        var result: GestureType?
        if let tap = candidate {
            let allowed = tap.anchors.union([tap.finger])
            if !added.isEmpty || !tap.anchors.isSubset(of: ids) || !ids.isSubset(of: allowed) {
                candidate = nil
            } else if lifted == [tap.finger], let finger = fingers[tap.finger] {
                let duration = timestamp - finger.began
                if (0.025...0.38).contains(duration), finger.travel < movementLimit,
                   tap.anchors.allSatisfy({ (fingers[$0]?.travel ?? 1) < movementLimit }) {
                    result = tap.type
                }
                candidate = nil
            }
        }

        // A TipTap starts with stable anchors already on the surface. Simultaneous
        // landings and staggered releases of a 3/4-finger tap must never become TipTaps.
        if candidate == nil, added.count == 1, lifted.isEmpty,
           (1...2).contains(previousIDs.count), let id = added.first,
           let finger = fingers[id], previousIDs.allSatisfy({
               guard let anchor = fingers[$0] else { return false }
               return timestamp - anchor.began >= 0.10 && anchor.travel < movementLimit
           }) {
            let xs = previousIDs.compactMap { fingers[$0]?.position.x }
            let type: GestureType?
            if finger.position.x > (xs.max() ?? 1) + 0.015 {
                type = previousIDs.count == 1 ? .tipTapRight2F : .tipTapRight3F
            } else if finger.position.x < (xs.min() ?? 0) - 0.015 {
                type = previousIDs.count == 1 ? .tipTapLeft2F : .tipTapLeft3F
            } else {
                type = nil
            }
            if let type {
                candidate = TipTap(finger: id, anchors: previousIDs, type: type)
                simultaneous = false
            }
        }

        for id in lifted { fingers.removeValue(forKey: id) }
        if ids.isEmpty {
            if let start = sessionStart, simultaneous, sessionTravel < movementLimit,
               (0.025...0.42).contains(timestamp - start) {
                if peakCount == 4 { result = .fourFingerTap }
                if peakCount == 3 { result = .threeFingerTap }
            }
            candidate = nil
            sessionStart = nil
            peakCount = 0
            sessionTravel = 0
            simultaneous = true
            hasLifted = false
        }
        if let result, timestamp - lastTrigger >= 0.12 {
            lastTrigger = timestamp
            return result
        }
        return nil
    }
}
