// UI-IOS-1ad · REQ-044 — 근무기록 확인 요청 시트 내용. 시트 판 · 막 · 모션은 공통 C9(`pumBottomSheet`).
import SwiftUI

/// 화면 전용 상수 — 토큰에 없는 값(DEC-005)
enum RecordReviewRequestLocal {
    /// 메시지 입력칸 높이(TextEditor는 세로로 늘어나려 해 높이를 정한다)
    static let messageMinHeight: CGFloat = PumTokens.Space.s16 * 5 // 원문 두 줄 + 안쪽 여백(약 80)
}

struct RecordReviewRequestSheet: View {
    @Binding var state: RecordReviewRequestState
    var onSend: () -> Void = {}
    var onPickDate: () -> Void = {}

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .footnote) private var messageMinHeight = RecordReviewRequestLocal.messageMinHeight

    var body: some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s12) {
            VStack(alignment: .leading, spacing: PumTokens.Space.s6) {
                Text(RecordReviewRequestState.sheetTitle).pumText(.title3) // 22px 700 → title3(1ao · 1al과 같은 결정)
                    .foregroundStyle(PumColor.textPrimary)
                    .accessibilityAddTraits(.isHeader)
                Text(RecordReviewRequestState.sheetSubtitle).pumText(.footnote, weight: .regular) // 13px
                    .foregroundStyle(PumColor.textSecondary)
            }
            .padding(.horizontal, PumTokens.Space.s4) // 원문: 카드보다 약 4 안쪽
            settings
            messageField
            PumButton(title: state.sendTitle, kind: .primary, isLoading: state.isSending, action: onSend)
                .disabled(!state.canSend && !state.isSending)
                .padding(.top, PumTokens.Space.s4)
        }
        .padding(.horizontal, PumTokens.Size.screenPad)
        .padding(.bottom, PumTokens.Space.s16)
    }

    // MARK: 설정 카드

    private var settings: some View {
        PumCard {
            VStack(spacing: 0) {
                kvRow(RecordReviewRequestState.periodTitle, state.periodLabel)
                divider
                deadlineRow
                divider
                kvRow(RecordReviewRequestState.targetTitle, state.targetText)
                divider
                autoSendRow
            }
        }
        .animation(PumMotion.respecting(reduceMotion, PumMotion.fast), value: state.autoSends) // M2 · M22
    }

    private var divider: some View {
        Rectangle().fill(PumTokens.ColorToken.borderHairline).frame(height: 1)
            .padding(.horizontal, PumTokens.Size.rowPadX) // 행 사이 hairline 안쪽
    }

    private func kvRow(_ key: String, _ value: String) -> some View {
        keyValue(key, value)
            .padding(.horizontal, PumTokens.Size.rowPadX)
            .padding(.vertical, PumTokens.Size.rowPadY)
            .frame(minHeight: PumTokens.Size.tapMin)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text("\(key), \(value)"))
    }

    private func keyValue(_ key: String, _ value: String) -> some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .firstTextBaseline, spacing: PumTokens.Space.s12) {
                keyText(key)
                Spacer(minLength: PumTokens.Space.s8)
                valueText(value)
            }
            VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                keyText(key)
                valueText(value)
            }
        }
    }

    private func keyText(_ s: String) -> some View {
        Text(s).pumText(.body, weight: .regular).foregroundStyle(PumColor.textSecondary) // 15px 400
    }

    private func valueText(_ s: String) -> some View {
        Text(s).pumText(.body, weight: .semibold).foregroundStyle(PumColor.textPrimary) // 15px 600
            .multilineTextAlignment(.trailing)
    }

    // MARK: 회신 기한 + 알약

    private var deadlineRow: some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s10) {
            keyValue(RecordReviewRequestState.deadlineTitle, state.deadlineText)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text("\(RecordReviewRequestState.deadlineTitle), \(state.deadlineText)"))
            RecordReviewRequestFlow(spacing: PumTokens.Space.s8) {
                ForEach(RecordReviewDeadlineChoice.allCases, id: \.self) { c in
                    PumChoicePill(title: c.title, isOn: state.choice == c) {
                        guard !state.isSending else { return }
                        if c == .custom { onPickDate() } else { state.choice = c }
                    }
                }
            }
        }
        .padding(.horizontal, PumTokens.Size.rowPadX)
        .padding(.vertical, PumTokens.Size.rowPadY)
    }

    // MARK: 자동 보내기

    private var autoSendRow: some View {
        Toggle(isOn: $state.autoSends) {
            VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                Text(RecordReviewRequestState.autoSendTitle).pumText(.body, weight: .semibold) // 15px 600
                    .foregroundStyle(PumColor.textPrimary)
                Text(state.autoSendSubtitle).pumText(.caption, weight: .regular) // 12px
                    .foregroundStyle(PumColor.textSecondary)
            }
        }
        .tint(PumColor.accent)
        .disabled(state.isSending) // 처리 중에는 보낸 값과 화면 값이 어긋나지 않게
        .padding(.horizontal, PumTokens.Size.rowPadX)
        .padding(.vertical, PumTokens.Space.s10)
        .frame(minHeight: PumTokens.Size.tapMin)
        .accessibilityLabel(Text("\(RecordReviewRequestState.autoSendTitle), \(state.autoSendSubtitle)"))
    }

    // MARK: 메시지

    private var messageField: some View {
        TextEditor(text: $state.message)
            .pumText(.callout, weight: .regular) // 14px 400
            .foregroundStyle(PumTokens.ColorToken.gray800)
            .scrollContentBackground(.hidden)
            .disabled(state.isSending)
            .padding(PumTokens.Space.s12)
            .frame(height: messageMinHeight) // TextEditor는 세로로 늘어나려 해서 시트를 화면 끝까지 키운다 — 높이를 정해 둔다
            .background(PumColor.surfaceCard, in: RoundedRectangle(cornerRadius: PumTokens.Radius.lg, style: .continuous))
            .pumRing(.hairline, cornerRadius: PumTokens.Radius.lg)
            .accessibilityLabel(Text("직원에게 보낼 메시지"))
    }
}

/// 선택 알약 — 선택 = 먹색 바탕 + 흰 13px 600, 선택 안 됨 = surfaceFill + 먹색. 터치 44.
/// 공통에 같은 알약이 없어 화면 전용(공통 후보).
/// 줄바꿈 배치 — 알약 · 사람 칩이 넘치면 다음 줄로
struct RecordReviewRequestFlow: Layout {
    var spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        arrange(in: proposal.width ?? .infinity, subviews: subviews).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(in: bounds.width, subviews: subviews)
        for (i, origin) in result.origins.enumerated() {
            subviews[i].place(at: CGPoint(x: bounds.minX + origin.x, y: bounds.minY + origin.y), proposal: .unspecified)
        }
    }

    private func arrange(in width: CGFloat, subviews: Subviews) -> (size: CGSize, origins: [CGPoint]) {
        var origins: [CGPoint] = []
        var x: CGFloat = 0, y: CGFloat = 0, rowH: CGFloat = 0, maxW: CGFloat = 0
        for s in subviews {
            let sz = s.sizeThatFits(.unspecified)
            if x > 0, x + sz.width > width { x = 0; y += rowH + spacing; rowH = 0 }
            origins.append(CGPoint(x: x, y: y))
            x += sz.width + spacing
            rowH = max(rowH, sz.height)
            maxW = max(maxW, x - spacing)
        }
        return (CGSize(width: maxW, height: y + rowH), origins)
    }
}
