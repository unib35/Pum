// UI-IOS-21c · REQ-076 — 「아직 입금 안 됐어요」 시트 내용: 사유 라디오(하나만) · 메모(선택) · 취소 / 사장님께 보내기.
// 높이 · 스크롤 · 키보드 대응은 공통 바텀시트(C9)가 한다. 보내는 중에는 입력 · 취소를 잠근다.
import SwiftUI

struct PaymentNotReceivedSheet: View {
    let state: PaymentNotReceivedState
    @Binding var draft: PaymentNotReceivedDraft
    var isSending = false
    var onCancel: () -> Void = {}
    var onSend: () -> Void = {}

    @FocusState private var memoFocused: Bool
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s14) {
            VStack(alignment: .leading, spacing: PumTokens.Space.s4) {
                Text(state.sheetTitle).pumText(.title3).foregroundStyle(PumColor.textPrimary)
                    .accessibilityAddTraits(.isHeader)
                Text(state.sheetSubtitle).pumText(.footnote, weight: .regular).foregroundStyle(PumColor.textSecondary)
            }
            .padding(.horizontal, PumTokens.Space.s2)
            reasonCard
            memoField
            buttons
        }
        .padding(.horizontal, PumTokens.Size.screenPad)
        .padding(.bottom, PumTokens.Space.s10)
    }

    private var reasonCard: some View {
        PumCard {
            ForEach(Array(state.reasons.enumerated()), id: \.element.id) { index, reason in
                PumRadioRow(title: reason.title, isOn: draft.reasonId == reason.id,
                            index: index, count: state.reasons.count) {
                    guard !isSending else { return }
                    draft.select(reason.id)
                }
                .overlay(alignment: .bottom) {
                    if index < state.reasons.count - 1 {
                        Rectangle().fill(PumColor.borderHairline).frame(height: 1)
                            .padding(.horizontal, PumTokens.Size.rowPadX)
                    }
                }
            }
        }
    }

    private var memoField: some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s6) {
            Text(state.memoLabel).pumText(.footnote, weight: .semibold).foregroundStyle(PumTokens.ColorToken.gray800)
                .padding(.horizontal, PumTokens.Space.s2)
                .accessibilityHidden(true)
            TextField("", text: Binding(get: { draft.memo }, set: { draft.setMemo($0) }))
                .pumText(.body, weight: .regular)
                .foregroundStyle(PumColor.textPrimary)
                .focused($memoFocused)
                .submitLabel(.done)
                .onSubmit { memoFocused = false }
                .disabled(isSending)
                .padding(.horizontal, PumTokens.Space.s14)
                .frame(minHeight: PumTokens.Size.buttonH)
                .background(PumColor.surfaceCard, in: RoundedRectangle(cornerRadius: PumTokens.Radius.md, style: .continuous))
                .pumRing(.hairline, cornerRadius: PumTokens.Radius.md)
                .accessibilityLabel(Text(state.memoLabel))
        }
    }

    /// 공통 후보: 취소(흰 바탕 테두리) + 주 버튼 1 : 1.5 쌍(주 버튼 처리 중 글자 · 큰 글자 세로 배치 포함)
    @ViewBuilder private var buttons: some View {
        if typeSize.isAccessibilitySize {
            VStack(spacing: PumTokens.Space.s8) {
                sendButton
                cancelButton
            }
        } else {
            GeometryReader { geo in
                let gap = PumTokens.Space.s8
                let unit = (geo.size.width - gap) / 2.5
                HStack(spacing: gap) {
                    cancelButton.frame(width: unit)
                    sendButton.frame(width: unit * 1.5)
                }
            }
            .frame(height: PumTokens.Size.buttonH)
        }
    }

    private var cancelButton: some View {
        PumButton(title: "취소", kind: .outline, action: onCancel).disabled(isSending)
    }

    private var sendButton: some View {
        PumButton(title: "사장님께 보내기", kind: .primary, isLoading: isSending, loadingTitle: "보내는 중", action: onSend)
            .disabled(isSending || !draft.canSend)
    }
}
