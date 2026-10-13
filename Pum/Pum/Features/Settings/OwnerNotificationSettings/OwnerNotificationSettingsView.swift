// UI-IOS-6g · REQ-092 — 사장님 「알림 설정」. 탭 바 없음. 값은 서버 값, 바꾸면 onToggle(id, Bool).
import SwiftUI

struct OwnerNotificationSettingsView: View {
    let state: OwnerNotificationSettingsState
    var onBack: () -> Void = {}
    var onPickWorkplace: () -> Void = {}
    var onToggle: (String, Bool) -> Void = { _, _ in }

    init(state: OwnerNotificationSettingsState = .sample,
         onBack: @escaping () -> Void = {},
         onPickWorkplace: @escaping () -> Void = {},
         onToggle: @escaping (String, Bool) -> Void = { _, _ in }) {
        self.state = state
        self.onBack = onBack
        self.onPickWorkplace = onPickWorkplace
        self.onToggle = onToggle
    }

    var body: some View {
        VStack(spacing: 0) {
            PumNavHeader(title: OwnerNotificationSettingsState.screenTitle, onBack: onBack) {
                workplaceButton
            }
            .padding(.horizontal, PumTokens.Size.screenPad)
            ScrollView {
                VStack(alignment: .leading, spacing: PumTokens.Space.s20) {
                    ForEach(state.sections) { section in
                        VStack(alignment: .leading, spacing: PumTokens.Space.s8) {
                            PumSectionHeader(title: section.title)
                            PumCard {
                                ForEach(Array(section.rows.enumerated()), id: \.element.id) { index, row in
                                    toggleRow(row, isLast: index == section.rows.count - 1)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, PumTokens.Size.screenPad)
                .padding(.top, PumTokens.Space.s12)
                .padding(.bottom, PumTokens.Space.s24)
            }
        }
        .background(PumColor.bgApp)
    }

    private var workplaceButton: some View {
        Button(action: onPickWorkplace) {
            Text(state.workplaceName)
                .pumText(.callout, weight: .semibold)
                .foregroundStyle(PumColor.accent)
                .lineLimit(1)
                .frame(minWidth: PumTokens.Size.tapMin, minHeight: PumTokens.Size.tapMin)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(state.workplaceAccessibilityLabel))
        .accessibilityAddTraits(.isButton)
    }

    private func toggleRow(_ row: OwnerNotificationRow, isLast: Bool) -> some View {
        Toggle(isOn: Binding(get: { row.isOn }, set: { onToggle(row.id, $0) })) {
            VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                Text(row.title).pumText(.body, weight: .semibold).foregroundStyle(PumColor.textPrimary)
                if let subtitle = row.subtitle {
                    Text(subtitle).pumText(.caption, weight: .regular).foregroundStyle(PumColor.textSecondary)
                }
            }
        }
        .tint(PumColor.accent)
        .padding(.horizontal, PumTokens.Size.rowPadX)
        .padding(.vertical, PumTokens.Space.s10)
        .frame(minHeight: PumTokens.Size.tapMin)
        .overlay(alignment: .bottom) {
            if !isLast {
                Rectangle().fill(PumColor.borderHairline).frame(height: 1)
                    .padding(.horizontal, PumTokens.Size.rowPadX)
            }
        }
        .accessibilityLabel(Text(row.accessibilityText))
    }
}

#Preview("6g · 사장님 알림 설정") { OwnerNotificationSettingsView(state: .sample) }
