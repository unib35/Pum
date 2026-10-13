// UI-IOS-21a · REQ-076 · DEC-003 — 「지급 대기로 되돌릴까요?」 시트 내용. 시트 판 · 막 · 스크롤은 공통 C9(`pumBottomSheet`)이 한다 — 여기선 ScrollView를 겹치지 않는다.
// 기한 없음(DEC-003): 시간 제한 문구 · 로직 없음. 처리 중 표시는 되돌리기 버튼에만, 보내는 중엔 취소도 막는다.
import SwiftUI

struct PaymentUndoSheet: View {
    let target: PaymentUndoState.UndoTarget
    let lock: PaymentUndoLock
    var onCancel: () -> Void = {}
    var onUndo: () -> Void = {}

    @Environment(\.dynamicTypeSize) private var typeSize
    @ScaledMetric(relativeTo: .body) private var circleSize = PumLayout.avatar - PumTokens.Space.s12 // 원문 24

    var body: some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s14) {
            VStack(alignment: .leading, spacing: PumTokens.Space.s4) { // 원문 위 3 → 4
                Text(PaymentUndoState.undoSheetTitle).pumText(.title3).foregroundStyle(PumColor.textPrimary)
                    .accessibilityAddTraits(.isHeader)
                Text(target.summaryText).pumText(.footnote, weight: .regular).foregroundStyle(PumColor.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, PumTokens.Space.s2)
            notesCard
            buttons
        }
        .padding(.horizontal, PumTokens.Size.screenPad)
        .padding(.bottom, PumTokens.Space.s10) // 원문 아래 34 − 안전 영역(공통 시트가 더함)
    }

    private var notesCard: some View {
        PumCard {
            ForEach(Array(PaymentUndoState.undoNotes.enumerated()), id: \.offset) { index, note in
                if index > 0 { Rectangle().fill(PumColor.borderHairline).frame(height: 1) }
                HStack(spacing: PumTokens.Space.s12) {
                    Image(systemName: "checkmark")
                        .font(.system(size: circleSize * 0.5, weight: .bold))
                        .foregroundStyle(PumColor.textPrimary)
                        .frame(width: circleSize, height: circleSize)
                        .background(PumColor.surfaceFill, in: Circle())
                        .accessibilityHidden(true)
                    Text(note).pumText(.callout, weight: .medium).foregroundStyle(PumColor.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, PumTokens.Size.rowPadX)
                .padding(.vertical, PumTokens.Space.s12)
                .accessibilityElement(children: .combine)
            }
        }
    }

    @ViewBuilder private var buttons: some View {
        if typeSize.isAccessibilitySize {
            VStack(spacing: PumTokens.Space.s8) { undoButton; cancelButton }
        } else {
            UndoRatioPairLayout(ratio: 1.5, spacing: PumTokens.Space.s8) { cancelButton; undoButton } // 원문 1 : 1.5
        }
    }

    private var cancelButton: some View {
        PumButton(title: PaymentUndoState.cancelTitle, kind: .outline, action: onCancel)
            .allowsHitTesting(!lock.isSending) // 보내는 중엔 모양은 그대로 두고 누르기만 막음
            .disabled(lock.isDone)
    }

    private var undoButton: some View {
        PumButton(title: PaymentUndoState.undoTitle, isLoading: lock.isSending,
                  loadingTitle: PaymentUndoState.undoingTitle, action: onUndo)
            .disabled(lock.isDone)
    }
}

/// 받은 폭을 두 칸으로 1 : ratio 로 나눈다(앞 칸 : 뒤 칸).
private struct UndoRatioPairLayout: Layout {
    var ratio: CGFloat
    var spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 0
        let widths = columnWidths(total: width)
        let height = zip(subviews, widths)
            .map { $0.sizeThatFits(ProposedViewSize(width: $1, height: nil)).height }
            .max() ?? 0
        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let widths = columnWidths(total: bounds.width)
        var x = bounds.minX
        for (view, width) in zip(subviews, widths) {
            view.place(at: CGPoint(x: x, y: bounds.minY), anchor: .topLeading,
                       proposal: ProposedViewSize(width: width, height: bounds.height))
            x += width + spacing
        }
    }

    private func columnWidths(total: CGFloat) -> [CGFloat] {
        let unit = max(0, total - spacing) / (1 + ratio)
        return [unit, unit * ratio]
    }
}

#Preview("21a 시트") {
    PumBottomSheetPanel {
        PaymentUndoSheet(target: PaymentUndoState.sample.undoTarget!, lock: PaymentUndoLock())
    }
}
