// UI-IOS-1i · REQ-006 · REQ-042 · REQ-071 — 근무기록 수정 요청 (하위 화면, 탭 바 없음)
// 퇴근 시각 칸 → C13 시간 선택 시트(끝 휠만). 전송은 후속 — 지금은 클로저만 호출한다.
import SwiftUI

struct EditRequestView: View {
    @State var draft: EditRequestDraft
    var onClose: () -> Void = {}
    var onPickTime: () -> Void = {}
    var onSubmit: (EditRequestDraft) -> Void = { _ in }

    @FocusState private var reasonFocused: Bool
    @State private var pickerOpen: Bool
    @State private var pickerValue = PumTimeRangeValue()

    init(draft: EditRequestDraft = .sample, pickerOpen: Bool = false,
         onClose: @escaping () -> Void = {}, onPickTime: @escaping () -> Void = {},
         onSubmit: @escaping (EditRequestDraft) -> Void = { _ in }) {
        _draft = State(initialValue: draft)
        _pickerOpen = State(initialValue: pickerOpen)
        _pickerValue = State(initialValue: PumTimeRangeValue(endMinutes: draft.requestedEnd))
        self.onClose = onClose
        self.onPickTime = onPickTime
        self.onSubmit = onSubmit
    }

    // 화면 전용 상수 (DEC-005: 목업 px → 가까운 토큰 단계)
    /// 사유 입력칸 높이 — 원문 min-height 112 + padding 16×2
    private let reasonHeight: CGFloat = 144
    /// 포커스 테두리 — 목업 1.5–2 중 2
    private let focusLine: CGFloat = 2
    /// 포커스 아닐 때 테두리
    private let restLine: CGFloat = 1

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                VStack(alignment: .leading, spacing: PumTokens.Space.s16) {
                    title
                    timeCard
                    previewBox
                    reasonField
                    // 목업 13px 400 → footnote
                    Text("사장님이 확인한 뒤 반영돼요. 승인·거절 결과는 알림으로 알려드리고, 모든 변경은 이력으로 남아요.")
                        .pumText(.footnote).foregroundStyle(PumColor.textSecondary)
                        .padding(.horizontal, PumTokens.Space.s4)
                }
                .padding(.horizontal, PumTokens.Size.screenPad)
                .padding(.top, PumTokens.Space.s16) // 원문 머리 줄 아래 16
                .padding(.bottom, PumTokens.Space.s12)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .background(PumColor.bgApp)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            PumButton(title: "수정 요청 보내기", kind: .primary) { onSubmit(draft) }
                .disabled(!draft.canSubmit)
                .padding(.horizontal, PumTokens.Size.screenPad)
                .padding(.vertical, PumTokens.Space.s12)
                .background(PumColor.bgApp)
        }
        .pumTimeRangeSheet(isPresented: $pickerOpen, value: $pickerValue, options: pickerOptions) {
            draft = draft.applying(pickedEnd: pickerValue.endMinutes)
        }
    }

    private var pickerOptions: PumTimeRangeOptions {
        PumTimeRangeOptions(
            title: EditRequestDraft.pickerTitle, mode: .endOnly, rangeLabel: draft.pickerRowLabel,
            showsDate: false, showsBreak: false, showsRepeat: false, showsEndDate: false,
            intervalMinutes: EditRequestDraft.pickerIntervalMinutes
        )
    }

    /// 열 때의 값을 시트용 복사본에 담는다 — 「완료」 전에 닫으면(막 · VoiceOver) 화면 값은 그대로
    private func openPicker() {
        onPickTime()
        pickerValue.endMinutes = draft.requestedEnd
        pickerOpen = true
    }

    /// 1f처럼 닫기(✕) — 왼쪽 원형 버튼 · 가운데 제목
    private var header: some View {
        ZStack {
            Text("근무기록 수정 요청").pumText(.headline).foregroundStyle(PumColor.textPrimary)
                .lineLimit(1).padding(.horizontal, PumTokens.Size.tapMin + PumTokens.Space.s8)
                .accessibilityAddTraits(.isHeader)
            HStack {
                PumIconButton(systemImage: "xmark", label: "닫기", action: onClose)
                Spacer()
            }
        }
        .padding(.vertical, -(PumTokens.Size.tapMin - EditRequestLocal.headerRowHeight) / 2) // 원문 줄 높이 40(누름 44 유지) · 위 여백 없음
        .padding(.horizontal, PumTokens.Size.screenPad)
    }

    private var title: some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s4) {
            Text(draft.dateTitle).pumText(.title2).foregroundStyle(PumColor.textPrimary)
                .accessibilityAddTraits(.isHeader)
            // 목업 14px 400 → callout regular
            Text(draft.subtitle).pumText(.callout, weight: .regular).foregroundStyle(PumColor.textSecondary)
        }
    }

    private var timeCard: some View {
        PumCard {
            // 원문: 카드 padding 4 18 · 행 padding 14 0 · 구분선은 카드 안쪽 폭
            VStack(spacing: 0) {
                startRow
                Rectangle().fill(PumColor.borderHairline).frame(height: 1)
                endRow
            }
            .padding(.vertical, PumTokens.Space.s4)
            .padding(.horizontal, PumTokens.Space.s18)
        }
    }

    private var startRow: some View {
        HStack(spacing: PumTokens.Space.s12) {
            Text("출근시간").pumText(.body, weight: .regular).foregroundStyle(PumColor.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            // 바꾸지 않는 칸이라 흐림. 목업 17px 600 → headline
            Text(draft.recordedStartText).pumText(.headline).foregroundStyle(PumColor.textTertiary)
        }
        .padding(.vertical, PumTokens.Space.s14)
        .frame(minHeight: PumTokens.Size.tapMin)
        .accessibilityElement(children: .combine)
    }

    /// 좁거나 글자가 크면 라벨 아래로 값이 내려간다
    private var endRow: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: PumTokens.Space.s12) { endLabel; Spacer(minLength: 0); endValues }
            VStack(alignment: .leading, spacing: PumTokens.Space.s8) { endLabel; endValues }
        }
        .padding(.vertical, PumTokens.Space.s14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(draft.endRowAccessibility))
        .accessibilityAddTraits(.isButton)
        .accessibilityHint(Text("퇴근 시간을 골라요"))
        .accessibilityAction(.default, openPicker)
    }

    private var endLabel: some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
            Text("퇴근시간").pumText(.body, weight: .semibold).foregroundStyle(PumColor.textPrimary)
            Text("기록 \(draft.recordedEndText)").pumText(.caption).foregroundStyle(PumColor.textSecondary)
        }
        .fixedSize(horizontal: true, vertical: false)
    }

    private var endValues: some View {
        HStack(spacing: PumTokens.Space.s10) { // 원문 gap 10
            Text(draft.recordedEndText).pumText(.body, weight: .regular)
                .strikethrough().foregroundStyle(PumColor.textTertiary)
            Image(systemName: "arrow.right").font(.footnote.weight(.semibold))
                .foregroundStyle(PumColor.textSecondary)
            Button(action: openPicker) {
                // 목업 20px 700 → title3
                Text(draft.requestedEndText).pumText(.title3).foregroundStyle(PumColor.accent)
                    .padding(.horizontal, PumTokens.Space.s12)
                    .padding(.vertical, PumTokens.Space.s6) // 원문 칸 padding 6 12
                    .background(PumColor.accentSoft, in: RoundedRectangle(cornerRadius: PumTokens.Radius.md, style: .continuous))
                    .frame(minWidth: PumTokens.Size.tapMin, minHeight: PumTokens.Size.tapMin)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.vertical, -PumTokens.Space.s2) // 보이는 높이만 원문에 가깝게, 누름 44 유지
        }
    }

    @ViewBuilder private var previewBox: some View {
        if let previewText = draft.previewText { previewBoxContent(previewText) }
    }

    private func previewBoxContent(_ previewText: String) -> some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: PumTokens.Space.s12) { previewLabel; Spacer(minLength: 0); previewValue(previewText) }
            VStack(alignment: .leading, spacing: PumTokens.Space.s4) { previewLabel; previewValue(previewText) }
        }
        .padding(.vertical, PumTokens.Space.s12)
        .padding(.horizontal, PumTokens.Space.s16) // 원문 12 16
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(PumColor.surfaceFill, in: RoundedRectangle(cornerRadius: PumTokens.Radius.md, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    private var previewLabel: some View {
        Text("반영되면").pumText(.footnote).foregroundStyle(PumColor.textSecondary)
    }

    private func previewValue(_ previewText: String) -> some View {
        Text(previewText).pumText(.footnote, weight: .semibold).foregroundStyle(PumColor.textPrimary)
            .multilineTextAlignment(.trailing)
    }

    private var reasonField: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("사유").pumText(.footnote, weight: .bold).foregroundStyle(PumColor.textSecondary)
                .accessibilityAddTraits(.isHeader)
                .padding(.horizontal, PumTokens.Space.s4) // 원문: 카드보다 약 4 안쪽
                .padding(.bottom, PumTokens.Space.s8) // 원문 라벨 아래 8
            TextEditor(text: $draft.reason)
            // 200자 자르기는 값이 바뀐 뒤에 — 바인딩 set에서 자르면 한글 조합 중 글자가 끊기거나 201번째가 화면에 남는다
            .onChange(of: draft.reason) { _, new in
                let clamped = EditRequestDraft.clampedReason(new)
                if clamped != new { draft.reason = clamped }
            }
            .focused($reasonFocused)
            .pumText(.body, weight: .regular) // 목업 16px → body(15)
            .foregroundStyle(PumColor.textPrimary)
            .scrollContentBackground(.hidden)
            .padding(PumTokens.Space.s12)
            .frame(height: reasonHeight)
            .background(PumColor.surfaceCard, in: RoundedRectangle(cornerRadius: PumTokens.Radius.md, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: PumTokens.Radius.md, style: .continuous)
                    .strokeBorder(reasonFocused ? PumColor.accent : PumColor.borderHairline, lineWidth: reasonFocused ? focusLine : restLine)
            }
            .accessibilityLabel(Text("사유"))
            Text(draft.counterText).pumText(.caption).foregroundStyle(PumColor.textTertiary)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.horizontal, PumTokens.Space.s4)
                .padding(.top, PumTokens.Space.s6) // 원문 칸 아래 6
                .accessibilityLabel(Text(draft.counterAccessibility))
        }
    }
}

#Preview("1i") { EditRequestView() }
#Preview("1i · 시간 선택 시트") {
    EditRequestView(pickerOpen: true)
}
#Preview("1i · 큰 글자") { EditRequestView().dynamicTypeSize(.xxxLarge) }

/// 화면 전용 상수 — 토큰에 없는 값(DEC-005)
private enum EditRequestLocal {
    /// 머리 줄(닫기 · 제목) 높이 40 — 누름 영역 44는 유지
    static let headerRowHeight = PumLayout.navRow
}
