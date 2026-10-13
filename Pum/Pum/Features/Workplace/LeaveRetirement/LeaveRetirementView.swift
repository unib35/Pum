// UI-IOS-10p · REQ-073 — 사업장 설정 › 휴가 · 퇴직 (하위 화면, 탭 바 없음).
// 상시 근로자 수 · 판정 · 대상 기준 문구 · 선택지 · 설명은 서버 값. 법정 대상을 끄는 설정은 없다 — 방식만 고른다.
// 저장은 처리 중에만 한 번(끝나면 풀림), 저장 버튼은 원문대로 늘 켜짐. 처리 중엔 입력 잠금.
// 서버가 저장값을 새로 주면 편집 중인 값도 서버 값으로 바꾼다(판단).
import SwiftUI

struct LeaveRetirementView: View {
    var state: LeaveRetirementState = .sample
    var onBack: () -> Void = {}
    /// 근거 보기
    var onShowBasis: () -> Void = {}
    /// 기준일 고르기
    var onPickBasisDate: () -> Void = {}
    /// 저장. 결과를 done(성공 여부)으로 알린다. 연결 전 기본값은 실패(done(false)).
    var onSave: (_ settings: LeaveRetirementSettings, _ done: @escaping (Bool) -> Void) -> Void = { _, done in done(false) }

    @State private var draft: LeaveRetirementDraft
    @State private var lock = LeaveRetirementLock()

    init(state: LeaveRetirementState = .sample,
         onBack: @escaping () -> Void = {}, onShowBasis: @escaping () -> Void = {},
         onPickBasisDate: @escaping () -> Void = {},
         onSave: @escaping (_ settings: LeaveRetirementSettings, _ done: @escaping (Bool) -> Void) -> Void = { _, done in done(false) }) {
        self.state = state
        self.onBack = onBack
        self.onShowBasis = onShowBasis
        self.onPickBasisDate = onPickBasisDate
        self.onSave = onSave
        _draft = State(initialValue: LeaveRetirementDraft(state.settings))
    }

    private var isSaving: Bool { lock.isSaving }

    var body: some View {
        VStack(spacing: 0) {
            PumNavHeader(title: LeaveRetirementState.headerTitle, onBack: isSaving ? nil : onBack)
                .padding(.top, PumTokens.Space.s8)
                .padding(.horizontal, PumTokens.Size.screenPad)
            ScrollView {
                VStack(alignment: .leading, spacing: PumTokens.Space.s12) {
                    headcountCard
                    section(state.leaveHeader) { leaveCard }
                    section(state.retirementHeader) { retirementCard }
                }
                .padding(.horizontal, PumTokens.Size.screenPad)
                .padding(.vertical, PumTokens.Space.s12)
            }
        }
        .background(PumColor.bgApp)
        .safeAreaInset(edge: .bottom, spacing: 0) { footer }
        // 서버가 저장값을 새로 주면 편집 중인 값도 서버 값으로
        .onChange(of: state.settings) { _, new in draft = LeaveRetirementDraft(new) }
    }

    private var footer: some View {
        VStack(spacing: PumTokens.Space.s10) {
            PumButton(title: LeaveRetirementState.saveTitle, kind: .dark, isLoading: isSaving, action: save)
            Text(LeaveRetirementState.notice).pumText(.caption).foregroundStyle(PumColor.textTertiary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, PumTokens.Size.screenPad)
        .padding(.vertical, PumTokens.Space.s12)
        .background(PumColor.bgApp)
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s6) {
            PumSectionHeader(title: title)
            content()
        }
    }

    private func divider(show: Bool) -> some View {
        Rectangle().fill(show ? PumColor.borderHairline : Color.clear).frame(height: 1)
    }

    // MARK: 상시 근로자

