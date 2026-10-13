// UI-IOS-10f · REQ-075 — 마감 후 정정 (하위 화면, 탭 바 없음)
// 시각은 C13 1분 휠(1af와 같은 방식). 「다시 계산하기」 성공이면 부모가 10g 정정 재계산으로 넘긴다.
import SwiftUI

struct RecordCorrectionView: View {
    @State private var state: RecordCorrectionState
    @State private var reason: String
    var onBack: () -> Void
    var onOpenSource: () -> Void
    /// 성공이면 done(true) — 화면은 잠긴 채 부모가 넘어간다. 실패면 done(false) — 다시 누를 수 있다.
    var onRecalculate: (RecordCorrection, @escaping (Bool) -> Void) -> Void

    @FocusState private var reasonFocused: Bool
    @State private var pickerOpen = false
    @State private var pickerField: RecordCorrectionField = .end
    @State private var pickerValue = PumTimeRangeValue()

    @ScaledMetric(relativeTo: .body) private var reasonHeight: CGFloat = 112
    private let focusLine: CGFloat = 2
    private let restLine: CGFloat = 1

    init(state: RecordCorrectionState = .sample, reason: String = "",
         onBack: @escaping () -> Void = {},
         onOpenSource: @escaping () -> Void = {},
         onRecalculate: @escaping (RecordCorrection, @escaping (Bool) -> Void) -> Void = { _, done in done(false) }) {
        _state = State(initialValue: state)
        _reason = State(initialValue: RecordCorrectionState.clampedReason(reason))
        self.onBack = onBack
        self.onOpenSource = onOpenSource
        self.onRecalculate = onRecalculate
    }

    var body: some View {
        VStack(spacing: 0) {
            PumNavHeader(title: RecordCorrectionState.title, onBack: onBack)
                .padding(.horizontal, PumTokens.Size.screenPad)
            ScrollView {
                VStack(alignment: .leading, spacing: PumTokens.Space.s12) {
                    headCard
                    section(RecordCorrectionState.contentSection) { timeCard }
                    section(RecordCorrectionState.reasonSection) { reasonEditor }
                    section(RecordCorrectionState.sourceSection) { sourceCard }
                }
                .padding(.horizontal, PumTokens.Size.screenPad)
                .padding(.vertical, PumTokens.Space.s12)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .background(PumColor.bgApp)
        .pumTimeRangeSheet(isPresented: $pickerOpen, value: $pickerValue, options: pickerOptions) {
            let picked = pickerValue
            state = state.applying(picked: picked, field: pickerField)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            VStack(spacing: PumTokens.Space.s10) {
                PumButton(title: RecordCorrectionState.submitTitle, kind: .primary, isLoading: state.isSending, action: submit)
                    .disabled(!state.canRecalculate(reason: reason))
                Text(RecordCorrectionState.footnote).pumText(.caption).foregroundStyle(PumColor.textTertiary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, PumTokens.Size.screenPad)
            .padding(.vertical, PumTokens.Space.s12)
            .background(PumColor.bgApp)
        }
    }

    private var pickerOptions: PumTimeRangeOptions {
        var o = PumTimeRangeOptions()
        o.title = pickerField == .start ? "출근" : "퇴근"
        o.mode = pickerField == .start ? .startOnly : .endOnly
        o.showsDate = false
        o.showsBreak = false
        o.showsRepeat = false
        o.showsEndDate = false
        o.intervalMinutes = RecordCorrectionState.pickerIntervalMinutes
        return o
    }

    private func submit() {
        guard state.beginSend(reason: reason) else { return }
        reasonFocused = false
        let correction = state.correction(reason: reason)
        onRecalculate(correction) { success in
            if !success { state.endSend() }
        }
    }

    private func openPicker(_ field: RecordCorrectionField) {
        pickerField = field
        pickerValue = state.pickerValue // 열 때 값 복사 — 「완료」 전에 닫으면 화면 값은 그대로
        pickerOpen = true
    }

    private func section<C: View>(_ title: String, @ViewBuilder content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s6) {
            Text(title).pumText(.caption, weight: .bold).foregroundStyle(PumColor.textSecondary)
                .padding(.horizontal, PumTokens.Space.s4)
                .accessibilityAddTraits(.isHeader)
            content()
        }
    }

    // MARK: 2. 카드

    private var headCard: some View {
        PumCard {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .top, spacing: PumTokens.Space.s12) {
                    headTexts
                    Spacer(minLength: 0)
                    lockBadge
                }
                VStack(alignment: .leading, spacing: PumTokens.Space.s8) { headTexts; lockBadge }
            }
            .padding(.vertical, PumTokens.Space.s14)
            .padding(.horizontal, PumTokens.Size.rowPadX)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var headTexts: some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s4) {
            Text(state.headline).pumText(.headline, weight: .bold).foregroundStyle(PumColor.textPrimary)
            Text(state.statusText).pumText(.caption).foregroundStyle(PumColor.textSecondary)
        }
    }

