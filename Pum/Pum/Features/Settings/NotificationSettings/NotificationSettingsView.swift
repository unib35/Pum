// UI-IOS-4b · REQ-092 — 직원 「알림 설정」(내가 받을 알림). 탭 바 없음(하위 화면). 저장은 부모(onChange).
import SwiftUI

struct NotificationSettingsView: View {
    @State private var state: NotificationSettingsState
    var onBack: () -> Void = {}
    var onChange: (NotificationSettingsState) -> Void = { _ in }
    var onOpenQuietHours: () -> Void = {}

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(state: NotificationSettingsState = .sample,
         onBack: @escaping () -> Void = {},
         onChange: @escaping (NotificationSettingsState) -> Void = { _ in },
         onOpenQuietHours: @escaping () -> Void = {}) {
        _state = State(initialValue: state)
        self.onBack = onBack
        self.onChange = onChange
        self.onOpenQuietHours = onOpenQuietHours
    }

    var body: some View {
        VStack(spacing: 0) {
            PumNavHeader(title: NotificationSettingsState.screenTitle, onBack: onBack)
                .padding(.horizontal, PumTokens.Size.screenPad)
            ScrollView {
                VStack(alignment: .leading, spacing: PumTokens.Space.s14) { // 원문 블록 사이 14
                    section {
                        PumSectionHeader(title: NotificationSettingsState.workSection)
                    } card: {
                        leadRow
                        divider
                        lockedRow(NotificationSettingsState.offReminderTitle, detail: state.offReminderDetail,
                                  tag: state.offReminderPolicyTag, label: state.offReminderSubtitle, isOn: state.offReminderOn, soft: false)
                        divider
                        toggleRow(NotificationSettingsState.recordChangesTitle, NotificationSettingsState.recordChangesSubtitle, $state.recordChanges)
                    }
                    section {
                        alwaysHeader
                    } card: {
                        lockedRow(NotificationSettingsState.alwaysTitle, detail: NotificationSettingsState.alwaysSubtitle,
                                  tag: nil, label: NotificationSettingsState.alwaysSubtitle, isOn: true, soft: true)
                        divider
                        toggleRow(NotificationSettingsState.noticesTitle, NotificationSettingsState.noticesSubtitle, $state.notices)
                    }
                    section {
                        PumSectionHeader(title: NotificationSettingsState.paySection)
                    } card: {
                        toggleRow(NotificationSettingsState.payslipTitle, nil, $state.payslip)
                        divider
                        toggleRow(NotificationSettingsState.paydayTitle, NotificationSettingsState.paydaySubtitle, $state.payday)
                    }
                    section {
                        PumSectionHeader(title: NotificationSettingsState.quietSection)
                    } card: {
                        quietRow
                    }
                }
                .padding(.horizontal, PumTokens.Size.screenPad)
                .padding(.top, PumTokens.Space.s14) // 머리 줄과 첫 블록 사이 14
                .padding(.bottom, PumTokens.Space.s24)
            }
        }
        .background(PumColor.bgApp)
        .onChange(of: state) { _, new in onChange(new) }
    }

    // MARK: 틀

