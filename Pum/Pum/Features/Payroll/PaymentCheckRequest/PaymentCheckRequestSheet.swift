// UI-IOS-21d · REQ-076 · DEC-003 — 입금 확인 요청 시트 내용(공통 바텀시트 C9 안).
// 「보낸 게 맞아요」는 한 번만 — 누르는 즉시 잠그고 실패일 때만 푼다. 「지급 대기로」는 21a 확인 시트로 가는 클로저만 부른다
// (이 화면에서 상태를 바꾸지 않음, DEC-003). 처리 중에는 두 버튼 모두 잠근다.
import SwiftUI

struct PaymentCheckRequestSheet: View {
    let state: PaymentCheckRequestState
    @Binding var lock: PaymentCheckConfirmLock
    var onConfirmSent: (_ done: @escaping (Bool) -> Void) -> Void
    var onRevertToPending: () -> Void

    private var isConfirming: Bool { lock.isConfirming }

    var body: some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s16) {
            head
            infoCard
            buttons
            Text(state.notice).pumText(.caption).foregroundStyle(PumColor.textSecondary)
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, PumTokens.Size.screenPad)
        .padding(.bottom, PumTokens.Space.s8)
    }

    private var head: some View {
        HStack(spacing: PumTokens.Space.s12) {
            PumAvatar(name: state.employeeName, colorIndex: state.avatarColorIndex, size: PumTokens.Size.tapMin)
            VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                Text(state.headline).pumText(.headline).foregroundStyle(PumColor.textPrimary) // 원문 16px 600 — headline(17)로 근사
                Text(state.requestSubtitle).pumText(.caption).foregroundStyle(PumColor.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(state.headSpoken))
        .accessibilityAddTraits(.isHeader)
    }

    private var infoCard: some View {
        PumCard {
            amountRow
            stackedRow(title: state.accountLabel, detail: state.sentAccount, spoken: state.accountSpoken, isLast: false)
            stackedRow(title: state.paidLabel, detail: state.paidSubtitle, spoken: state.paidSpoken, isLast: true)
        }
    }

    /// 금액 행: 넓으면 한 줄, 좁으면(큰 글자) 값이 아래로
    private var amountRow: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: PumTokens.Space.s12) {
                rowTitle(state.amountLabel)
                Spacer(minLength: 0)
                rowTitle(state.amountText).fixedSize()
            }
            VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                rowTitle(state.amountLabel)
                rowTitle(state.amountText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, PumTokens.Size.rowPadY)
        .frame(minHeight: PumTokens.Size.tapMin)
        .padding(.horizontal, PumTokens.Size.rowPadX)
        .overlay(alignment: .bottom) { hairline }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(state.amountSpoken))
    }

    /// 제목(굵게) 위 · 설명(회색) 아래 행
    private func stackedRow(title: String, detail: String, spoken: String, isLast: Bool) -> some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
            rowTitle(title)
            Text(detail).pumText(.caption).foregroundStyle(PumColor.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, PumTokens.Size.rowPadY)
        .frame(minHeight: PumTokens.Size.tapMin)
        .padding(.horizontal, PumTokens.Size.rowPadX)
        .overlay(alignment: .bottom) { if !isLast { hairline } }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(spoken))
    }

    private func rowTitle(_ s: String) -> some View {
        Text(s).pumText(.callout).foregroundStyle(PumColor.textPrimary) // 원문 14px 600
    }

    /// 원문: 행 사이 선은 카드 끝까지
    private var hairline: some View {
        Rectangle().fill(PumColor.borderHairline).frame(height: 1)
    }

    /// 두 버튼: 넓으면 1 : 1.5 가로, 넘치면 세로(파랑이 위)
    private var buttons: some View {
        ViewThatFits(in: .horizontal) {
            PaymentCheckRatioRow(spacing: PumTokens.Space.s8) { revertButton; confirmButton }
            VStack(spacing: PumTokens.Space.s8) { confirmButton; revertButton }
        }
    }

    private var revertButton: some View {
        PumButton(title: state.revertTitle, kind: .outline, action: onRevertToPending)
            .disabled(isConfirming)
    }

    private var confirmButton: some View {
        PumButton(title: state.confirmTitle, kind: .primary, isLoading: isConfirming,
                  loadingTitle: state.confirmingTitle, action: confirm)
    }

    /// 한 번만 — 누르는 즉시 잠그고, 실패일 때만 푼다
    private func confirm() {
        guard lock.begin() else { return }
        onConfirmSent { success in lock.finish(success: success) }
    }
}

/// 공통 후보: 두 버튼 1 : 1.5 가로 배치 — 공통 PumButtonPair는 높이가 고정이라 큰 글자에서 세로 전환이 안 된다.
/// 이상적인 폭은 두 버튼이 각자 자기 몫(1 / 1.5)에 들어가는 최소 폭이라, ViewThatFits가 넘치는지 알 수 있다.
private struct PaymentCheckRatioRow: Layout {
    var spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        guard subviews.count == 2 else { return .zero }
        let ideal = subviews.map { $0.sizeThatFits(.unspecified) }
        let height = ideal.map(\.height).max() ?? 0
        let needed = max(ideal[0].width / 1, ideal[1].width / 1.5) * 2.5 + spacing
        return CGSize(width: proposal.width ?? needed, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        guard subviews.count == 2 else { return }
        let unit = (bounds.width - spacing) / 2.5
        let widths = [unit, unit * 1.5]
        var x = bounds.minX
        for (i, sub) in subviews.enumerated() {
            sub.place(at: CGPoint(x: x, y: bounds.minY), anchor: .topLeading,
                      proposal: ProposedViewSize(width: widths[i], height: bounds.height))
            x += widths[i] + spacing
        }
    }
}