    /// 공통 후보: 자물쇠가 붙은 회색 배지(PumBadge는 글자만)
    private var lockBadge: some View {
        HStack(spacing: PumTokens.Space.s4) {
            Image(systemName: "lock").font(.caption.weight(.semibold)).accessibilityHidden(true)
            Text(state.lockText).pumText(.caption, weight: .semibold)
        }
        .foregroundStyle(PumColor.textSecondary)
        .padding(.vertical, PumTokens.Space.s4)
        .padding(.horizontal, PumTokens.Space.s8)
        .background(PumColor.surfaceFill, in: RoundedRectangle(cornerRadius: PumTokens.Radius.md, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(state.lockAccessibility))
    }

    // MARK: 3. 정정 내용

    private var timeCard: some View {
        PumCard {
            timeRow(.start)
            Rectangle().fill(PumColor.borderHairline).frame(height: 1)
            timeRow(.end)
        }
    }

    private func timeRow(_ field: RecordCorrectionField) -> some View {
        let changed = field == .start ? state.startChanged : state.endChanged
        let label = field == .start ? "출근" : "퇴근"
        let before = field == .start ? state.originalStartText : state.originalEndText
        let after = field == .start ? state.startText : state.endText
        let key = Text(label).pumText(.callout, weight: changed ? .semibold : .regular)
            .foregroundStyle(changed ? PumColor.textPrimary : PumTokens.ColorToken.gray800)
        let value = Group {
            if changed {
                HStack(spacing: PumTokens.Space.s8) {
                    Text(before).pumText(.callout, weight: .regular).foregroundStyle(PumColor.textTertiary).strikethrough()
                    Image(systemName: "arrow.right").font(.footnote.weight(.semibold))
                        .foregroundStyle(PumColor.textSecondary).accessibilityHidden(true)
                    Text(after).pumText(.headline, weight: .bold).foregroundStyle(PumColor.accent)
                        .padding(.horizontal, PumTokens.Space.s12)
                        .padding(.vertical, PumTokens.Space.s4)
                        .background(PumColor.accentSoft, in: RoundedRectangle(cornerRadius: PumTokens.Radius.sm, style: .continuous))
                }
            } else {
                Text(after).pumText(.callout, weight: .semibold).foregroundStyle(PumColor.textTertiary)
            }
        }
        return Button { openPicker(field) } label: {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: PumTokens.Space.s12) { key.fixedSize(); Spacer(minLength: 0); value }
                VStack(alignment: .leading, spacing: PumTokens.Space.s8) { key; value }
            }
            .padding(.vertical, PumTokens.Size.rowPadY)
            .padding(.horizontal, PumTokens.Size.rowPadX)
            .frame(maxWidth: .infinity, minHeight: PumTokens.Size.tapMin, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(state.isSending)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(state.rowAccessibility(field)))
        .accessibilityAddTraits(.isButton)
        .accessibilityHint(Text("시각을 골라요"))
    }

    // MARK: 4. 사유

    private var reasonEditor: some View {
        TextEditor(text: $reason)
            // 200자 자르기는 값이 바뀐 뒤에 — 한글 조합 중 글자가 끊기지 않게(1i와 같은 규칙)
            .onChange(of: reason) { _, new in
                let clamped = RecordCorrectionState.clampedReason(new)
                if clamped != new { reason = clamped }
            }
            .focused($reasonFocused)
            .disabled(state.isSending)
            .pumText(.callout, weight: .regular)
            .foregroundStyle(PumTokens.ColorToken.gray800)
            .scrollContentBackground(.hidden)
            .padding(PumTokens.Space.s12)
            .frame(minHeight: reasonHeight)
            .background(PumColor.surfaceCard, in: RoundedRectangle(cornerRadius: PumTokens.Radius.md, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: PumTokens.Radius.md, style: .continuous)
                    .strokeBorder(reasonFocused ? PumColor.accent : PumColor.borderHairline,
                                  lineWidth: reasonFocused ? focusLine : restLine)
            }
            .accessibilityLabel(Text("정정 사유, 필수"))
    }

    // MARK: 5. 요청 출처

    private var sourceCard: some View {
        PumCard {
            Button(action: onOpenSource) {
                HStack(spacing: PumTokens.Space.s12) {
                    VStack(alignment: .leading, spacing: PumTokens.Space.s4) {
                        Text(state.sourceTitle).pumText(.callout, weight: .semibold).foregroundStyle(PumColor.textPrimary)
                        Text(state.sourceSubtitle).pumText(.caption).foregroundStyle(PumColor.textSecondary)
                    }
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.right").font(.footnote.weight(.semibold))
                        .foregroundStyle(PumColor.textDisabled).accessibilityHidden(true)
                }
                .padding(.vertical, PumTokens.Size.rowPadY)
                .padding(.horizontal, PumTokens.Size.rowPadX)
                .frame(maxWidth: .infinity, minHeight: PumTokens.Size.tapMin, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(state.sourceAccessibility))
            .accessibilityAddTraits(.isButton)
        }
    }
}

#Preview("10f · 캡처 상태") { RecordCorrectionView(state: .sample, reason: RecordCorrectionState.sampleReason) }
#Preview("10f · 큰 글자") {
    RecordCorrectionView(state: .sample, reason: RecordCorrectionState.sampleReason).dynamicTypeSize(.accessibility3)
}
