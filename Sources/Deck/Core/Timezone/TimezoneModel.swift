import Foundation

public enum TimezoneRegion: String, CaseIterable, Identifiable {
    case all = "all"
    case major = "major"
    case asia = "asia"
    case americas = "americas"
    case europe = "europe"
    case pacific = "pacific"
    case africa = "africa"
    case other = "other"

    public var id: String { rawValue }
}

public struct TimezoneItem: Identifiable, Hashable {
    public var id: String { identifier }
    public let identifier: String
    public let countryName: String
    public let cityName: String
    public let flag: String
    public let region: TimezoneRegion
    public let isMajorEconomy: Bool

    public var timeZone: TimeZone {
        TimeZone(identifier: identifier) ?? TimeZone.current
    }

    public init(
        identifier: String,
        countryName: String,
        cityName: String,
        flag: String,
        region: TimezoneRegion,
        isMajorEconomy: Bool = false
    ) {
        self.identifier = identifier
        self.countryName = countryName
        self.cityName = cityName
        self.flag = flag
        self.region = region
        self.isMajorEconomy = isMajorEconomy
    }

    /// Formats the current time in this timezone (e.g., "14:30")
    public func formattedTime(from date: Date = Date()) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = timeZone
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    /// Formats the current time with seconds in this timezone (e.g., "14:30:45")
    public func formattedTimeWithSeconds(from date: Date = Date()) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = timeZone
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: date)
    }

    /// Formats the current date in this timezone (e.g., "09月20日 周日" or "Sep 20, Sun")
    public func formattedDate(from date: Date = Date(), locale: Locale = .current) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = timeZone
        formatter.locale = locale
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    /// Formats the UTC offset (e.g., "UTC+8", "UTC-4", "UTC+5:30")
    public func utcOffsetString(at date: Date = Date()) -> String {
        let seconds = timeZone.secondsFromGMT(for: date)
        let totalMinutes = abs(seconds) / 60
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        let sign = seconds >= 0 ? "+" : "-"

        if minutes == 0 {
            return "UTC\(sign)\(hours)"
        } else {
            return String(format: "UTC%@%d:%02d", sign, hours, minutes)
        }
    }

    /// Relative time difference compared to another timezone (e.g., "同时间", "快 3 小时", "慢 12 小时")
    public func relativeTimeDifference(comparedTo base: TimeZone, at date: Date = Date()) -> String {
        let currentSeconds = base.secondsFromGMT(for: date)
        let targetSeconds = timeZone.secondsFromGMT(for: date)
        let diffMinutes = (targetSeconds - currentSeconds) / 60

        if diffMinutes == 0 {
            return LocalizationManager.shared.currentLanguage == .chinese ? "相同时间" : "Same time"
        }

        let diffHours = abs(diffMinutes) / 60
        let remainderMinutes = abs(diffMinutes) % 60
        let isAhead = diffMinutes > 0

        let prefix = LocalizationManager.shared.currentLanguage == .chinese
            ? (isAhead ? "快 " : "慢 ")
            : (isAhead ? "+" : "-")

        var result = prefix
        if diffHours > 0 {
            result += "\(diffHours)" + (LocalizationManager.shared.currentLanguage == .chinese ? " 小时" : "h")
        }
        if remainderMinutes > 0 {
            if diffHours > 0 { result += " " }
            result += "\(remainderMinutes)" + (LocalizationManager.shared.currentLanguage == .chinese ? " 分钟" : "m")
        }
        if LocalizationManager.shared.currentLanguage == .english {
            result += isAhead ? " ahead" : " behind"
        }
        return result
    }

    public static func == (lhs: TimezoneItem, rhs: TimezoneItem) -> Bool {
        lhs.identifier == rhs.identifier
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(identifier)
    }
}

