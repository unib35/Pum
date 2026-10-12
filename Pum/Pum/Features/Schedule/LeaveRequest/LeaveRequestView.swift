// UI-IOS-10i · REQ-042 — 직원 휴무 신청 (하위 화면, 탭 바 없음). 보내기 버튼은 하단 고정(키보드가 떠도 보인다).
// 보내기는 한 번만 — 누르는 즉시 잠그고 실패일 때만 푼다. 처리 중에는 입력 · 토글 · 닫기도 잠근다.
// 근무 고르기 화면 원문이 없어 「변경」은 클로저만 호출한다.
import SwiftUI

struct LeaveRequestView: View {
    var state: LeaveRequestState = .sample
    var onClose: () -> Void = {}
    var onChangeShift: () -> Void = {}
    /// 보내기. 결과를 done(성공 여부)으로 알린다. 연결 전 기본값은 실패(done(false)).
    var onSend: (_ request: LeaveRequest, _ done: @escaping (Bool) -> Void) -> Void = { _, done in done(false) }

    @State private var draft: LeaveRequestDraft
    @State private var lock = LeaveRequestLock()
    @FocusState private var reasonFocused: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// `reason`은 캡처용 초기 사유(원문 「병원 예약이 있어요」)
    init(state: LeaveRequestState = .sample, reason: String = "",
         onClose: @escaping () -> Void = {}, onChangeShift: @escaping () -> Void = {},
         onSend: @escaping (_ request: LeaveRequest, _ done: @escaping (Bool) -> Void) -> Void = { _, done in done(false) }) {
        self.state = state
        self.onClose = onClose
        self.onChangeShift = onChangeShift
        self.onSend = onSend
        _draft = State(initialValue: LeaveRequestDraft(reason: reason))
    }

    // 화면 전용 상수 (DEC-005: 목업 px → 가까운 토큰 단계)
    /// 사유 입력칸 최소 높이 — 디자인 캡처 약 82
    private let reasonHeight: CGFloat = 82
    /// 포커스 테두리 — 1i와 같게 2
    private let focusLine: CGFloat = 2
    private let restLine: CGFloat = 1

