// UI-IOS-4c · REQ-026 · REQ-093 — 사장님 「사업장 설정」: 정보 → 근태 → 급여 → 관리자 → 폐업. 탭 바 없음(하위 화면).
// 버튼 동작은 클로저로만. 폐업 · 내보내기 확인 흐름은 디자인에 없어 누름 클로저만 둔다.
import SwiftUI

struct WorkplaceSettingsView: View {
    @State private var state: WorkplaceSettingsState
    /// 없으면 뒤로 버튼을 숨긴다(MVP 설정 탭 첫 화면)
    var onBack: (() -> Void)?
    var onOpenInfo: () -> Void
    var onOpenCheckInMethod: () -> Void
    var onOpenOvertimePolicy: () -> Void
    var onOpenReminder: () -> Void
    var onOpenStoreQR: () -> Void
    var onOpenPayday: () -> Void
    var onOpenPremiumRules: () -> Void
    var onToggleReviewRequest: (Bool) -> Void
    var onOpenContractTemplate: () -> Void
    var onOpenAdmin: (String) -> Void
    var onAddAdmin: () -> Void
    var onCloseWorkplace: () -> Void
    var onOpenDeduction: () -> Void

    init(state: WorkplaceSettingsState = .sample,
         onBack: (() -> Void)? = {},
         onOpenInfo: @escaping () -> Void = {},
         onOpenCheckInMethod: @escaping () -> Void = {},
         onOpenOvertimePolicy: @escaping () -> Void = {},
         onOpenReminder: @escaping () -> Void = {},
         onOpenStoreQR: @escaping () -> Void = {},
         onOpenPayday: @escaping () -> Void = {},
         onOpenPremiumRules: @escaping () -> Void = {},
         onToggleReviewRequest: @escaping (Bool) -> Void = { _ in },
         onOpenContractTemplate: @escaping () -> Void = {},
         onOpenAdmin: @escaping (String) -> Void = { _ in },
         onAddAdmin: @escaping () -> Void = {},
         onCloseWorkplace: @escaping () -> Void = {},
         onOpenDeduction: @escaping () -> Void = {}) {
        _state = State(initialValue: state)
        self.onBack = onBack
        self.onOpenInfo = onOpenInfo
        self.onOpenCheckInMethod = onOpenCheckInMethod
        self.onOpenOvertimePolicy = onOpenOvertimePolicy
        self.onOpenReminder = onOpenReminder
        self.onOpenStoreQR = onOpenStoreQR
        self.onOpenPayday = onOpenPayday
        self.onOpenPremiumRules = onOpenPremiumRules
        self.onToggleReviewRequest = onToggleReviewRequest
        self.onOpenContractTemplate = onOpenContractTemplate
        self.onOpenAdmin = onOpenAdmin
        self.onAddAdmin = onAddAdmin
        self.onCloseWorkplace = onCloseWorkplace
        self.onOpenDeduction = onOpenDeduction
    }

    var body: some View {
        VStack(spacing: 0) {
            PumNavHeader(title: WorkplaceSettingsState.screenTitle, onBack: onBack)
                .padding(.horizontal, PumTokens.Size.screenPad)
            ScrollView {
                VStack(alignment: .leading, spacing: PumTokens.Space.s10) { // 원문: 카드 사이 약 10 (4a와 같은 방식)
                    infoCard
                    if state.isSolo {
                        section(WorkplaceSettingsState.paySection) {
                            SettingsRow(title: "기본 급여일", value: state.payday, action: onOpenPayday)
                            SettingsRow(title: "상시 5인 이상", value: state.fiveOrMoreText, action: onOpenPremiumRules)
                            SettingsRow(title: "공제", value: state.deductionText, isLast: true, action: onOpenDeduction)
                        }
                    } else {
                        fullSections
                    }
                }
                .padding(.horizontal, PumTokens.Size.screenPad)
                .padding(.top, PumTokens.Space.s4) // 원문 머리 줄(40) 아래 10 — 공통 머리 줄이 44라 4만
                .padding(.bottom, PumTokens.Space.s24)
            }
        }
        .background(PumColor.bgApp)
    }

