// UI-IOS-1s · REQ-006 · REQ-042 · DEC-005 — 수정 요청 승인(사장님). 승인 전까지 기존 기록 그대로. 탭 바 없음.
// 거절 · 승인 · 다른 시간으로 직접 수정은 클로저만(연결 후속).
import SwiftUI

struct EditApprovalView: View {
    var state: EditApprovalState = .sample
    var onBack: () -> Void = {}
    var onReject: () -> Void = {}
    var onApprove: () -> Void = {}
    var onEditDirectly: () -> Void = {}

    // 화면 전용 상수 — 토큰에 없는 값(DEC-005)
    private enum Local {
        /// 사람 아바타 약 44 → 터치 최소 크기 토큰(44)과 같다
        static let avatarSize: CGFloat = PumTokens.Size.tapMin
        /// 인용 막대 폭 약 3 (1ae와 같음)
        static let quoteBarWidth: CGFloat = 3
        /// 변경 이력 점 지름 약 10, 점 칸 폭, 점 사이 선 폭
        static let dotSize: CGFloat = PumTokens.Space.s10
        static let markerColumn: CGFloat = PumTokens.Space.s16
        static let lineWidth: CGFloat = 1
    }

    var body: some View {
        VStack(spacing: 0) {
            PumNavHeader(title: EditApprovalState.screenTitle, onBack: onBack)
                .padding(.horizontal, PumTokens.Size.screenPad)
            ScrollView {
                VStack(alignment: .leading, spacing: PumTokens.Space.s12) {
                    personRow
                    changeCard
                    historyCard
                    Button(action: onEditDirectly) {
                        Text(EditApprovalState.directEditText).pumText(.footnote, weight: .regular) // 13px
                            .underline().foregroundStyle(PumColor.textSecondary)
                            .frame(maxWidth: .infinity, minHeight: PumTokens.Size.tapMin)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, PumTokens.Size.screenPad)
                .padding(.vertical, PumTokens.Space.s12)
            }
        }
        .background(PumColor.bgApp)
        .safeAreaInset(edge: .bottom, spacing: 0) { actions }
    }

    // 2. 사람 줄
    private var personRow: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: PumTokens.Space.s12) { personInfo; badge }
            VStack(alignment: .leading, spacing: PumTokens.Space.s8) { personInfo; badge }
        }
        .padding(.horizontal, PumTokens.Space.s4)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(state.personAccessibilityText))
    }

    private var personInfo: some View {
        HStack(spacing: PumTokens.Space.s12) {
            PumAvatar(name: state.employeeName, colorIndex: state.colorIndex, size: Local.avatarSize)
            VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                // 18px 700 → headline(17) bold
                Text(state.employeeName).pumText(.headline, weight: .bold).foregroundStyle(PumColor.textPrimary)
                Text(state.subtitleText).pumText(.footnote, weight: .regular).foregroundStyle(PumColor.textSecondary) // 13px
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var badge: some View { PumBadge(text: EditApprovalState.reviewBadgeText, kind: .attention) }

    // 3. 변경 카드
    private var changeCard: some View {
        PumCard {
            VStack(alignment: .leading, spacing: PumTokens.Space.s12) {
                Text(EditApprovalState.fieldLabel).pumText(.caption, weight: .bold).foregroundStyle(PumColor.textSecondary) // 12px 700
                timeChange
                messageBox
                changeCells
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(PumTokens.Space.s16)
        }
    }

    private var timeChange: some View {
        HStack(alignment: .bottom, spacing: PumTokens.Space.s12) {
            VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                Text(EditApprovalState.recordedLabel).pumText(.caption2, weight: .regular).foregroundStyle(PumColor.textTertiary)
                // 26px 600 → title2(24) 굵기 600. 기존 기록이라 흐림 + 취소선
                Text(state.recordedEndText).pumText(.title2, weight: .semibold)
                    .strikethrough().foregroundStyle(PumColor.textTertiary)
            }
            Image(systemName: "arrow.right").font(.body.weight(.semibold))
                .foregroundStyle(PumColor.textPrimary)
                .padding(.bottom, PumTokens.Space.s6)
            VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                Text(EditApprovalState.requestedLabel).pumText(.caption2, weight: .semibold).foregroundStyle(PumColor.accent)
                Text(state.requestedEndText).pumText(.title2, weight: .bold).foregroundStyle(PumColor.accent) // 26px 700 → title2(24)
            }
            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(state.timeAccessibilityText))
    }

    private var messageBox: some View {
        HStack(alignment: .top, spacing: PumTokens.Space.s12) {
            Rectangle().fill(PumTokens.ColorToken.gray300) // 인용 막대(1ae와 같음)
                .frame(width: Local.quoteBarWidth)
                .accessibilityHidden(true)
            Text(state.message).pumText(.body, weight: .regular) // 15px → body
                .foregroundStyle(PumColor.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .fixedSize(horizontal: false, vertical: true)
        .padding(PumTokens.Space.s12)
        .background(PumColor.surfaceFill, in: RoundedRectangle(cornerRadius: PumTokens.Radius.md, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(state.messageAccessibilityText))
    }

    private var changeCells: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .top, spacing: PumTokens.Space.s8) {
                cell(state.recognizedChange)
                cell(state.payChange)
            }
            VStack(spacing: PumTokens.Space.s8) {
                cell(state.recognizedChange)
                cell(state.payChange)
            }
        }
    }

    private func cell(_ change: ApprovalChange) -> some View {
        var from = AttributedString(change.fromText)
        from.font = PumFont.font(size: PumTokens.FontToken.body.size, weight: .semibold, relativeTo: .body)
        var to = AttributedString(change.toText)
        // 원문 900 — 토큰 굵기 중 가장 굵은 bold
        to.font = PumFont.font(size: PumTokens.FontToken.body.size, weight: .heavy, relativeTo: .body) // 원문 15px 900 → Pretendard ExtraBold(heavy)
        return VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
            Text(change.label).pumText(.caption2, weight: .regular).foregroundStyle(PumColor.textSecondary) // 11px
            Text(from + to).pumText(.body, weight: .semibold).foregroundStyle(PumColor.textPrimary) // 15px
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(PumTokens.Space.s12)
        .background(PumColor.surfaceCard, in: RoundedRectangle(cornerRadius: PumTokens.Radius.md, style: .continuous))
        .pumRing(.hairline, cornerRadius: PumTokens.Radius.md)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(change.accessibilityText))
    }

    // 4. 변경 이력
    private var historyCard: some View {
        PumCard {
            VStack(alignment: .leading, spacing: PumTokens.Space.s12) {
                Text(EditApprovalState.historyTitle).pumText(.footnote, weight: .bold).foregroundStyle(PumColor.textSecondary) // 13px 700
                    .accessibilityAddTraits(.isHeader)
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(state.history.enumerated()), id: \.element.id) { index, step in
                        stepRow(step, isLast: index == state.history.count - 1)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(PumTokens.Space.s16)
        }
    }

    private func stepRow(_ step: ApprovalHistoryStep, isLast: Bool) -> some View {
        let pending = step.status == .pending
        return HStack(alignment: .top, spacing: PumTokens.Space.s12) {
            VStack(spacing: PumTokens.Space.s2) {
                marker(step.status)
                if !isLast {
                    Rectangle().fill(PumColor.borderHairline).frame(width: Local.lineWidth).frame(maxHeight: .infinity)
                }
            }
            .frame(width: Local.markerColumn)
            VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                Text(step.title).pumText(.callout) // 14px 600
                    .foregroundStyle(pending ? PumColor.textTertiary : PumColor.textPrimary)
                Text(step.detail).pumText(.caption, weight: .regular) // 12px
                    .foregroundStyle(pending ? PumColor.textTertiary : PumColor.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, isLast ? 0 : PumTokens.Space.s12)
        }
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(step.accessibilityText))
    }

    @ViewBuilder private func marker(_ status: ApprovalHistoryStep.Status) -> some View {
        switch status {
        case .done: Circle().fill(PumTokens.ColorToken.gray300).frame(width: Local.dotSize, height: Local.dotSize)
        case .current: Circle().fill(PumColor.statusAttentionDot).frame(width: Local.dotSize, height: Local.dotSize)
        case .pending:
            // 점선 원 — SF Symbol, 회색
            Image(systemName: "circle.dashed").font(.caption.weight(.semibold)).foregroundStyle(PumColor.textTertiary)
        }
    }

    // 6. 하단 고정 두 버튼 (비율 1 : 1.5 ≈ 원문 4:6) — 거절은 위험 outline(빨강)
    private var actions: some View {
        PumButtonPair(negative: EditApprovalState.rejectText, positive: state.approveText,
                      onNegative: onReject, onPositive: onApprove)
            .padding(.horizontal, PumTokens.Size.screenPad)
            .padding(.top, PumTokens.Space.s12)
            .padding(.bottom, PumTokens.Space.s4)
            .background(PumColor.bgApp)
    }
}

#Preview("1s") { EditApprovalView() }
#Preview("1s · 큰 글자") { EditApprovalView().dynamicTypeSize(.xxxLarge) }
