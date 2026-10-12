// UI-IOS-10j · REQ-042 — 직원 근무 변경 요청 (하위 화면, 탭 바 없음). 보내기 버튼은 하단 고정(키보드가 떠도 보인다).
// 「반영되면」은 엔진(서버) 값 — 시간을 바꾸면 onTimesChanged로 부모에 알리고, 결과(basis 포함)가 지금 시간과 같을 때만 보인다.
// 보내기는 한 번만 — 누르는 즉시 잠그고 실패일 때만 푼다. 처리 중에는 스테퍼 · 입력 · 닫기도 잠근다.
import SwiftUI

struct ShiftChangeRequestView: View {
    var state: ShiftChangeRequestState = .sample
    var onClose: () -> Void = {}
    /// 바꾼 출근 · 퇴근(분)을 부모에 알린다 — 부모가 엔진에 물어 state.preview(basis 포함)를 갱신한다
    var onTimesChanged: (_ start: Int, _ end: Int) -> Void = { _, _ in }
    /// 보내기. 결과를 done(성공 여부)으로 알린다. 연결 전 기본값은 실패(done(false)).
    var onSend: (_ request: ShiftChangeRequest, _ done: @escaping (Bool) -> Void) -> Void = { _, done in done(false) }

    @State private var draft: ShiftChangeDraft
    @State private var lock = ShiftChangeLock()
    @FocusState private var reasonFocused: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .body) private var stepperHeight: CGFloat = 36

    /// `start` · `end` · `reason`은 캡처용 초기값(원문 18:00 · 23:00 · 「수요일 수업이 18시에 끝나요」). 없으면 지금 근무 그대로
    init(state: ShiftChangeRequestState = .sample, start: Int? = nil, end: Int? = nil, reason: String = "",
         onClose: @escaping () -> Void = {},
         onTimesChanged: @escaping (_ start: Int, _ end: Int) -> Void = { _, _ in },
         onSend: @escaping (_ request: ShiftChangeRequest, _ done: @escaping (Bool) -> Void) -> Void = { _, done in done(false) }) {
        self.state = state
        self.onClose = onClose
        self.onTimesChanged = onTimesChanged
        self.onSend = onSend
        _draft = State(initialValue: ShiftChangeDraft(start: start ?? state.startMinutes, end: end ?? state.endMinutes, reason: reason))
    }

    // 화면 전용 상수 (DEC-005: 목업 px → 가까운 토큰 단계)
    /// 사유 입력칸 최소 높이 — 디자인 캡처 약 82
    private let reasonHeight: CGFloat = 82
    /// 포커스 테두리 — 10i · 1i와 같게 2
    private let focusLine: CGFloat = 2
    private let restLine: CGFloat = 1

    private var isSending: Bool { lock.isSending }
    private var previewText: String? { draft.previewText(for: state) }

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                VStack(alignment: .leading, spacing: PumTokens.Space.s16) {
                    section(ShiftChangeRequestState.currentHeader) { currentCard }
                    section(ShiftChangeRequestState.changeHeader) { changeCard }
                    if let previewText { previewBox(previewText) }
                    section(ShiftChangeRequestState.reasonHeader) { reasonField }
                }
                .padding(.horizontal, PumTokens.Size.screenPad)
                .padding(.vertical, PumTokens.Space.s12)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .background(PumColor.bgApp)
        .safeAreaInset(edge: .bottom, spacing: 0) { footer }
        .animation(PumMotion.respecting(reduceMotion, PumMotion.fast), value: previewText)
    }

    // MARK: 머리 · 바닥

    private var header: some View {
        ZStack {
            Text(ShiftChangeRequestState.headerTitle).pumText(.headline).foregroundStyle(PumColor.textPrimary)
                .lineLimit(1).padding(.horizontal, PumTokens.Size.tapMin + PumTokens.Space.s8)
                .accessibilityAddTraits(.isHeader)
            HStack {
                PumIconButton(systemImage: "xmark", label: "닫기", action: close)
                    .disabled(isSending)
                Spacer()
            }
        }
        .padding(.top, PumTokens.Space.s8)
        .padding(.horizontal, PumTokens.Size.screenPad)
    }

    private var footer: some View {
        PumButton(title: ShiftChangeRequestState.sendTitle, kind: .primary, isLoading: isSending,
                  loadingTitle: ShiftChangeRequestState.sendingTitle, action: send)
            .disabled(!draft.canSend(for: state))
            .padding(.horizontal, PumTokens.Size.screenPad)
            .padding(.vertical, PumTokens.Space.s12)
            .background(PumColor.bgApp)
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s8) {
            PumSectionHeader(title: title)
            content()
        }
    }

    // MARK: 카드

    /// 날짜 · 사업장 왼쪽, 시간 오른쪽. 글자가 크면 시간이 아래로 내려간다
    private var currentCard: some View {
        PumCard {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .center, spacing: PumTokens.Space.s12) { currentTitles; Spacer(minLength: 0); currentTime }
                VStack(alignment: .leading, spacing: PumTokens.Space.s8) { currentTitles; currentTime }
            }
            .padding(.horizontal, PumTokens.Size.rowPadX)
            .padding(.vertical, PumTokens.Space.s12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(state.shiftAccessibility))
        }
    }

    private var currentTitles: some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
            // 목업 15px 600 → callout semibold
            Text(state.dateTitle).pumText(.callout, weight: .semibold).foregroundStyle(PumColor.textPrimary)
            Text(state.workplaceName).pumText(.caption).foregroundStyle(PumColor.textSecondary)
        }
    }

    private var currentTime: some View {
        Text(state.currentRangeText).pumText(.callout, weight: .semibold).foregroundStyle(PumColor.textPrimary)
            .lineLimit(1).fixedSize(horizontal: true, vertical: false)
    }

    private var changeCard: some View {
        PumCard {
            timeRow(.start, minutes: draft.start)
            // hairline은 카드 끝까지(원문)
            Rectangle().fill(PumColor.borderHairline).frame(height: 1)
            timeRow(.end, minutes: draft.end)
        }
    }

    /// 라벨 왼쪽 · 스테퍼 오른쪽. 큰 글자에서 한 줄에 안 들어가면 스테퍼가 아래로 내려간다
    private func timeRow(_ edge: ShiftChangeEdge, minutes: Int) -> some View {
        let label = Text(ShiftChangeRequestState.rowAccessibilityLabel(edge)).pumText(.callout, weight: .semibold)
            .foregroundStyle(PumColor.textPrimary)
        return ViewThatFits(in: .horizontal) {
            HStack(spacing: PumTokens.Space.s12) { label.fixedSize(); Spacer(minLength: 0); stepper(edge, minutes: minutes) }
            VStack(alignment: .leading, spacing: PumTokens.Space.s8) { label; stepper(edge, minutes: minutes) }
        }
        .padding(.vertical, PumTokens.Space.s10)
        .padding(.horizontal, PumTokens.Size.rowPadX)
        .frame(maxWidth: .infinity, minHeight: PumTokens.Size.tapMin, alignment: .leading)
    }

    // MARK: 스테퍼 — 9a와 같은 모양(공통 후보: 스테퍼가 공통에 없어 화면 전용)

    private func stepper(_ edge: ShiftChangeEdge, minutes: Int) -> some View {
        HStack(spacing: 0) {
            stepButton("minus", enabled: draft.canMove(edge, by: -1) && !isSending) { step(edge, by: -1) }
            // 목업 16px 700 → body bold(9a와 같게)
            Text(ShiftChangeRequestState.clock(minutes)).pumText(.body, weight: .bold).foregroundStyle(PumColor.textPrimary)
                .lineLimit(1).fixedSize()
            stepButton("plus", enabled: draft.canMove(edge, by: 1) && !isSending) { step(edge, by: 1) }
        }
        .frame(minHeight: stepperHeight)
        .background(PumColor.surfaceFill, in: RoundedRectangle(cornerRadius: PumTokens.Radius.md, style: .continuous))
        // 「출근, 18시」 — 위아래로 쓸어 30분씩 조정
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(ShiftChangeRequestState.rowAccessibilityLabel(edge)))
        .accessibilityValue(Text(ShiftChangeRequestState.spokenClock(minutes)))
        .accessibilityAction(named: Text("30분 늦추기")) { step(edge, by: 1) }
        .accessibilityAction(named: Text("30분 당기기")) { step(edge, by: -1) }
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: step(edge, by: 1)
            case .decrement: step(edge, by: -1)
            @unknown default: break
            }
        }
    }

    /// 누름 영역은 가로 · 세로 44pt — 알약 높이는 그대로 두고 세로 여백만 바깥으로 낸다
    private func stepButton(_ symbol: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol).font(.system(size: PumLayout.navIcon, weight: .regular))
                .foregroundStyle(enabled ? PumTokens.ColorToken.gray700 : PumColor.textDisabled)
                .frame(width: PumTokens.Size.tapMin, height: PumTokens.Size.tapMin)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .frame(height: stepperHeight)
    }

    // MARK: 반영되면 · 사유

    /// 1i와 같은 회색 바탕 상자. 좁거나 글자가 크면 라벨 아래로 값이 내려간다
    private func previewBox(_ text: String) -> some View {
        let label = Text(ShiftChangeRequestState.previewLabel).pumText(.footnote).foregroundStyle(PumColor.textSecondary)
        let value = Text(text).pumText(.footnote, weight: .semibold).foregroundStyle(PumColor.textPrimary)
            .multilineTextAlignment(.trailing)
        return ViewThatFits(in: .horizontal) {
            HStack(spacing: PumTokens.Space.s12) { label; Spacer(minLength: 0); value }
            VStack(alignment: .leading, spacing: PumTokens.Space.s4) { label; value }
        }
        .padding(PumTokens.Space.s12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(PumColor.surfaceFill, in: RoundedRectangle(cornerRadius: PumTokens.Radius.md, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    private var reasonField: some View {
        TextEditor(text: $draft.reason)
            // 글자 수 제한은 값이 바뀐 뒤에 자른다 — 10i와 같게(한글 조합 중 끊김 방지)
            .onChange(of: draft.reason) { _, new in
                let clamped = ShiftChangeRequestState.clampedReason(new)
                if clamped != new { draft.reason = clamped }
            }
            .focused($reasonFocused)
            .disabled(isSending)
            .pumText(.body, weight: .regular)
            .foregroundStyle(PumColor.textPrimary)
            .scrollContentBackground(.hidden)
            .padding(PumTokens.Space.s12)
            .frame(minHeight: reasonHeight)
            .background(PumColor.surfaceCard, in: RoundedRectangle(cornerRadius: PumTokens.Radius.md, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: PumTokens.Radius.md, style: .continuous)
                    .strokeBorder(reasonFocused ? PumColor.accent : PumColor.borderHairline,
                                  lineWidth: reasonFocused ? focusLine : restLine)
            }
            .accessibilityLabel(Text(ShiftChangeRequestState.reasonHeader))
    }

    // MARK: 동작

    private func step(_ edge: ShiftChangeEdge, by direction: Int) {
        guard !isSending, draft.move(edge, by: direction) else { return }
        onTimesChanged(draft.start, draft.end)
    }

    private func close() {
        guard !isSending else { return }
        onClose()
    }

    /// 한 번만 — 누르는 즉시 잠그고, 실패일 때만 푼다
    private func send() {
        guard draft.canSend(for: state), lock.begin() else { return }
        reasonFocused = false
        onSend(draft.request(for: state)) { success in lock.finish(success: success) }
    }
}

#Preview("10j") { ShiftChangeRequestView(state: .sample, start: 18 * 60, end: 23 * 60, reason: "수요일 수업이 18시에 끝나요") }
#Preview("10j · 큰 글자") {
    ShiftChangeRequestView(state: .sample, start: 18 * 60, end: 23 * 60, reason: "수요일 수업이 18시에 끝나요").dynamicTypeSize(.xxxLarge)
}