    private var headcountCard: some View {
        PumCard {
            HStack(spacing: PumTokens.Space.s10) {
                VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                    Text(state.headcountText).pumText(.callout, weight: .semibold).foregroundStyle(PumColor.textPrimary)
                    Text(state.judgmentText).pumText(.caption).foregroundStyle(PumColor.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityElement(children: .combine)
                Button(action: onShowBasis) {
                    Text(LeaveRetirementState.basisLink).pumText(.footnote, weight: .semibold).foregroundStyle(PumColor.accent)
                        .frame(minWidth: PumTokens.Size.tapMin, minHeight: PumTokens.Size.tapMin)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(isSaving)
            }
            .padding(.horizontal, PumTokens.Size.rowPadX)
            .padding(.vertical, PumTokens.Size.rowPadY)
        }
    }

    // MARK: 연차

    private var leaveCard: some View {
        PumCard {
            basisRow.overlay(alignment: .bottom) { divider(show: true) }
            toggleRow(LeaveRetirementState.hourlyTitle, state.hourlyDetail, $draft.hourlyUse, isLast: false)
            toggleRow(LeaveRetirementState.promotionTitle, state.promotionDetail, $draft.promotion, isLast: false)
            toggleRow(LeaveRetirementState.agreedTitle, state.agreedDetail, $draft.agreedLeave, isLast: true)
        }
    }

    /// 키–값 › 행(4c와 같은 모양). 큰 글자에서 한 줄에 안 들어가면 키 아래에 값.
    private var basisRow: some View {
        let title = LeaveRetirementState.basisTitle
        let value = state.settings.basisText
        return Button(action: onPickBasisDate) {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: PumTokens.Space.s12) {
                    keyText(title)
                    Spacer(minLength: PumTokens.Space.s8)
                    valueText(value)
                    chevron
                }
                HStack(alignment: .center, spacing: PumTokens.Space.s12) {
                    VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                        keyText(title)
                        valueText(value).multilineTextAlignment(.leading)
                    }
                    Spacer(minLength: PumTokens.Space.s8)
                    chevron
                }
            }
            .padding(.horizontal, PumTokens.Size.rowPadX)
            .padding(.vertical, PumTokens.Size.rowPadY)
            .frame(minHeight: PumTokens.Size.tapMin)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(isSaving)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("\(title), \(value)"))
        .accessibilityAddTraits(.isButton)
    }

    private func keyText(_ s: String) -> some View {
        Text(s).pumText(.callout).foregroundStyle(PumTokens.ColorToken.gray800)
    }

    private func valueText(_ s: String) -> some View {
        Text(s).pumText(.callout, weight: .semibold).foregroundStyle(PumColor.textPrimary)
    }

    private var chevron: some View {
        Image(systemName: "chevron.right").font(.footnote.weight(.semibold))
            .foregroundStyle(PumColor.textDisabled).accessibilityHidden(true)
    }

    /// 공통 후보: 제목 + 설명 두 줄 토글 행 (시스템 Toggle — 스위치로 읽힌다)
    private func toggleRow(_ title: String, _ detail: String, _ isOn: Binding<Bool>, isLast: Bool) -> some View {
        Toggle(isOn: isOn) {
            VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                Text(title).pumText(.callout, weight: .semibold).foregroundStyle(PumColor.textPrimary)
                Text(detail).pumText(.caption).foregroundStyle(PumColor.textSecondary)
            }
        }
        .tint(PumColor.accent)
        .disabled(isSaving)
        .padding(.horizontal, PumTokens.Size.rowPadX)
        .padding(.vertical, PumTokens.Size.rowPadY)
        .frame(minHeight: PumTokens.Size.tapMin)
        .overlay(alignment: .bottom) { divider(show: !isLast) }
    }

    // MARK: 퇴직급여

    private var retirementCard: some View {
        PumCard {
            ForEach(Array(state.retirementOptions.enumerated()), id: \.element.id) { index, option in
                retirementRow(option)
                    .overlay(alignment: .bottom) { divider(show: index < state.retirementOptions.count - 1) }
            }
        }
    }

    /// 공통 후보: 제목 + 설명 두 줄 라디오 행 (PumRadioRow는 한 줄)
    private func retirementRow(_ option: RetirementOption) -> some View {
        let isOn = draft.retirement == option.kind
        return Button {
            guard !isSaving else { return }
            draft.select(option.kind, in: state)
        } label: {
            HStack(spacing: PumTokens.Space.s12) {
                PumRadioMark(isOn: isOn)
                VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                    Text(option.title).pumText(.callout, weight: .semibold).foregroundStyle(PumColor.textPrimary)
                    Text(option.detail).pumText(.caption).foregroundStyle(PumColor.textSecondary)
                        .multilineTextAlignment(.leading)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, PumTokens.Size.rowPadX)
            .padding(.vertical, PumTokens.Size.rowPadY)
            .frame(minHeight: PumTokens.Size.tapMin)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(isSaving)
        .accessibilityElement(children: .ignore)
        // 「선택됨」이 라벨에 있어 isSelected 특성은 붙이지 않는다(두 번 읽힘)
        .accessibilityLabel(Text(state.optionAccessibility(option, isOn: isOn)))
        .accessibilityAddTraits(.isButton)
    }

    // MARK: 동작

    /// 처리 중에만 한 번 — 끝나면 풀린다
    private func save() {
        guard lock.begin() else { return }
        onSave(draft.settings(basisText: state.settings.basisText)) { _ in lock.finish() }
    }
}

#Preview("10p") { LeaveRetirementView(state: .sample) }
#Preview("10p · 큰 글자") { LeaveRetirementView(state: .sample).dynamicTypeSize(.xxxLarge) }
