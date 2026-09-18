import Foundation

public struct MTPoint {
    public var x: Float
    public var y: Float
    public init(x: Float = 0, y: Float = 0) {
        self.x = x
        self.y = y
    }
}

public struct MTTouch {
    public var frame: Int32
    public var timestamp: Double
    public var identifier: Int32
    public var state: Int32
    public var fingerCount: Int32
    public var size: Int32
    public var normalized: MTPoint
    public var zDensity: Float
}

public typealias MTDeviceRef = UnsafeMutableRawPointer

public typealias MTContactCallback = @convention(c) (
    MTDeviceRef?,
    UnsafeMutableRawPointer?,
    Int32,
    Double,
    Int32
) -> Int32

public class MultitouchBridge {
    public static let shared = MultitouchBridge()

    private var handle: UnsafeMutableRawPointer?

    public var MTDeviceCreateDefault: (@convention(c) () -> MTDeviceRef?)?
    public var MTRegisterContactFrameCallback: (@convention(c) (MTDeviceRef?, MTContactCallback?) -> Void)?
    public var MTDeviceStart: (@convention(c) (MTDeviceRef?, Int32) -> Void)?
    public var MTDeviceStop: (@convention(c) (MTDeviceRef?) -> Void)?

    private init() {
        loadFramework()
    }

    private func loadFramework() {
        guard let lib = dlopen("/System/Library/PrivateFrameworks/MultitouchSupport.framework/MultitouchSupport", RTLD_NOW) else {
            print("Failed to load MultitouchSupport.framework")
            return
        }
        self.handle = lib

        if let sym = dlsym(lib, "MTDeviceCreateDefault") {
            self.MTDeviceCreateDefault = unsafeBitCast(sym, to: (@convention(c) () -> MTDeviceRef?).self)
        }
        if let sym = dlsym(lib, "MTRegisterContactFrameCallback") {
            self.MTRegisterContactFrameCallback = unsafeBitCast(sym, to: (@convention(c) (MTDeviceRef?, MTContactCallback?) -> Void).self)
        }
        if let sym = dlsym(lib, "MTDeviceStart") {
            self.MTDeviceStart = unsafeBitCast(sym, to: (@convention(c) (MTDeviceRef?, Int32) -> Void).self)
        }
        if let sym = dlsym(lib, "MTDeviceStop") {
            self.MTDeviceStop = unsafeBitCast(sym, to: (@convention(c) (MTDeviceRef?) -> Void).self)
        }
    }

    public var isAvailable: Bool {
        return MTDeviceCreateDefault != nil && MTRegisterContactFrameCallback != nil && MTDeviceStart != nil
    }
}
