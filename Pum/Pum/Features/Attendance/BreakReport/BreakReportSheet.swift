// UI-IOS-19h · REQ-030 — 휴게 시트 내용. 시트 판 · 막 · 모션은 공통 C9(`pumBottomSheet`).
// 「바뀌면」 값은 서버 값(선택별 미리보기). 예정과 같은 시간이면 보내기 비활성(원문 없음), 사유 빈칸은 막지 않는다(원문 없음).
import SwiftUI

struct BreakReportSheet: View {
    let state: BreakReportSheetState
    @Binding var choiceID: String
    @Binding var reason: String
    let isSending: Bool
    let isSent: Bool
    /// 입력칸을 처음부터 입력 중 모양(파랑 테두리)으로 — 원문 캡처 상태
    var startsFocused = false
    var onEdit: () -> Void = {}
    var onSend: () -> Void = {}

    @FocusState private var reasonFocused: Bool
    @Environment(\.dynamicTypeSize) private var typeSize

    private var locked: Bool { isSending || isSent }
    private var canSend: Bool { state.canSend(choiceID: choiceID) }

    var body: some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s12) {
            header
            VStack(alignment: .leading, spacing: PumTokens.Space.s6) { // 원문 라벨~칸 6
                label(BreakReportSheetState.choiceHeader)
                segments.disabled(locked)
            }
            VStack(alignment: .leading, spacing: PumTokens.Space.s6) {
                label(BreakReportSheetState.reasonHeader)
                reasonField
            }
            if let p = state.preview(choiceID) { changeCard(p) }
            VStack(spacing: PumTokens.Space.s12) { // 원문 보내기 버튼~안내는 시트 gap 12
                PumButton(title: BreakReportSheetState.sendTitle, isLoading: isSending,
                          loadingTitle: BreakReportSheetState.sendingTitle, action: onSend)
                    .disabled(!canSend || isSent)
                    .accessibilityHint(Text(canSend ? "" : BreakReportSheetState.samePlannedHint))
                Text(BreakReportSheetState.footerNotice)
                    .pumText(.caption).foregroundStyle(PumColor.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, PumTokens.Size.screenPad)
        // 원문 아래 34는 홈 막대 안전 영역(시트 판이 따로 더함)
        .onAppear { if startsFocused { reasonFocused = true } }
    }

    // MARK: 머리

    private var header: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .firstTextBaseline) { title; Spacer(minLength: PumTokens.Space.s8); planned }
            VStack(alignment: .leading, spacing: PumTokens.Space.s4) { title; planned }
        }
        .padding(.top, PumTokens.Space.s4)
    }

    private var title: some View {
        Text(state.title).pumText(.title3, weight: .bold).foregroundStyle(PumColor.textPrimary)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityAddTraits(.isHeader)
    }

    private var planned: some View {
        Text(state.plannedText).pumText(.footnote).foregroundStyle(PumColor.textSecondary)
    }

    private func label(_ text: String) -> some View {
        Text(text).pumText(.footnote, weight: .semibold).foregroundStyle(PumTokens.ColorToken.gray800)
            .fixedSize(horizontal: false, vertical: true)
    }

    // MARK: 세그먼트

    private var segments: some View {
        HStack(spacing: 0) {
            ForEach(state.choices) { c in
                let selected = choiceID == c.id
                Button {
                    guard choiceID != c.id else { return } // 같은 칸 다시 누름은 손댄 것이 아님
                    onEdit()
                    choiceID = c.id
                } label: {
                    Text(c.title)
                        .pumText(.callout, weight: selected ? .semibold : .medium)
                        .foregroundStyle(selected ? PumColor.textPrimary : PumColor.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.vertical, PumTokens.Space.s8) // 원문 칸 padding 8 0
                        .frame(maxWidth: .infinity)
                        .background {
                            if selected {
                                RoundedRectangle(cornerRadius: PumTokens.Radius.sm, style: .continuous)
                                    .fill(PumColor.surfaceCard)
                            }
                        }
                        // 누름 영역만 44 이상으로 키우고 배치는 원문 칸 높이만 쓴다
                        .padding(.vertical, PumTokens.Space.s6)
                        .contentShape(Rectangle())
                        .padding(.vertical, -PumTokens.Space.s6)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text(c.title)) // 「선택됨」은 .isSelected가 읽는다
                .accessibilityAddTraits(selected ? [.isButton, .isSelected] : .isButton)
            }
        }
        .padding(PumTokens.Space.s2)
        .background(PumColor.surfaceFill, in: RoundedRectangle(cornerRadius: PumTokens.Radius.md, style: .continuous)) // 원문 모서리 10 → 가까운 12
    }

    // MARK: 사유

    private var reasonField: some View {
        TextField("", text: $reason)
            .pumText(.body, weight: .medium)
            .foregroundStyle(PumColor.textPrimary)
            .tint(PumColor.accent)
            .focused($reasonFocused)
            .disabled(locked)
            .onChange(of: reason) { if reasonFocused { onEdit() } } // 서버 값으로 바뀐 것은 손댄 것이 아님
            .padding(.horizontal, PumTokens.Space.s14) // 원문 padding 0 14
            .padding(.vertical, PumTokens.Space.s14) // 원문 상자 높이 48(글자 한 줄 + 14 × 2)
            .background(PumColor.surfaceCard, in: RoundedRectangle(cornerRadius: PumTokens.Radius.md, style: .continuous))
            .pumRing(reasonFocused ? Self.focusRing : .hairline, cornerRadius: PumTokens.Radius.md)
            .accessibilityLabel(Text(BreakReportSheetState.reasonHeader))
    }

    /// 입력 중 — 파랑 테두리(accent)
    private static let focusRing = PumTokens.Shadow(x: 0, y: 0, blur: 0, spread: PumTokens.Shadow.outline.spread, color: PumColor.accent)

    // MARK: 바뀌면

    private func changeCard(_ p: BreakPreview) -> some View {
        PumCard {
            Text(BreakReportSheetState.changeHeader).pumText(.body, weight: .bold).foregroundStyle(PumColor.textPrimary)
                .padding(.horizontal, PumTokens.Size.rowPadX)
                .padding(.top, PumTokens.Space.s14) // 원문 머리 padding 14 16 4
                .padding(.bottom, PumTokens.Space.s4)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityAddTraits(.isHeader)
            changeRow(title: BreakReportSheetState.recognizedTitle, detail: nil, value: p.recognizedChange,
                      readout: state.changeReadout(p))
            Divider().overlay(PumColor.borderHairline)
            changeRow(title: BreakReportSheetState.payTitle, detail: p.payDetail, value: p.payText,
                      readout: state.payReadout(p))
        }
    }

    private func changeRow(title: String, detail: String?, value: String, readout: String) -> some View {
        let left = VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
            Text(title).pumText(.callout, weight: .regular).foregroundStyle(PumTokens.ColorToken.gray800)
            if let detail {
                Text(detail).pumText(.caption).foregroundStyle(PumColor.textSecondary)
            }
        }
        .fixedSize(horizontal: false, vertical: true)
        let right = Text(value).pumText(.callout, weight: .bold).foregroundStyle(PumColor.textPrimary)
            .fixedSize(horizontal: false, vertical: true)
        return ViewThatFits(in: .horizontal) {
            HStack(spacing: PumTokens.Space.s12) { left.frame(maxWidth: .infinity, alignment: .leading); right }
            VStack(alignment: .leading, spacing: PumTokens.Space.s4) { left; right }
        }
        .padding(.horizontal, PumTokens.Size.rowPadX)
        .padding(.vertical, PumTokens.Size.rowPadY)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(readout))
    }
}

#Preview("19h 시트") {
    @Previewable @State var choice = BreakReportSheetState.sample.initialChoiceID
    @Previewable @State var reason = BreakReportSheetState.sample.initialReason
    PumBottomSheetPanel {
        BreakReportSheet(state: .sample, choiceID: $choice, reason: $reason, isSending: false, isSent: false, startsFocused: true)
    }
}
