import Foundation

struct ShortcutDefinition {
    let keyCode: UInt16
    let modifiers: [String]

    private static let keys: [String: UInt16] = [
        "a": 0, "s": 1, "d": 2, "f": 3, "h": 4, "g": 5, "z": 6, "x": 7,
        "c": 8, "v": 9, "b": 11, "q": 12, "w": 13, "e": 14, "r": 15,
        "y": 16, "t": 17, "1": 18, "2": 19, "3": 20, "4": 21, "6": 22,
        "5": 23, "=": 24, "9": 25, "7": 26, "-": 27, "8": 28, "0": 29,
        "]": 30, "o": 31, "u": 32, "[": 33, "i": 34, "p": 35, "return": 36,
        "l": 37, "j": 38, "'": 39, "k": 40, ";": 41, "\\": 42, ",": 43,
        "/": 44, "n": 45, "m": 46, ".": 47, "tab": 48, "space": 49,
        "`": 50, "delete": 51, "escape": 53, "left": 123, "right": 124,
        "down": 125, "up": 126
    ]

    static func parse(_ text: String) -> Self? {
        var value = text.lowercased()
        for (symbol, name) in [("⌘", "cmd"), ("⇧", "shift"), ("⌃", "ctrl"), ("^", "ctrl"),
                               ("⌥", "opt"), ("←", "left"), ("→", "right"), ("↑", "up"), ("↓", "down")] {
            value = value.replacingOccurrences(of: symbol, with: " \(name) ")
        }
        let parts = value.split(whereSeparator: { $0.isWhitespace || $0 == "+" }).map(String.init)
        var modifiers: [String] = []
        var keyCode: UInt16?
        for part in parts {
            let modifier: String?
            switch part {
            case "cmd", "command": modifier = "cmd"
            case "shift": modifier = "shift"
            case "ctrl", "control": modifier = "ctrl"
            case "opt", "option", "alt": modifier = "opt"
            default: modifier = nil
            }
            if let modifier {
                if !modifiers.contains(modifier) { modifiers.append(modifier) }
            } else if let code = keys[part], keyCode == nil {
                keyCode = code
            } else { return nil }
        }
        guard let keyCode else { return nil }
        return Self(keyCode: keyCode, modifiers: modifiers)
    }

    var display: String {
        let symbols = ["cmd": "⌘", "ctrl": "^", "shift": "⇧", "opt": "⌥"]
        let arrows: [UInt16: String] = [123: "←", 124: "→", 125: "↓", 126: "↑"]
        let key = arrows[keyCode] ?? Self.keys.first(where: { $0.value == keyCode })?.key.uppercased() ?? "?"
        return (modifiers.compactMap { symbols[$0] } + [key]).joined(separator: " ")
    }
}
