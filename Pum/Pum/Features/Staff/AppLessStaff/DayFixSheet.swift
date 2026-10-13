// UI-IOS-20f · REQ-007 · DEC-001 — 하루 고치기 시트 내용. 시트 판 · 막 · 모션은 공통 C9(`pumBottomSheet`)이 하고 스크롤도 거기서 한다.
// 인정 근무 · 가산은 서버 미리보기(현재 입력과 같은 입력에 대한 것일 때만). 시간 행은 근무함일 때만.
// 휴게 고르기는 원문에 화면이 없어 시스템 메뉴(없음 · 30분 · 1시간 — 시간 고르기와 같은 값)로 둔다.
import SwiftUI

/// 시간 칸 — 파랑 테두리(입력 중)를 어느 칸에 줄지
nonisolated enum DayFixField: Equatable, Sendable { case start, end }

struct DayFixSheet: View {
    let state: DayFixState
    @Binding var draft: DayFixDraft
    let isSaving: Bool
    let isSaved: Bool
    /// 파랑 테두리를 둔 칸 — 원문 캡처는 출근 칸
    var focusedField: DayFixField?
    var onEdit: () -> Void = {}
    var onPickStart: () -> Void = {}
    var onPickEnd: () -> Void = {}
    var onCancel: () -> Void = {}
    var onSave: () -> Void = {}

    @FocusState private var reasonFocused: Bool
    @Environment(\.dynamicTypeSize) private var typeSize

    private var locked: Bool { isSaving || isSaved }