    private func section<H: View, C: View>(@ViewBuilder header: () -> H, @ViewBuilder card: () -> C) -> some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s8) { // 원문: 머리와 카드 사이 약 8
            header()
            PumCard { card() }
        }
        .padding(.top, PumTokens.Space.s4) // 원문 섹션 제목 위 4
    }

    private var divider: some View {
        Rectangle().fill(PumColor.borderHairline).frame(height: 1)
            .padding(.horizontal, PumTokens.Size.rowPadX)
    }

    private var alwaysHeader: some View {
        let lead = Text(NotificationSettingsState.alwaysSectionLead)
            .font(PumFont.font(size: PumTokens.FontToken.caption.size, weight: .bold, relativeTo: .caption))
        let tail = Text(NotificationSettingsState.alwaysSectionTail)
            .font(PumFont.font(size: PumTokens.FontToken.caption.size, weight: .medium, relativeTo: .caption))
        return Text("\(lead)\(tail)")
            .foregroundStyle(PumColor.textSecondary)
            .padding(.horizontal, PumTokens.Space.s4)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityAddTraits(.isHeader)
    }

    private func titleBlock(_ title: String, _ subtitle: Text?, titleColor: Color = PumColor.textPrimary) -> some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
            Text(title).pumText(.body, weight: .semibold).foregroundStyle(titleColor) // 15px 600
            if let subtitle {
                subtitle.pumText(.caption, weight: .regular) // 12px
            }
        }
    }

    // MARK: 출근 전 알림 + 알약

    private var leadRow: some View {
        let sub = Text(NotificationSettingsState.leadSubtitle).foregroundStyle(PumColor.textSecondary)
        return ViewThatFits(in: .horizontal) {
            HStack(spacing: PumTokens.Space.s12) { // 원문 gap 12
                titleBlock(NotificationSettingsState.leadTitle, sub)
                Spacer(minLength: PumTokens.Space.s8)
                pills
            }
            VStack(alignment: .leading, spacing: PumTokens.Space.s8) { // 좁거나 글자가 크면 알약은 제목 아래로
                titleBlock(NotificationSettingsState.leadTitle, sub)
                pills
            }
        }
        .padding(.horizontal, PumTokens.Size.rowPadX)
        .padding(.vertical, PumTokens.Size.rowPadY)
        .frame(minHeight: PumTokens.Size.tapMin)
    }

    /// 알약 3개 — 한 줄에 안 들어가면 세로로(가장 큰 글자)
    private var pills: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: PumTokens.Space.s6) { pillItems } // 원문 알약 사이 6
            VStack(alignment: .leading, spacing: PumTokens.Space.s4) { pillItems }
        }
        .animation(PumMotion.respecting(reduceMotion, PumMotion.fast), value: state.leadTime) // M2 · M22
    }

    private var pillItems: some View {
        let all = NotificationLeadTime.allCases
        return ForEach(Array(all.enumerated()), id: \.element) { i, c in
            PumChoicePill(title: c.title, isOn: state.leadTime == c, position: (i, all.count)) {
                state.leadTime = c
            }
        }
    }

    // MARK: 토글 행

    /// 제목 · 부제 + 토글. 1ad 자동 보내기 행과 같은 모양이라 공통 후보(PumToggleRow).
    private func toggleRow(_ title: String, _ subtitle: String?, _ isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            titleBlock(title, subtitle.map { Text($0).foregroundStyle(PumColor.textSecondary) })
        }
        .tint(PumColor.accent)
        .padding(.horizontal, PumTokens.Size.rowPadX)
        .padding(.vertical, PumTokens.Size.rowPadY) // 원문 13 → 12
        .frame(minHeight: PumTokens.Size.tapMin)
        .accessibilityLabel(Text(subtitle.map { "\(title), \($0)" } ?? title))
    }

    /// 직원이 끌 수 없는 토글 — 제목 회색, 토글 비활성. VoiceOver는 원문 부제를 읽고 흐림 특성(disabled)이 붙는다.
    private func lockedRow(_ title: String, detail: String, tag: String?, label: String, isOn: Bool, soft: Bool) -> some View {
        let sub: Text
        if let tag {
            let head = Text(detail + " ").foregroundStyle(PumColor.textSecondary)
            let tagText = Text("· \(tag)").foregroundStyle(PumColor.textTertiary)
            sub = Text("\(head)\(tagText)")
        } else {
            sub = Text(detail).foregroundStyle(PumColor.textTertiary)
        }
        return Toggle(isOn: .constant(isOn)) {
            titleBlock(title, sub, titleColor: soft ? PumColor.textTertiary : PumColor.textSecondary) // 근무 요청은 한 단계 더 연한 글자 토큰
        }
        .tint(PumColor.textDisabled) // 원문: 회색 트랙 — 비활성이라 켜진 채 고정
        .disabled(true)
        .padding(.horizontal, PumTokens.Size.rowPadX)
        .padding(.vertical, PumTokens.Size.rowPadY) // 원문 13 → 12
        .frame(minHeight: PumTokens.Size.tapMin)
        .accessibilityLabel(Text("\(title), \(label)"))
    }

    // MARK: 조용한 시간

    private var quietRow: some View {
        Button(action: onOpenQuietHours) {
            HStack(spacing: PumTokens.Space.s12) { // 원문 gap 12
                titleBlock(NotificationSettingsState.quietTitle, Text(state.quietHoursText).foregroundStyle(PumColor.textSecondary))
                    .frame(maxWidth: .infinity, alignment: .leading)
                HStack(spacing: PumTokens.Space.s6) { // 원문 「켜짐」–› 6
                    Text(state.quietStatusText).pumText(.callout, weight: .regular).foregroundStyle(PumColor.textSecondary)
                    Image(systemName: "chevron.right")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(PumColor.textDisabled)
                        .accessibilityHidden(true)
                }
            }
            .padding(.horizontal, PumTokens.Size.rowPadX)
            .padding(.vertical, PumTokens.Size.rowPadY) // 원문 13 → 12
            .frame(minHeight: PumTokens.Size.tapMin)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("\(NotificationSettingsState.quietTitle), \(state.quietStatusText), \(state.quietHoursText)"))
        .accessibilityAddTraits(.isButton)
    }
}

#Preview("4b · 알림 설정") { NotificationSettingsView(state: .sample) }
