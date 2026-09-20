import SwiftUI

public struct TimezoneView: View {
    @ObservedObject var tzManager = TimezoneManager.shared
    @ObservedObject var l10n = LocalizationManager.shared

    @State private var searchText: String = ""
    @State private var selectedRegion: TimezoneRegion = .all
    @State private var hoveredItemId: String? = nil

    private var baseTimeZone: TimeZone {
        TimeZone(identifier: tzManager.currentTimezone) ?? TimeZone.current
    }

    private var filteredTimezones: [TimezoneItem] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        return TimezoneDatabase.allTimezones.filter { item in
            // 地区筛选
            if selectedRegion == .major && !item.isMajorEconomy {
                return false
            }
            if selectedRegion != .all && selectedRegion != .major && item.region != selectedRegion {
                return false
            }

            // 搜索关键字匹配
            if query.isEmpty { return true }
            if item.identifier.lowercased().contains(query) { return true }
            if item.cityName.lowercased().contains(query) { return true }
            if item.countryName.lowercased().contains(query) { return true }
            if item.utcOffsetString().lowercased().contains(query) { return true }
            return false
        }
    }

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // 1. 顶部当前系统时区卡片看板
                currentSystemTimezoneCard

                // 错误或成功提示
                if let successMsg = tzManager.lastSuccessMessage {
                    statusMessageBanner(text: successMsg, isError: false)
                }
                if let errorMsg = tzManager.lastError {
                    statusMessageBanner(text: errorMsg, isError: true)
                }

                // 2. 主流经济体快速切换网格
                majorEconomiesSection

                // 3. 全球时区搜索与切换
                globalTimezonesSection
            }
            .padding(20)
        }
        .background(DeckTheme.canvasBackground)
    }

    // MARK: - 1. 当前生效时区卡片
    private var currentSystemTimezoneCard: some View {
        let currentItem = tzManager.currentItem

        return VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(currentItem.flag)
                            .font(.system(size: 24))
                        Text(currentItem.countryName.isEmpty ? currentItem.identifier : "\(currentItem.countryName) · \(currentItem.cityName)")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.primary)

                        // 当前生效状态指示
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 7, height: 7)
                            Text(loc(.tzActive))
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.green)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.green.opacity(0.12))
                        .cornerRadius(6)
                    }

                    Text(currentItem.identifier)
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundColor(.secondary)
                }

                Spacer()

                // 时钟与日期数字显示
                VStack(alignment: .trailing, spacing: 2) {
                    Text(tzManager.currentFormattedTime.isEmpty ? "--:--:--" : tzManager.currentFormattedTime)
                        .font(.system(size: 28, weight: .bold, design: .monospaced))
                        .foregroundColor(DeckTheme.accent)

                    HStack(spacing: 6) {
                        Text(tzManager.currentFormattedDate)
                            .font(.system(size: 11.5, weight: .medium))
                            .foregroundColor(.secondary)
                        Text(currentItem.utcOffsetString())
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(DeckTheme.accent.opacity(0.12))
                            .foregroundColor(DeckTheme.accent)
                            .cornerRadius(4)
                    }
                }
            }

            Divider()

            // 权限与免密提示栏
            HStack(spacing: 12) {
                Image(systemName: tzManager.isPasswordless ? "checkmark.shield.fill" : "lock.shield.fill")
                    .foregroundColor(tzManager.isPasswordless ? .green : .orange)
                    .font(.system(size: 15))

                VStack(alignment: .leading, spacing: 1) {
                    Text(loc(tzManager.isPasswordless ? .tzPasswordlessActive : .tzPasswordlessInactive))
                        .font(.system(size: 11.5, weight: .semibold))
                    Text(loc(.tzPasswordlessTip))
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }

                Spacer()

                if !tzManager.isPasswordless {
                    Button(loc(.tzEnablePasswordless)) {
                        tzManager.enablePasswordlessMode()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(DeckTheme.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(DeckTheme.borderColor, lineWidth: 1)
        )
        .shadow(color: DeckTheme.cardShadow, radius: 6, x: 0, y: 2)
    }

    // MARK: - 2. 主流经济体时区
    private var majorEconomiesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(loc(.tzMajorEconomies))
                    .font(.system(size: 13, weight: .bold))
                Text(loc(.tzMajorEconomiesDesc))
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }

            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 260, maximum: 380), spacing: 12)
            ], spacing: 12) {
                ForEach(TimezoneDatabase.majorEconomies) { item in
                    majorEconomyCard(item)
                }
            }
        }
    }

    private func majorEconomyCard(_ item: TimezoneItem) -> some View {
        let isCurrent = item.identifier == tzManager.currentTimezone
        let isHovered = hoveredItemId == item.identifier

        return VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center) {
                Text(item.flag)
                    .font(.system(size: 20))

                VStack(alignment: .leading, spacing: 1) {
                    Text(item.countryName)
                        .font(.system(size: 12.5, weight: .bold))
                        .foregroundColor(.primary)
                    Text(item.cityName)
                        .font(.system(size: 10.5))
                        .foregroundColor(.secondary)
                }

                Spacer()

                // 当前生效或切换按钮
                if isCurrent {
                    HStack(spacing: 3) {
                        Image(systemName: "checkmark.circle.fill")
                        Text(loc(.tzActive))
                    }
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.green)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(Color.green.opacity(0.12))
                    .cornerRadius(5)
                } else {
                    Button(loc(.tzSwitchTo)) {
                        tzManager.setTimezone(item.identifier)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.mini)
                    .disabled(tzManager.isSwitching)
                }
            }

            HStack(alignment: .bottom) {
                // 当地实时时间
                Text(item.formattedTime())
                    .font(.system(size: 20, weight: .bold, design: .monospaced))
                    .foregroundColor(isCurrent ? DeckTheme.accent : .primary)

                Spacer()

                HStack(spacing: 6) {
                    // 时差对比
                    if !isCurrent {
                        Text(item.relativeTimeDifference(comparedTo: baseTimeZone))
                            .font(.system(size: 9.5, weight: .medium))
                            .foregroundColor(.secondary)
                    }

                    // UTC 偏移
                    Text(item.utcOffsetString())
                        .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1.5)
                        .background(DeckTheme.borderColor)
                        .cornerRadius(3)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(isCurrent ? DeckTheme.accent.opacity(0.04) : (isHovered ? DeckTheme.hoverBackground : DeckTheme.cardBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(isCurrent ? DeckTheme.accent.opacity(0.4) : DeckTheme.borderColor, lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onHover { hovering in
            hoveredItemId = hovering ? item.identifier : nil
        }
        .onTapGesture {
            if !isCurrent {
                tzManager.setTimezone(item.identifier)
            }
        }
    }

    // MARK: - 3. 全球时区搜索与切换
    private var globalTimezonesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(loc(.tzGlobalTimezones))
                .font(.system(size: 13, weight: .bold))

            // 搜索栏与分类过滤器
            VStack(spacing: 8) {
                // 搜索输入框
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                        .font(.system(size: 12))

                    TextField(loc(.tzGlobalSearchPlaceholder), text: $searchText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 12))

                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                                .font(.system(size: 12))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(DeckTheme.cardBackground)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(DeckTheme.borderColor, lineWidth: 1)
                )

                // 分类筛选 Pills
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        regionFilterPill(title: loc(.tzFilterAll), region: .all)
                        regionFilterPill(title: loc(.tzFilterMajor), region: .major)
                        regionFilterPill(title: loc(.tzFilterAsia), region: .asia)
                        regionFilterPill(title: loc(.tzFilterAmericas), region: .americas)
                        regionFilterPill(title: loc(.tzFilterEurope), region: .europe)
                        regionFilterPill(title: loc(.tzFilterPacific), region: .pacific)
                        regionFilterPill(title: loc(.tzFilterAfrica), region: .africa)
                        regionFilterPill(title: loc(.tzFilterOther), region: .other)
                    }
                }
            }

            // 时区列表
            let results = filteredTimezones
            if results.isEmpty {
                HStack {
                    Spacer()
                    Text(loc(.tzCitySearchEmpty))
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .padding(.vertical, 30)
                    Spacer()
                }
            } else {
                VStack(spacing: 1) {
                    ForEach(results.prefix(150)) { item in
                        globalTimezoneRow(item)
                    }
                }
                .background(DeckTheme.cardBackground)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(DeckTheme.borderColor, lineWidth: 1)
                )
            }
        }
    }

    private func regionFilterPill(title: String, region: TimezoneRegion) -> some View {
        let isSelected = selectedRegion == region
        return Text(title)
            .font(.system(size: 11, weight: isSelected ? .semibold : .regular))
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isSelected ? DeckTheme.accent : DeckTheme.cardBackground)
            )
            .foregroundColor(isSelected ? .white : .primary)
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(isSelected ? DeckTheme.accent : DeckTheme.borderColor, lineWidth: 1)
            )
            .contentShape(Rectangle())
            .onTapGesture {
                selectedRegion = region
            }
    }

    private func globalTimezoneRow(_ item: TimezoneItem) -> some View {
        let isCurrent = item.identifier == tzManager.currentTimezone
        let isHovered = hoveredItemId == item.identifier

        return HStack(spacing: 12) {
            Text(item.flag)
                .font(.system(size: 16))
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 6) {
                    Text(item.cityName)
                        .font(.system(size: 12.5, weight: isCurrent ? .bold : .medium))
                        .foregroundColor(.primary)

                    if item.isMajorEconomy {
                        Text(item.countryName)
                            .font(.system(size: 9, weight: .semibold))
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(DeckTheme.accent.opacity(0.1))
                            .foregroundColor(DeckTheme.accent)
                            .cornerRadius(3)
                    }
                }

                Text(item.identifier)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.secondary)
            }

            Spacer()

            // 当前时间与偏移量
            HStack(spacing: 10) {
                Text(item.formattedTime())
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    .foregroundColor(isCurrent ? DeckTheme.accent : .primary)

                Text(item.utcOffsetString())
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(.secondary)
                    .frame(width: 55, alignment: .trailing)

                if isCurrent {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.system(size: 14))
                        .frame(width: 44)
                } else {
                    Button(loc(.tzSwitchTo)) {
                        tzManager.setTimezone(item.identifier)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.mini)
                    .frame(width: 44)
                    .disabled(tzManager.isSwitching)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(
            isCurrent
                ? DeckTheme.accent.opacity(0.05)
                : (isHovered ? DeckTheme.hoverBackground : Color.clear)
        )
        .contentShape(Rectangle())
        .onHover { hovering in
            hoveredItemId = hovering ? item.identifier : nil
        }
        .onTapGesture {
            if !isCurrent {
                tzManager.setTimezone(item.identifier)
            }
        }
    }

    private func statusMessageBanner(text: String, isError: Bool) -> some View {
        HStack(spacing: 8) {
            Image(systemName: isError ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                .foregroundColor(isError ? .red : .green)
            Text(text)
                .font(.system(size: 11.5, weight: .medium))
                .foregroundColor(isError ? .red : .green)
            Spacer()
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill((isError ? Color.red : Color.green).opacity(0.08))
        )
    }
}
