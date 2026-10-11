// UI-IOS-1v · REQ-107 · DEC-005 — 급여 확정: 미처리 0건일 때 확인 시트. 막을 눌러도 「취소」와 같이 닫는다.
// 「확정」은 되돌리기 어려운 행동(C10) — 이 시트가 그 확인이다. 실제 전송은 후속.
import SwiftUI

struct PayrollConfirmView: View {
    @State private var state: PayrollConfirmState
    @State private var sheetOpen: Bool
    /// 확정 — 두 토글 값을 담은 상태를 넘긴다
    var onConfirm: (PayrollConfirmState) -> Void
    var onCancel: () -> Void

    init(state: PayrollConfirmState = .sample, sheetOpen: Bool = true,
         onConfirm: @escaping (PayrollConfirmState) -> Void = { _ in },
         onCancel: @escaping () -> Void = {}) {
        _state = State(initialValue: state)
        _sheetOpen = State(initialValue: sheetOpen)
        self.onConfirm = onConfirm
        self.onCancel = onCancel
    }

    var body: some View {
        background
            .background(PumColor.bgApp)
            .pumBottomSheet(isPresented: $sheetOpen, onDismiss: onCancel) {
                PayrollConfirmSheet(
                    state: $state,
                    onConfirm: { onConfirm(state) }, // 처리 중 표시는 state.isConfirming — 닫는 것은 호출한 쪽
                    onCancel: { sheetOpen = false; onCancel() })
            }
    }

    /// 뒤 화면(시트에 덮여 어둡게): 머리 + 확인 완료 상자 + 총액 카드
    private var background: some View {
        VStack(spacing: PumTokens.Space.s16) {
            HStack {
                Text("급여").pumText(.title1).foregroundStyle(PumColor.textPrimary) // 28px 700
                    .accessibilityAddTraits(.isHeader)
                Spacer(minLength: PumTokens.Space.s8)
                Text(state.yearMonthTitle).pumText(.callout, weight: .semibold) // 14px 600, 꺾쇠 없음
                    .foregroundStyle(PumColor.textPrimary)
                    .padding(.horizontal, PumTokens.Space.s14)
                    .frame(minHeight: PumTokens.Size.tapMin)
                    .background(PumColor.surfaceCard, in: Capsule())
                    .pumRing(.hairline, cornerRadius: PumTokens.Radius.pill)
            }
            checkedBox
            PumCard {
                VStack(alignment: .leading, spacing: PumTokens.Space.s8) {
                    Text(state.expectedTitle).pumText(.footnote, weight: .medium).foregroundStyle(PumColor.textSecondary) // 13px 500
                    Text(state.amountText).pumText(.hero).foregroundStyle(PumColor.textPrimary) // 32px 700
                        .lineLimit(1).minimumScaleFactor(0.5)
                }
                .padding(PumTokens.Space.s16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityElement(children: .combine)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, PumTokens.Size.screenPad)
        .padding(.vertical, PumTokens.Space.s12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private var checkedBox: some View {
        HStack(spacing: PumTokens.Space.s12) {
            Image(systemName: "checkmark").pumText(.caption, weight: .bold).foregroundStyle(.white)
                .frame(width: PumTokens.Space.s24, height: PumTokens.Space.s24) // 목업 원 약 26 → space-24
                .background(PumColor.statusDone, in: Circle())
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                Text(state.checkedTitle).pumText(.callout, weight: .bold).foregroundStyle(PumTokens.ColorToken.green700) // 14px 700
                Text(state.checkedSubtitle).pumText(.caption, weight: .regular).foregroundStyle(PumColor.statusDone) // 12px
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, PumTokens.Space.s14)
        .padding(.vertical, PumTokens.Space.s10)
        .background(PumColor.statusDoneSoft, in: RoundedRectangle(cornerRadius: PumTokens.Radius.md, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

#Preview("1v") { PayrollConfirmView() }
#Preview("1v · 큰 글자") { PayrollConfirmView().dynamicTypeSize(.accessibility2) }
#Preview("1v · 처리 중") {
    var s = PayrollConfirmState.sample
    s.isConfirming = true
    return PayrollConfirmView(state: s)
}
