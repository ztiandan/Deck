import Foundation
import AppKit

private struct FingerInfo {
    var id: Int32
    var startX: Float
    var startY: Float
    var currentX: Float
    var currentY: Float
    var startTime: Double

    var maxDisplacement: Float {
        let dx = abs(currentX - startX)
        let dy = abs(currentY - startY)
        return max(dx, dy)
    }
}

public class TouchpadManager: ObservableObject {
    public static let shared = TouchpadManager()

    @Published public var isRunning: Bool = false
    @Published public var lastTriggeredGesture: GestureType?

    private var device: MTDeviceRef?
    private var activeFingers: [Int32: FingerInfo] = [:]
    private var lastTriggerTime: Double = 0
    private let cooldownDuration: Double = 0.16 // 优化为 160ms 防抖，支持连续流畅快捷操作

    // 多指轻点（三指/四指）会话追踪
    private var sessionActive: Bool = false
    private var sessionStartTime: Double = 0
    private var sessionPeakCount: Int = 0
    private var sessionMaxDisplacement: Float = 0

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

        // 1. 检查新进入与移动的手指
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

        // 更新多指会话状态（记录峰值接触指尖数与滑动位移）
        if !currentTouches.isEmpty {
            if !sessionActive {
                sessionActive = true
                sessionStartTime = now
                sessionPeakCount = currentTouches.count
                sessionMaxDisplacement = 0
            } else {
                sessionPeakCount = max(sessionPeakCount, currentTouches.count)
            }

            for (_, info) in activeFingers {
                sessionMaxDisplacement = max(sessionMaxDisplacement, info.maxDisplacement)
            }
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
            // A. TipTap 手势识别（手指有先后轻敲）
            for lifted in liftedFingers {
                let duration = now - lifted.startTime
                let tapDisplacement = lifted.maxDisplacement

                // 优化敲击判定：0.04s ~ 0.38s，位移不超过 0.08（防止滑动误判，允许指肚轻微自然形变）
                if duration >= 0.04 && duration <= 0.38 && tapDisplacement < 0.08 {
                    // 情况 1: 剩下 1 根手指固定按住 -> TipTap (2 Fingers)
                    if currentTouches.count == 1 {
                        let restingTouch = currentTouches.values.first!
                        if let restingInfo = activeFingers[restingTouch.fingerID] {
                            // 固定手指位移稳定（非滑动拖拽）且进入时间在敲击手指之前或相差不超过 60ms
                            if restingInfo.maxDisplacement < 0.08 && restingInfo.startTime <= lifted.startTime + 0.06 {
                                if lifted.startX > restingInfo.currentX + 0.015 {
                                    triggerGesture(.tipTapRight2F, timestamp: now)
                                    break
                                } else if lifted.startX < restingInfo.currentX - 0.015 {
                                    triggerGesture(.tipTapLeft2F, timestamp: now)
                                    break
                                }
                            }
                        }
                    }
                    // 情况 2: 剩下 2 根手指固定按住 -> TipTap (3 Fingers: 2 固定 1 敲)
                    else if currentTouches.count == 2 {
                        let restingTouches = Array(currentTouches.values)
                        let restingInfos = restingTouches.compactMap { activeFingers[$0.fingerID] }

                        if restingInfos.count == 2 && restingInfos.allSatisfy({ $0.maxDisplacement < 0.08 && $0.startTime <= lifted.startTime + 0.06 }) {
                            let restingXs = restingTouches.map { $0.normalizedVector.position.x }
                            let minX = restingXs.min() ?? 0
                            let maxX = restingXs.max() ?? 1

                            if lifted.startX > maxX + 0.015 {
                                triggerGesture(.tipTapRight3F, timestamp: now)
                                break
                            } else if lifted.startX < minX - 0.015 {
                                triggerGesture(.tipTapLeft3F, timestamp: now)
                                break
                            }
                        }
                    }
                }
            }

            // 情况 3: 剩下 1 根手指固定，2 根手指同时轻敲 -> TipTap (3 Fingers: 1 固定 2 敲)
            if currentTouches.count == 1 && liftedFingers.count == 2 {
                let restingTouch = currentTouches.values.first!
                if let restingInfo = activeFingers[restingTouch.fingerID], restingInfo.maxDisplacement < 0.08 {
                    let validTaps = liftedFingers.allSatisfy { (now - $0.startTime) <= 0.38 && $0.maxDisplacement < 0.08 }
                    if validTaps {
                        let liftedXs = liftedFingers.map { $0.startX }
                        let minLiftedX = liftedXs.min() ?? 0
                        let maxLiftedX = liftedXs.max() ?? 1

                        if minLiftedX > restingInfo.currentX + 0.015 {
                            triggerGesture(.tipTapRight3F, timestamp: now)
                        } else if maxLiftedX < restingInfo.currentX - 0.015 {
                            triggerGesture(.tipTapLeft3F, timestamp: now)
                        }
                    }
                }
            }

            // B. 多指同时轻点 (3指/4指轻点)
            // 在所有手指全部离开触控板时完成会话判定
            if currentTouches.isEmpty && sessionActive {
                let sessionDuration = now - sessionStartTime
                // 判定是否为纯轻拍：时长 0.05s ~ 0.42s，且过程中无明显滑行（displacement < 0.08，彻底避免与 Mission Control 4指滑动冲突）
                if sessionDuration >= 0.05 && sessionDuration <= 0.42 && sessionMaxDisplacement < 0.08 {
                    if sessionPeakCount == 4 {
                        triggerGesture(.fourFingerTap, timestamp: now)
                    } else if sessionPeakCount == 3 {
                        triggerGesture(.threeFingerTap, timestamp: now)
                    }
                }
            }
        }

        // 当所有手指离开，复位多指会话
        if currentTouches.isEmpty {
            sessionActive = false
            sessionPeakCount = 0
            sessionMaxDisplacement = 0
        }
    }

    /// 触发指定手势
    private func triggerGesture(_ gestureType: GestureType, timestamp: Double) {
        lastTriggerTime = timestamp

        // 触控板触觉反馈 (Taptic Engine 物理敲击感)
        if GestureStore.shared.isHapticFeedbackEnabled {
            NSHapticFeedbackManager.defaultPerformer.perform(
                .alignment,
                performanceTime: .now
            )
        }

        DispatchQueue.main.async {
            self.lastTriggeredGesture = gestureType
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                if self.lastTriggeredGesture == gestureType {
                    self.lastTriggeredGesture = nil
                }
            }
        }

        // 查找配置中匹配的手势并执行动作
        if let gesture = GestureStore.shared.gestures.first(where: { $0.gestureType == gestureType && $0.isEnabled }) {
            print("Triggering gesture: \(gestureType.rawValue) -> Action: \(gesture.shortcutDisplay)")
            ActionExecutor.shared.execute(gesture: gesture)
        }
    }
}
