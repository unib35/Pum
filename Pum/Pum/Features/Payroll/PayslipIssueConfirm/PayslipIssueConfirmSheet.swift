// UI-IOS-10e · REQ-074 — 발행 확인 시트 내용(공통 바텀시트 C9 안).
// 「발행」은 한 번만 — 누르는 즉시 잠그고 실패일 때만 푼다(되돌릴 수 없음 — 성공이면 잠근 채 부르는 쪽이 닫음).
import SwiftUI

struct PayslipIssueConfirmSheet: View {
    let state: PayslipIssueConfirmState
    @Binding var lock: WorkClosingLock
    var onCancel: () -> Void
    var onIssue: (_ done: @escaping (Bool) -> Void) -> Void

    private var isIssuing: Bool { lock.isClosing }

    var body: some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s12) {
            VStack(alignment: .leading, spacing: PumTokens.Space.s4) {
                Text(state.title).pumText(.title2).foregroundStyle(PumColor.textPrimary) // 원문 22px 700
                    .accessibilityAddTraits(.isHeader)
                Text(state.subtitle).pumText(.footnote, weight: .regular).foregroundStyle(PumColor.textSecondary)
            }
            PumCard {
                ForEach(Array(state.rows.enumerated()), id: \.element.id) { i, r in
                    personRow(r, isLast: i == state.rows.count - 1)
                }
            }
            PumCard {
                termRow(PayslipIssueConfirmState.editLabel, PayslipIssueConfirmState.editValue, isLast: false)
                termRow(PayslipIssueConfirmState.recordLabel, PayslipIssueConfirmState.recordValue, isLast: true)
            }
            buttons.padding(.top, PumTokens.Space.s4)
        }
        .padding(.horizontal, PumTokens.Size.screenPad)
        .padding(.bottom, PumTokens.Space.s8)
    }

    private func personRow(_ r: PayslipIssueConfirmRow, isLast: Bool) -> some View {
        HStack(spacing: PumTokens.Space.s12) {
            PumAvatar(name: r.name, colorIndex: r.colorIndex).accessibilityHidden(true)
            Text(r.name).pumText(.body).foregroundStyle(PumColor.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(r.amountText).pumText(.body, weight: .bold).foregroundStyle(PumColor.textPrimary)
        }
        .padding(.vertical, PumTokens.Size.rowPadY)
        .frame(minHeight: PumTokens.Size.tapMin)
        .padding(.horizontal, PumTokens.Size.rowPadX)
        .overlay(alignment: .bottom) { if !isLast { hairline } }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(r.accessibilityText))
    }

    /// 키–값 행: 넓으면 한 줄, 좁으면(큰 글자) 값이 아래로
    private func termRow(_ label: String, _ value: String, isLast: Bool) -> some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: PumTokens.Space.s12) {
                key(label)
                Spacer(minLength: 0)
                val(value).fixedSize()
            }
            VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                key(label)
                val(value)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, PumTokens.Size.rowPadY)
        .frame(minHeight: PumTokens.Size.tapMin)
        .padding(.horizontal, PumTokens.Size.rowPadX)
        .overlay(alignment: .bottom) { if !isLast { hairline } }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("\(label), \(value)"))
    }

    private func key(_ s: String) -> some View {
        Text(s).pumText(.body, weight: .regular).foregroundStyle(PumColor.textSecondary)
    }

    private func val(_ s: String) -> some View {
        Text(s).pumText(.body, weight: .semibold).foregroundStyle(PumColor.textPrimary)
    }

    private var hairline: some View {
        Rectangle().fill(PumColor.borderHairline).frame(height: 1)
    }

    /// 두 버튼: 넓으면 1 : 1.5 가로(취소 → 발행), 넘치면 세로(같은 순서)
    private var buttons: some View {
        ViewThatFits(in: .horizontal) {
            PayslipConfirmRatioRow(spacing: PumTokens.Space.s8) { cancelButton; issueButton }
            VStack(spacing: PumTokens.Space.s8) { cancelButton; issueButton }
        }
    }

    private var cancelButton: some View {
        PumButton(title: PayslipIssueConfirmState.cancelTitle, kind: .outline, action: onCancel)
            .disabled(isIssuing)
    }

    private var issueButton: some View {
        PumButton(title: PayslipIssueConfirmState.issueTitle, kind: .primary, isLoading: isIssuing,
                  loadingTitle: PayslipIssueConfirmState.issuingTitle, action: issue)
    }

    /// 한 번만 — 누르는 즉시 잠그고, 실패일 때만 푼다
    private func issue() {
        guard lock.begin(canClose: true) else { return }
        onIssue { success in lock.finish(success: success) }
    }
}

/// 공통 후보: 두 버튼 1 : 1.5 가로 배치(21d와 같은 모양) — 넘치면 ViewThatFits가 세로로 넘긴다.
private struct PayslipConfirmRatioRow: Layout {
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