    @ViewBuilder private var fullSections: some View {
                    section(WorkplaceSettingsState.attendanceSection) {
                        SettingsRow(title: "출퇴근 방식", value: state.checkInMethod, action: onOpenCheckInMethod)
                        SettingsRow(title: "연장·조기퇴근 정책", value: state.overtimePolicy, action: onOpenOvertimePolicy)
                        SettingsRow(title: "퇴근 리마인드 · 미확정 처리", value: state.reminderValue, action: onOpenReminder)
                        SettingsRow(title: "매장 QR 코드", value: state.storeQRAction, valueIsAccent: true, showsChevron: false,
                                    isLast: true, action: onOpenStoreQR)
                    }
                    section(WorkplaceSettingsState.paySection) {
                        SettingsRow(title: "기본 급여일 · 정산 기간", value: state.payday, action: onOpenPayday)
                        SettingsRow(title: "주휴수당 · 가산 규칙", value: state.premiumRules, action: onOpenPremiumRules)
                        reviewRequestRow
                        SettingsRow(title: "근로계약서 기본 양식", value: state.contractTemplate, isLast: true, action: onOpenContractTemplate)
                    }
                    section(WorkplaceSettingsState.adminSection) {
                        ForEach(state.admins) { admin in
                            AdminRow(admin: admin) { onOpenAdmin(admin.id) }
                        }
                        SettingsRow(title: WorkplaceSettingsState.addAdminTitle, titleIsAccent: true, showsChevron: false,
                                    isLast: true, action: onAddAdmin)
                    }
                    if state.isMeRepresentative { closeButton } // 대표만(REQ-093)
    }

    // MARK: 틀

    private func section<C: View>(_ title: String, @ViewBuilder card: () -> C) -> some View {
        VStack(spacing: PumTokens.Space.s4) { // 원문: 머리와 카드 사이 약 4–6 (4a와 같게)
            PumSectionHeader(title: title)
            PumCard { card() }
        }
        .padding(.top, PumTokens.Space.s2)
    }

    // MARK: 사업장 카드

    private var infoCard: some View {
        Button(action: onOpenInfo) {
            PumCard {
                HStack(spacing: PumTokens.Space.s14) { // 원문 14
                    StoreTile(initial: state.workplaceInitial, colorIndex: state.workplaceColorIndex)
                    VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                        Text(state.workplaceName).pumText(.headline, weight: .bold).foregroundStyle(PumColor.textPrimary) // 원문 18px 700 → 17
                        Text(state.infoLine).pumText(.footnote).foregroundStyle(PumColor.textSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    Image(systemName: "chevron.right")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(PumColor.textDisabled)
                        .accessibilityHidden(true)
                }
                .padding(.horizontal, PumTokens.Space.s18) // 원문 16 18
                .padding(.vertical, PumTokens.Space.s16)
                .frame(minHeight: PumTokens.Size.tapMin)
            }
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(state.infoAccessibilityText))
        .accessibilityHint(Text("사업장 정보를 열어요"))
    }

    // MARK: 확인 요청 토글

    private var reviewRequestRow: some View {
        Toggle(isOn: Binding(get: { state.reviewRequestOn },
                             set: { state.reviewRequestOn = $0; onToggleReviewRequest($0) })) {
            VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                Text("급여 확정 전 확인 요청").font(PumTextStyle.body.font).tracking(PumTokens.Tracking.body)
                    .foregroundStyle(PumColor.textPrimary)
                Text(state.reviewRequestSubtitle).pumText(.caption).foregroundStyle(PumColor.textSecondary)
            }
        }
        .tint(PumColor.accent)
        .padding(.horizontal, PumTokens.Size.rowPadX)
        .padding(.vertical, PumTokens.Size.rowPadY) // 원문 11 → 12
        .frame(minHeight: PumTokens.Size.tapMin)
        .accessibilityLabel(Text("급여 확정 전 확인 요청, \(state.reviewRequestSubtitle)"))
        .overlay(alignment: .bottom) { Rectangle().fill(PumColor.borderHairline).frame(height: 1) }
    }

    // MARK: 폐업

