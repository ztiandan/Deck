import Foundation
import AppKit

private struct FingerInfo {
    var id: Int32
    var startX: Float
    var startY: Float
    var currentX: Float
    var currentY: Float
    var startTime: Double
}

public class TouchpadManager: ObservableObject {
    public static let shared = TouchpadManager()

    @Published public var isRunning: Bool = false
    @Published public var lastTriggeredGesture: GestureType?

    private var device: MTDeviceRef?
    private var activeFingers: [Int32: FingerInfo] = [:]
    private var lastTriggerTime: Double = 0
    private let cooldownDuration: Double = 0.30 // 300ms 防抖冷却

    // 记录多指轻拍统计
    private var multiTouchHistoryCount: Int = 0
    private var multiTouchStartTime: Double = 0

    private init() {}

    public func start() {
        guard !isRunning else { return }
        guard MultitouchBridge.shared.isAvailable else {
            print("Multitouch framework is not available on this device")
            return
        }

        guard let createDev = MultitouchBridge.shared.MTDeviceCreateDefault,
              let dev = createDev() else {
            print("No Multitouch device created (external or non-trackpad)")
            return
        }

        self.device = dev

        guard let registerCallback = MultitouchBridge.shared.MTRegisterContactFrameCallback,
              let startDevice = MultitouchBridge.shared.MTDeviceStart else {
            return
        }

        // C 回调函数
        let callback: MTContactCallback = { device, rawTouches, numTouches, timestamp, frame in
            guard let rawTouches = rawTouches else { return 0 }
            let touches = rawTouches.assumingMemoryBound(to: MTTouch.self)
            TouchpadManager.shared.processFrame(touches: touches, count: Int(numTouches), timestamp: timestamp)
            return 0
        }

        registerCallback(dev, callback)
        startDevice(dev, 0)
        self.isRunning = true
        print("TouchpadManager successfully started listening to trackpad gestures")
    }

    public func stop() {
        guard isRunning, let dev = device else { return }
        if let stopDevice = MultitouchBridge.shared.MTDeviceStop {
            stopDevice(dev)
        }
        self.device = nil
        self.isRunning = false
    }

    /// 帧数据处理与手势识别
    fileprivate func processFrame(touches: UnsafeMutablePointer<MTTouch>, count: Int, timestamp: Double) {
        guard GestureStore.shared.isGlobalEnabled else { return }

        var currentTouches: [Int32: MTTouch] = [:]
        for i in 0..<count {
            let touch = touches[i]
            // state 3 (MakeTouch) 和 state 4 (Touching) 表示手指接触在触控板上
            if touch.state >= 3 && touch.state <= 4 {
                currentTouches[touch.fingerID] = touch
            }
        }

        let now = timestamp

        // 1. 检查新进入的手指
        for (id, touch) in currentTouches {
            let posX = touch.normalizedVector.position.x
            let posY = touch.normalizedVector.position.y

            if activeFingers[id] == nil {
                activeFingers[id] = FingerInfo(
                    id: id,
                    startX: posX,
                    startY: posY,
                    currentX: posX,
                    currentY: posY,
                    startTime: now
                )
            } else {
                activeFingers[id]?.currentX = posX
                activeFingers[id]?.currentY = posY
            }
        }

        // 记录多指轻敲历史峰值及起始时间
        if activeFingers.count > multiTouchHistoryCount {
            if multiTouchHistoryCount == 0 {
                multiTouchStartTime = now
            }
            multiTouchHistoryCount = activeFingers.count
        }

        // 2. 检查离开的手指（上帧在，本帧离开）
        var liftedFingers: [FingerInfo] = []
        for (id, info) in activeFingers {
            if currentTouches[id] == nil {
                liftedFingers.append(info)
                activeFingers.removeValue(forKey: id)
            }
        }

        // 3. 手势识别判定（检查冷却时间）
        if now - lastTriggerTime > cooldownDuration {
            // A. TipTap 手势识别
            for lifted in liftedFingers {
                let duration = now - lifted.startTime
                let moveDistanceX = abs(lifted.currentX - lifted.startX)
                let moveDistanceY = abs(lifted.currentY - lifted.startY)

                // 快速短促轻敲 (duration < 0.28s 且无明显滑行)
                if duration < 0.28 && moveDistanceX < 0.05 && moveDistanceY < 0.05 {
                    // 情况 1: 剩下 1 根手指固定按住 -> TipTap (2 Fingers Fix)
                    if currentTouches.count == 1 {
                        let restingTouch = currentTouches.values.first!
                        if let restingInfo = activeFingers[restingTouch.fingerID] {
                            let restingDuration = now - restingInfo.startTime
                            // 固定手指必须已经按住至少 80ms 且长于抬起手指
                            if restingDuration >= 0.08 && restingDuration > duration {
                                if lifted.startX > restingInfo.currentX {
                                    triggerGesture(.tipTapRight2F, timestamp: now)
                                    break
                                } else if lifted.startX < restingInfo.currentX {
                                    triggerGesture(.tipTapLeft2F, timestamp: now)
                                    break
                                }
                            }
                        }
                    }
                    // 情况 2: 剩下 2 根手指固定按住 -> TipTap (3 Fingers Fix)
                    else if currentTouches.count == 2 {
                        let restingTouches = Array(currentTouches.values)
                        let restingInfos = restingTouches.compactMap { activeFingers[$0.fingerID] }

                        if restingInfos.count == 2 && restingInfos.allSatisfy({ (now - $0.startTime) >= 0.08 && (now - $0.startTime) > duration }) {
                            let restingXs = restingTouches.map { $0.normalizedVector.position.x }
                            let minX = restingXs.min() ?? 0
                            let maxX = restingXs.max() ?? 1

                            if lifted.startX > maxX {
                                triggerGesture(.tipTapRight3F, timestamp: now)
                                break
                            } else if lifted.startX < minX {
                                triggerGesture(.tipTapLeft3F, timestamp: now)
                                break
                            }
                        }
                    }
                }
            }

            // B. 多指同时轻点 (3指/4指轻点)
            if currentTouches.isEmpty && multiTouchHistoryCount >= 3 {
                let tapDuration = now - multiTouchStartTime
                if tapDuration >= 0.03 && tapDuration < 0.28 {
                    if multiTouchHistoryCount == 4 {
                        triggerGesture(.fourFingerTap, timestamp: now)
                    } else if multiTouchHistoryCount == 3 {
                        triggerGesture(.threeFingerTap, timestamp: now)
                    }
                }
                multiTouchHistoryCount = 0
            }
        }

        // 当所有手指抬起，重置多指计数
        if currentTouches.isEmpty {
            multiTouchHistoryCount = 0
        }
    }

    /// 触发指定手势
    private func triggerGesture(_ gestureType: GestureType, timestamp: Double) {
        lastTriggerTime = timestamp

        DispatchQueue.main.async {
            self.lastTriggeredGesture = gestureType
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                if self.lastTriggeredGesture == gestureType {
                    self.lastTriggeredGesture = nil
                }
            }
        }

        // 查找配置中匹配的手势
        if let gesture = GestureStore.shared.gestures.first(where: { $0.gestureType == gestureType && $0.isEnabled }) {
            print("Triggering gesture: \(gestureType.rawValue) -> Action: \(gesture.shortcutDisplay)")
            ActionExecutor.shared.execute(gesture: gesture)
        }
    }
}