    private var isSending: Bool { lock.isSending }

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                VStack(alignment: .leading, spacing: PumTokens.Space.s16) {
                    shiftCard
                    section(LeaveRequestState.methodHeader) { methodCard }
                    substituteCard
                    section(LeaveRequestState.reasonHeader) { reasonField }
                }
                .padding(.horizontal, PumTokens.Size.screenPad)
                .padding(.vertical, PumTokens.Space.s12)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .background(PumColor.bgApp)
        .safeAreaInset(edge: .bottom, spacing: 0) { footer }
        .animation(PumMotion.respecting(reduceMotion, PumMotion.fast), value: draft.method)
        .animation(PumMotion.respecting(reduceMotion, PumMotion.fast), value: draft.withSubstitute)
    }

    // MARK: 머리 · 바닥

    /// 1i처럼 닫기(✕) — 왼쪽 원형 버튼 · 가운데 제목
    private var header: some View {
        ZStack {
            Text(LeaveRequestState.headerTitle).pumText(.headline).foregroundStyle(PumColor.textPrimary)
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
        VStack(spacing: PumTokens.Space.s8) {
            PumButton(title: LeaveRequestState.sendTitle, kind: .primary, isLoading: isSending,
                      loadingTitle: LeaveRequestState.sendingTitle, action: send)
            Text(LeaveRequestState.notice).pumText(.caption).foregroundStyle(PumColor.textTertiary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
        }
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

    private var shiftCard: some View {
        PumCard {
            HStack(alignment: .center, spacing: PumTokens.Space.s12) {
                VStack(alignment: .leading, spacing: PumTokens.Space.s4) {
                    Text(LeaveRequestState.shiftLabel).pumText(.caption).foregroundStyle(PumColor.textSecondary)
                    // 목업 19px 700 → title3(20)
                    Text(state.shiftTitle).pumText(.title3, weight: .bold).foregroundStyle(PumColor.textPrimary)
                    Text(state.shiftSubtitle).pumText(.caption).foregroundStyle(PumColor.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text(state.shiftAccessibility))
                Button(action: onChangeShift) {
                    // 목업 13px 600 → footnote semibold
                    Text(LeaveRequestState.changeTitle).pumText(.footnote, weight: .semibold).foregroundStyle(PumColor.accent)
                        .frame(minWidth: PumTokens.Size.tapMin, minHeight: PumTokens.Size.tapMin)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(isSending)
                .accessibilityLabel(Text("쉬려는 근무 변경"))
            }
            .padding(.horizontal, PumTokens.Size.rowPadX)
            .padding(.vertical, PumTokens.Space.s12)
        }
    }

    private var methodCard: some View {
        PumCard {
            ForEach(Array(state.methods.enumerated()), id: \.element.id) { index, option in
                methodRow(option)
                    .overlay(alignment: .bottom) {
                        if index < state.methods.count - 1 {
                            Rectangle().fill(PumColor.borderHairline).frame(height: 1)
                                .padding(.horizontal, PumTokens.Size.rowPadX)
                        }
                    }
            }
        }
    }

    /// 공통 후보: 제목 + 설명 두 줄 라디오 행 (PumRadioRow는 한 줄)
    private func methodRow(_ option: LeaveMethodOption) -> some View {
        let isOn = draft.method == option.method
        return Button {
            guard !isSending else { return }
            draft.select(option)
        } label: {
            HStack(spacing: PumTokens.Space.s12) {
                PumRadioMark(isOn: isOn)
                VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                    // 목업 15px 600 → callout semibold
                    Text(option.title).pumText(.callout, weight: .semibold).foregroundStyle(PumColor.textPrimary)
                    Text(option.detail).pumText(.caption).foregroundStyle(PumColor.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, PumTokens.Size.rowPadX)
            .padding(.vertical, PumTokens.Size.rowPadY)
            .frame(minHeight: PumTokens.Size.tapMin)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        // 서버가 고를 수 없다고 준 방식 · 보내는 중엔 누를 수 없고 흐리게(8b 잠긴 알약과 같은 값)
        .disabled(!option.isSelectable || isSending)
        .opacity(option.isSelectable ? 1 : 0.5)
        .accessibilityElement(children: .ignore)
        // 「선택됨」이 라벨에 있어 isSelected 특성은 붙이지 않는다(두 번 읽힘)
        .accessibilityLabel(Text(LeaveRequestState.optionAccessibility(option, isOn: isOn)))
        .accessibilityAddTraits(.isButton)
    }

    private var substituteCard: some View {
        PumCard {
            Toggle(isOn: $draft.withSubstitute) {
                VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                    Text(LeaveRequestState.substituteTitle).pumText(.callout, weight: .semibold).foregroundStyle(PumColor.textPrimary)
                    Text(state.colleaguesText).pumText(.caption).foregroundStyle(PumColor.textSecondary)
                }
            }
            .tint(PumColor.accent)
            .disabled(isSending)
            .padding(.horizontal, PumTokens.Size.rowPadX)
            .padding(.vertical, PumTokens.Space.s10)
            .frame(minHeight: PumTokens.Size.tapMin)
        }
        // 시스템 Toggle이 스위치로 읽힌다(제목 · 동료 수 · 켬/끔)
    }

    private var reasonField: some View {
        TextEditor(text: $draft.reason)
            // 글자 수 제한은 값이 바뀐 뒤에 자른다 — 1i와 같게(한글 조합 중 끊김 방지)
            .onChange(of: draft.reason) { _, new in
                let clamped = LeaveRequestState.clampedReason(new)
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
            .accessibilityLabel(Text(LeaveRequestState.reasonHeader))
    }

    // MARK: 동작

    private func close() {
        guard !isSending else { return }
        onClose()
    }

    /// 한 번만 — 누르는 즉시 잠그고, 실패일 때만 푼다
    private func send() {
        guard lock.begin() else { return }
        reasonFocused = false
        onSend(draft.request(for: state)) { success in lock.finish(success: success) }
    }
}

#Preview("10i") { LeaveRequestView(reason: "병원 예약이 있어요") }
#Preview("10i · 큰 글자") { LeaveRequestView(reason: "병원 예약이 있어요").dynamicTypeSize(.xxxLarge) }