    private var closeButton: some View {
        Button(action: onCloseWorkplace) {
            Text(WorkplaceSettingsState.closeTitle)
                .pumText(.callout, weight: .medium) // 원문 14px 500
                .foregroundStyle(PumColor.statusDanger)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, minHeight: PumTokens.Size.tapMin)
                .contentShape(Rectangle())
                .padding(.vertical, -PumTokens.Space.s4) // 원문 높이 36 — 누름 영역은 44 유지
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 사업장 큰 네모

/// 공통 후보 — 큰 사업장 색 네모(C7 · 4a 목록 행은 36pt, 여기는 원문 약 52pt). 지금은 이 화면 전용.
private struct StoreTile: View {
    let initial: String
    let colorIndex: Int
    @ScaledMetric private var tile = PumTokens.Size.buttonH // 원문 약 52 → 54로 근사

    var body: some View {
        Text(initial)
            .pumText(.title3, weight: .bold) // 원문 20px 700
            .foregroundStyle(.white)
            .frame(width: tile, height: tile)
            .background(PumAvatarPalette.stores[colorIndex % PumAvatarPalette.stores.count],
                        in: RoundedRectangle(cornerRadius: tile * PumLayout.storeTileRadiusRatio, style: .continuous))
            .accessibilityHidden(true)
    }
}

// MARK: - 설정 행

/// 공통 후보 — 제목 + 오른쪽 값(회색 · 파랑) + ›. 값이 길면 제목 아래로 내린다. 4a MyInfoRow와 같은 모양(공통 PumRow는 값 색을 못 해 화면 전용).
private struct SettingsRow: View {
    let title: String
    var value: String?
    var valueIsAccent = false
    var titleIsAccent = false
    var showsChevron = true
    var isLast = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: PumTokens.Space.s12) {
                    titleText
                    Spacer(minLength: PumTokens.Space.s8)
                    valueText
                    chevron
                }
                HStack(alignment: .top, spacing: PumTokens.Space.s12) {
                    VStack(alignment: .leading, spacing: PumTokens.Space.s4) {
                        titleText
                        valueText
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    chevron
                }
            }
            .padding(.vertical, PumTokens.Size.rowPadY)
            .padding(.horizontal, PumTokens.Size.rowPadX)
            .frame(minHeight: PumTokens.Size.tapMin)
            .contentShape(Rectangle())
            .overlay(alignment: .bottom) {
                if !isLast { Rectangle().fill(PumColor.borderHairline).frame(height: 1) }
            }
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text([title, value].compactMap { $0 }.joined(separator: ", ")))
    }

    private var titleText: some View {
        Text(title)
            .font(PumTextStyle.body.font) // 원문 15px 500
            .tracking(PumTokens.Tracking.body)
            .foregroundStyle(titleIsAccent ? PumColor.accent : PumColor.textPrimary)
            .multilineTextAlignment(.leading)
    }

    @ViewBuilder private var valueText: some View {
        if let value {
            Text(value)
                .pumText(.footnote, weight: valueIsAccent ? .semibold : .regular)
                .foregroundStyle(valueIsAccent ? PumColor.accent : PumColor.textSecondary)
                .multilineTextAlignment(.trailing)
        }
    }

    @ViewBuilder private var chevron: some View {
        if showsChevron {
            Image(systemName: "chevron.right")
                .font(.body.weight(.semibold))
                .foregroundStyle(PumColor.textDisabled)
                .accessibilityHidden(true)
        }
    }
}

// MARK: - 관리자 행

/// 공통 후보 — 사람 행(아바타 + 이름 + 역할 배지). 아바타 글자를 값으로 받는다(PumAvatar는 글자를 이름에서 계산 — 충돌 #21).
private struct AdminRow: View {
    let admin: WorkplaceAdmin
    let action: () -> Void
    @ScaledMetric private var avatar = PumLayout.avatar

    var body: some View {
        Button(action: action) {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: PumTokens.Space.s12) {
                    avatarView
                    nameLine
                    Spacer(minLength: PumTokens.Space.s8)
                    PumBadge(text: admin.roleLabel, kind: .waiting)
                }
                HStack(alignment: .top, spacing: PumTokens.Space.s12) { // 글자가 크면 배지는 이름 아래, 같은 왼쪽 선
                    avatarView
                    VStack(alignment: .leading, spacing: PumTokens.Space.s4) {
                        nameLine
                        PumBadge(text: admin.roleLabel, kind: .waiting)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(.vertical, PumTokens.Space.s10)
            .padding(.horizontal, PumTokens.Size.rowPadX)
            .frame(minHeight: PumTokens.Size.tapMin)
            .contentShape(Rectangle())
            .overlay(alignment: .bottom) { Rectangle().fill(PumColor.borderHairline).frame(height: 1) }
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(admin.accessibilityText))
    }

    private var avatarView: some View {
        let pair = PumAvatarPalette.person(index: admin.colorIndex)
        return Text(admin.initial)
            .font(PumFont.font(size: avatar * 0.38, weight: .bold, relativeTo: .callout))
            .foregroundStyle(pair.foreground)
            .frame(width: avatar, height: avatar)
            .background(pair.background, in: Circle())
            .accessibilityHidden(true)
    }

    private var nameLine: some View {
        let name = Text(admin.name).font(PumTextStyle.body.font).foregroundStyle(PumColor.textPrimary)
        let me = Text(" \(WorkplaceSettingsState.meMark)")
            .font(PumFont.font(size: PumTokens.FontToken.caption.size, weight: .medium, relativeTo: .caption))
            .foregroundStyle(PumColor.textSecondary)
        return Group { if admin.isMe { Text("\(name)\(me)") } else { name } }
            .tracking(PumTokens.Tracking.body)
            .multilineTextAlignment(.leading)
    }
}

#Preview("4c · 사업장 설정") { WorkplaceSettingsView(state: .sample) }