    var body: some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s12) {
            header
            segments.disabled(locked)
            if DayFixState.showsTimes(draft) {
                timeFields.disabled(locked)
            }
            if let p = state.visiblePreview(for: draft) { previewCard(p) }
            VStack(alignment: .leading, spacing: PumTokens.Space.s8) {
                label(DayFixState.reasonTitle)
                reasonField
            }
            buttons
            Text(DayFixState.footerNotice)
                .pumText(.caption).foregroundStyle(PumColor.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, PumTokens.Size.screenPad)
        .padding(.bottom, PumTokens.Space.s16)
    }

    // MARK: 머리

    private var header: some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s4) {
            Text(state.dateTitle).pumText(.title3, weight: .bold).foregroundStyle(PumColor.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
            Text(state.plannedText).pumText(.footnote).foregroundStyle(PumColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, PumTokens.Space.s4)
    }

    private func label(_ text: String) -> some View {
        Text(text).pumText(.footnote, weight: .semibold).foregroundStyle(PumTokens.ColorToken.gray800)
            .fixedSize(horizontal: false, vertical: true)
    }

    // MARK: 세그먼트

    private var segments: some View {
        HStack(spacing: 0) {
            ForEach(DayFixKind.allCases) { kind in
                let selected = draft.kind == kind
                Button {
                    guard draft.kind != kind else { return } // 같은 칸 다시 누름은 손댄 것이 아님
                    onEdit()
                    draft.kind = kind
                } label: {
                    Text(kind.title)
                        .pumText(.callout, weight: selected ? .semibold : .medium)
                        .foregroundStyle(selected ? PumColor.textPrimary : PumColor.textSecondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity, minHeight: PumTokens.Size.tapMin)
                        .background {
                            if selected {
                                RoundedRectangle(cornerRadius: PumTokens.Radius.md, style: .continuous)
                                    .fill(PumColor.surfaceCard)
                            }
                        }
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text(kind.title)) // 「선택됨」은 .isSelected가 읽는다
                .accessibilityAddTraits(selected ? [.isButton, .isSelected] : .isButton)
            }
        }
        .padding(PumTokens.Space.s2)
        .background(PumColor.surfaceFill, in: RoundedRectangle(cornerRadius: PumTokens.Radius.lg, style: .continuous))
    }

    // MARK: 시간 칸

    private var timeFields: some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s12) {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .top, spacing: PumTokens.Space.s16) { startField; endField }
                VStack(alignment: .leading, spacing: PumTokens.Space.s12) { startField; endField }
            }
            VStack(alignment: .leading, spacing: PumTokens.Space.s8) {
                label(DayFixState.breakTitle)
                breakMenu
            }
        }
    }

    private var startField: some View {
        timeField(title: DayFixState.startTitle, minutes: draft.startMinutes, field: .start, action: onPickStart)
    }

    private var endField: some View {
        timeField(title: DayFixState.endTitle, minutes: draft.endMinutes, field: .end, action: onPickEnd)
    }

    private func timeField(title: String, minutes: Int, field: DayFixField, action: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s8) {
            label(title)
            Button(action: action) {
                fieldBox(ring: focusedField == field ? Self.focusRing : .hairline) {
                    Text(DayFixState.clock(minutes)).pumText(.body, weight: .regular).foregroundStyle(PumColor.textPrimary)
                }
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(DayFixState.timeReadout(title: title, minutes: minutes)))
            .accessibilityAddTraits(.isButton)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var breakMenu: some View {
        Menu {
            ForEach(PumTimePickerStyle.breakChoices, id: \.minutes) { choice in
                Button(choice.title) {
                    guard draft.breakMinutes != choice.minutes else { return }
                    onEdit()
                    draft.breakMinutes = choice.minutes
                }
            }
        } label: {
            fieldBox(ring: .hairline) {
                Text(DayFixState.breakText(draft.breakMinutes)).pumText(.body, weight: .regular).foregroundStyle(PumColor.textPrimary)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("\(DayFixState.breakTitle), \(DayFixState.breakText(draft.breakMinutes))"))
        .accessibilityAddTraits(.isButton)
    }

    /// 흰 바탕 · 모서리 md · 얇은 테두리 칸
    private func fieldBox<Content: View>(ring: PumTokens.Shadow, @ViewBuilder content: () -> Content) -> some View {
        content()
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, PumTokens.Space.s14) // 원문 padding 0 14
            .frame(minHeight: PumTokens.Size.tapMin)
            .padding(.vertical, PumTokens.Space.s4) // 원문 상자 높이 50(44 + 4 + 4 ≈ 52)
            .background(PumColor.surfaceCard, in: RoundedRectangle(cornerRadius: PumTokens.Radius.md, style: .continuous))
            .pumRing(ring, cornerRadius: PumTokens.Radius.md)
            .contentShape(Rectangle())
    }

    /// 입력 중 — 파랑 테두리(accent)
    private static let focusRing = PumTokens.Shadow(x: 0, y: 0, blur: 0, spread: PumTokens.Shadow.outline.spread, color: PumColor.accent)

    // MARK: 인정 근무 카드

    private func previewCard(_ p: DayFixPreview) -> some View {
        PumCard {
            previewRow(title: DayFixState.recognizedTitle, detail: nil, value: p.recognizedText,
                       readout: state.recognizedReadout(p))
            Divider().overlay(PumColor.borderHairline)
            previewRow(title: DayFixState.deltaTitle, detail: p.deltaDetail, value: p.deltaText,
                       readout: state.deltaReadout(p))
        }
    }

    private func previewRow(title: String, detail: String?, value: String, readout: String) -> some View {
        let left = VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
            Text(title).pumText(.callout, weight: .semibold).foregroundStyle(PumColor.textPrimary)
            if let detail {
                Text(detail).pumText(.caption).foregroundStyle(PumColor.textSecondary)
            }
        }
        .fixedSize(horizontal: false, vertical: true)
        let right = Text(value).pumText(.callout, weight: .semibold).foregroundStyle(PumColor.textPrimary)
            .fixedSize(horizontal: false, vertical: true)
        return ViewThatFits(in: .horizontal) {
            HStack(spacing: PumTokens.Space.s12) { left.frame(maxWidth: .infinity, alignment: .leading); right }
            VStack(alignment: .leading, spacing: PumTokens.Space.s4) { left; right }
        }
        .padding(.horizontal, PumTokens.Size.rowPadX)
        .padding(.vertical, PumTokens.Size.rowPadY)
        .frame(maxWidth: .infinity, minHeight: PumTokens.Size.tapMin, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(readout))
    }

    // MARK: 사유

    private var reasonField: some View {
        TextField("", text: $draft.reason)
            .pumText(.body, weight: .regular)
            .foregroundStyle(PumColor.textPrimary)
            .tint(PumColor.accent)
            .focused($reasonFocused)
            .disabled(locked)
            .onChange(of: draft.reason) { if reasonFocused { onEdit() } } // 서버 값으로 바뀐 것은 손댄 것이 아님
            .padding(.horizontal, PumTokens.Space.s14) // 원문 padding 0 14
            .frame(minHeight: PumTokens.Size.tapMin)
            .padding(.vertical, PumTokens.Space.s4) // 원문 상자 높이 50
            .background(PumColor.surfaceCard, in: RoundedRectangle(cornerRadius: PumTokens.Radius.md, style: .continuous))
            .pumRing(reasonFocused ? Self.focusRing : .hairline, cornerRadius: PumTokens.Radius.md)
            .accessibilityLabel(Text(DayFixState.reasonTitle))
    }

    // MARK: 버튼

    @ViewBuilder private var buttons: some View {
        let cancel = PumButton(title: DayFixState.cancelTitle, kind: .outline, action: onCancel)
            .disabled(isSaving) // 처리 중에는 닫지 않게 — 모양 변화는 저장 버튼만
        let save = PumButton(title: DayFixState.saveTitle, isLoading: isSaving, loadingTitle: DayFixState.savingTitle, action: onSave)
        Group {
            if typeSize.isAccessibilitySize {
                VStack(spacing: PumTokens.Space.s8) { save; cancel }
            } else {
                DayFixRatioPairLayout(ratio: 1.5, spacing: PumTokens.Space.s8) { cancel; save } // 원문 약 1 : 1.5
            }
        }
        .disabled(isSaved)
        .padding(.top, PumTokens.Space.s4)
    }
}

/// 받은 폭을 두 칸으로 1 : ratio 로 나눈다(앞 칸 : 뒤 칸). 19c와 같은 값 — 공통 후보.
private struct DayFixRatioPairLayout: Layout {
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

#Preview("20f 시트") {
    @Previewable @State var draft = DayFixState.sample.initialDraft
    PumBottomSheetPanel {
        DayFixSheet(state: .sample, draft: $draft, isSaving: false, isSaved: false, focusedField: .start)
    }
}
