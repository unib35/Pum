// UI-IOS-10g · REQ-075 — 정정 재계산 (하위 화면, 탭 바 없음)
// 금액 · 내역 · 지급 시기 선택지는 서버 값 그대로. 「정정 확정」은 되돌릴 수 없어 성공이면 잠근 채 둔다.
import SwiftUI

struct CorrectionRecalcView: View {
    @State private var state: CorrectionRecalcState
    var onBack: () -> Void
    var onChoiceChanged: (String) -> Void
    /// 성공이면 done(true) — 잠긴 채 부모가 넘어간다. 실패면 done(false) — 다시 누를 수 있다.
    var onConfirm: (String, @escaping (Bool) -> Void) -> Void

    init(state: CorrectionRecalcState = .sample,
         onBack: @escaping () -> Void = {},
         onChoiceChanged: @escaping (String) -> Void = { _ in },
         onConfirm: @escaping (String, @escaping (Bool) -> Void) -> Void = { _, done in done(false) }) {
        _state = State(initialValue: state)
        self.onBack = onBack
        self.onChoiceChanged = onChoiceChanged
        self.onConfirm = onConfirm
    }

    var body: some View {
        VStack(spacing: 0) {
            PumNavHeader(title: CorrectionRecalcState.title, onBack: onBack)
                .padding(.horizontal, PumTokens.Size.screenPad)
                .disabled(state.isSending)
            ScrollView {
                VStack(alignment: .leading, spacing: PumTokens.Space.s12) {
                    summaryCard
                    section(CorrectionRecalcState.changesSection) { changesCard }
                    section(CorrectionRecalcState.payoutSection) { payoutCard }
                }
                .padding(.horizontal, PumTokens.Size.screenPad)
                .padding(.vertical, PumTokens.Space.s12)
            }
        }
        .background(PumColor.bgApp)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            VStack(spacing: PumTokens.Space.s10) {
                PumButton(title: CorrectionRecalcState.confirmTitle, kind: .primary, isLoading: state.isSending, action: confirm)
                    .disabled(!state.canConfirm && !state.isSending)
                Text(state.footnote).pumText(.caption).foregroundStyle(PumColor.textTertiary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, PumTokens.Size.screenPad)
            .padding(.top, PumTokens.Space.s12)
            .padding(.bottom, PumTokens.Space.s10) // 원문 아래 44 − 안전 영역 34
            .background(PumColor.bgApp)
        }
    }

    private func confirm() {
        guard state.beginConfirm() else { return }
        onConfirm(state.selectedChoiceID) { success in
            if !success { state.endConfirm() }
        }
    }

    private func choose(_ id: String) {
        guard !state.isSending, id != state.selectedChoiceID else { return }
        state.select(id)
        onChoiceChanged(id)
    }

    private func section<C: View>(_ title: String, @ViewBuilder content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s6) {
            Text(title).pumText(.caption, weight: .bold).foregroundStyle(PumColor.textSecondary)
                .padding(.horizontal, PumTokens.Space.s4)
                .accessibilityAddTraits(.isHeader)
            content()
        }
    }

    private var divider: some View {
        Rectangle().fill(PumColor.borderHairline).frame(height: 1) // 카드 끝까지
    }

    // MARK: 요약

    private var summaryCard: some View {
        PumCard {
            VStack(alignment: .leading, spacing: 0) {
                Text(state.summaryTitle).pumText(.caption, weight: .regular).foregroundStyle(PumColor.textSecondary)
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .firstTextBaseline, spacing: PumTokens.Space.s10) { oldAmount; newAmount }
                    VStack(alignment: .leading, spacing: PumTokens.Space.s2) { oldAmount; newAmount } // 넘치면 아래로
                }
                .padding(.top, PumTokens.Space.s4)
                Text(state.deltaText).pumText(.footnote, weight: .bold)
                    .foregroundStyle(state.deltaWon < 0 ? PumColor.textSecondary : PumColor.statusDone)
                    .padding(.top, PumTokens.Space.s2)
            }
            .padding(.horizontal, PumTokens.Space.s16)
            .padding(.vertical, PumTokens.Space.s14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(state.summaryAccessibility))
        }
    }

    private var oldAmount: some View {
        Text(state.beforeText).pumText(.body, weight: .regular) // 원문 15px 400
            .strikethrough().foregroundStyle(PumColor.textTertiary)
    }

    private var newAmount: some View {
        Text(state.afterText).pumText(.title1, weight: .bold) // 원문 26px 700 → 28px 근사
            .foregroundStyle(PumColor.textPrimary)
    }

    // MARK: 바뀐 내역

    private var changesCard: some View {
        PumCard {
            ForEach(Array(state.lines.enumerated()), id: \.element.id) { i, line in
                if i > 0 { divider }
                lineRow(line)
            }
        }
    }

    private func lineRow(_ line: CorrectionLine) -> some View {
        let texts = VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
            Text(line.title).pumText(.callout, weight: .regular).foregroundStyle(PumTokens.ColorToken.gray800)
            if let detail = line.detail {
                Text(detail).pumText(.caption, weight: .regular).foregroundStyle(PumColor.textSecondary)
            }
        }
        let amount = Text(line.amountText).pumText(.callout, weight: .semibold)
            .foregroundStyle(line.direction == .decrease ? PumColor.statusDanger : PumColor.textPrimary)
        return ViewThatFits(in: .horizontal) {
            HStack(spacing: PumTokens.Space.s12) { texts; Spacer(minLength: 0); amount.fixedSize() }
            VStack(alignment: .leading, spacing: PumTokens.Space.s4) { texts; amount } // 넘치면 아래로
        }
        .padding(.vertical, PumTokens.Size.rowPadY)
        .padding(.horizontal, PumTokens.Size.rowPadX)
        .frame(maxWidth: .infinity, minHeight: PumTokens.Size.tapMin, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(line.accessibilityText))
    }

    // MARK: 차액 지급

    private var payoutCard: some View {
        PumCard {
            ForEach(Array(state.choices.enumerated()), id: \.element.id) { i, choice in
                if i > 0 { divider }
                choiceRow(choice)
            }
        }
    }

    /// 공통 후보: 제목 + 설명 두 줄 라디오 행(PumRadioRow는 한 줄)
    private func choiceRow(_ choice: CorrectionPayoutChoice) -> some View {
        let isOn = choice.id == state.selectedChoiceID
        return Button { choose(choice.id) } label: {
            HStack(spacing: PumTokens.Space.s12) {
                PumRadioMark(isOn: isOn)
                VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                    Text(choice.title).pumText(.callout, weight: .semibold).foregroundStyle(PumColor.textPrimary)
                    Text(choice.detail).pumText(.caption, weight: .regular).foregroundStyle(PumColor.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, PumTokens.Size.rowPadX)
            .padding(.vertical, PumTokens.Size.rowPadY)
            .frame(minHeight: PumTokens.Size.tapMin)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(state.isSending)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(state.choiceAccessibility(choice)))
        .accessibilityAddTraits(isOn ? [.isButton, .isSelected] : .isButton)
    }
}

#Preview("10g · 캡처 상태") { CorrectionRecalcView(state: .sample) }
#Preview("10g · 큰 글자") { CorrectionRecalcView(state: .sample).dynamicTypeSize(.accessibility3) }