public enum TimezoneDatabase {
    /// 预设全球主流经济体与关键金融中心
    public static let majorEconomies: [TimezoneItem] = [
        TimezoneItem(
            identifier: "Asia/Shanghai",
            countryName: "中国",
            cityName: "北京 / 上海",
            flag: "🇨🇳",
            region: .asia,
            isMajorEconomy: true
        ),
        TimezoneItem(
            identifier: "America/New_York",
            countryName: "美国 (美东)",
            cityName: "纽约 · 华尔街",
            flag: "🇺🇸",
            region: .americas,
            isMajorEconomy: true
        ),
        TimezoneItem(
            identifier: "America/Los_Angeles",
            countryName: "美国 (美西)",
            cityName: "旧金山 · 硅谷 · 洛杉矶",
            flag: "🇺🇸",
            region: .americas,
            isMajorEconomy: true
        ),
        TimezoneItem(
            identifier: "America/Chicago",
            countryName: "美国 (美中)",
            cityName: "芝加哥",
            flag: "🇺🇸",
            region: .americas,
            isMajorEconomy: true
        ),
        TimezoneItem(
            identifier: "Europe/London",
            countryName: "英国",
            cityName: "伦敦",
            flag: "🇬🇧",
            region: .europe,
            isMajorEconomy: true
        ),
        TimezoneItem(
            identifier: "Europe/Berlin",
            countryName: "德国 / 欧盟",
            cityName: "柏林 · 法兰克福",
            flag: "🇩🇪",
            region: .europe,
            isMajorEconomy: true
        ),
        TimezoneItem(
            identifier: "Europe/Paris",
            countryName: "法国 / 欧盟",
            cityName: "巴黎",
            flag: "🇫🇷",
            region: .europe,
            isMajorEconomy: true
        ),
        TimezoneItem(
            identifier: "Asia/Tokyo",
            countryName: "日本",
            cityName: "东京",
            flag: "🇯🇵",
            region: .asia,
            isMajorEconomy: true
        ),
        TimezoneItem(
            identifier: "Asia/Singapore",
            countryName: "新加坡",
            cityName: "新加坡",
            flag: "🇸🇬",
            region: .asia,
            isMajorEconomy: true
        ),
        TimezoneItem(
            identifier: "Asia/Hong_Kong",
            countryName: "中国香港",
            cityName: "香港",
            flag: "🇭🇰",
            region: .asia,
            isMajorEconomy: true
        ),
        TimezoneItem(
            identifier: "Australia/Sydney",
            countryName: "澳大利亚",
            cityName: "悉尼 · 墨尔本",
            flag: "🇦🇺",
            region: .pacific,
            isMajorEconomy: true
        ),
        TimezoneItem(
            identifier: "Asia/Kolkata",
            countryName: "印度",
            cityName: "新德里 · 孟买",
            flag: "🇮🇳",
            region: .asia,
            isMajorEconomy: true
        ),
        TimezoneItem(
            identifier: "Asia/Dubai",
            countryName: "阿联酋",
            cityName: "迪拜 · 阿布扎比",
            flag: "🇦🇪",
            region: .asia,
            isMajorEconomy: true
        ),
        TimezoneItem(
            identifier: "America/Toronto",
            countryName: "加拿大",
            cityName: "多伦多",
            flag: "🇨🇦",
            region: .americas,
            isMajorEconomy: true
        )
    ]

    /// 全球所有支持的 IANA 时区列表（去重且按大洲/字母排序）
    public static let allTimezones: [TimezoneItem] = {
        var majorDict = [String: TimezoneItem]()
        for item in majorEconomies {
            majorDict[item.identifier] = item
        }

        var result: [TimezoneItem] = []
        let identifiers = TimeZone.knownTimeZoneIdentifiers.sorted()

        for id in identifiers {
            if let existing = majorDict[id] {
                result.append(existing)
            } else {
                let parts = id.components(separatedBy: "/")
                let regionPrefix = parts.first ?? ""
                let cityPart = parts.dropFirst().joined(separator: " / ").replacingOccurrences(of: "_", with: " ")

                let region: TimezoneRegion
                let flag: String
                switch regionPrefix {
                case "Asia":
                    region = .asia
                    flag = "🌏"
                case "America", "US", "Canada", "Brazil", "Chile", "Mexico":
                    region = .americas
                    flag = "🌎"
                case "Europe":
                    region = .europe
                    flag = "🌍"
                case "Africa":
                    region = .africa
                    flag = "🌍"
                case "Pacific", "Australia", "NZ":
                    region = .pacific
                    flag = "🌏"
                default:
                    region = .other
                    flag = "🌐"
                }

                let displayName = cityPart.isEmpty ? id : cityPart
                let countryName = regionPrefix

                result.append(TimezoneItem(
                    identifier: id,
                    countryName: countryName,
                    cityName: displayName,
                    flag: flag,
                    region: region,
                    isMajorEconomy: false
                ))
            }
        }
        return result
    }()

    /// 根据当前时区标识符查找匹配项
    public static func find(by identifier: String) -> TimezoneItem? {
        if let major = majorEconomies.first(where: { $0.identifier == identifier }) {
            return major
        }
        return allTimezones.first(where: { $0.identifier == identifier })
    }
}
