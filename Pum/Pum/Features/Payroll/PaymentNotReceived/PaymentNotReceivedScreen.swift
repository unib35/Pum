// UI-IOS-21c · REQ-076 — 직원 「아직 입금 안 됐어요」: 지급 완료 명세서(뒤 화면) 위에 공통 바텀시트(C9).
// 지급 완료 상태 명세서에서만 열린다(isPaidOut). 보내기는 한 번만 — 처리 중에는 입력 · 취소 · 막 닫기도 잠근다.
// 색: 초록 = 지급 완료 배지 · 파랑 = 선택 점 · 주 버튼. 메모 · 계좌는 로그에 남기지 않는다.
import SwiftUI

struct PaymentNotReceivedScreen: View {
    var state: PaymentNotReceivedState = .sample
    var onBack: () -> Void = {}
    var onCancel: () -> Void = {}
    /// 보내기. 결과를 done(성공 여부)로 알린다. 연결 전 기본값은 실패(done(false)).
    var onSend: (_ reasonId: String, _ memo: String?, _ done: @escaping (Bool) -> Void) -> Void = { _, _, done in done(false) }

    @State private var sheetOpen: Bool
    @State private var draft: PaymentNotReceivedDraft
    @State private var lock = PaymentNotReceivedLock()

    /// `memo`는 캡처용 초기 메모(원문 「국민은행 앱에서 확인했어요」). 첫 사유가 미리 선택된다.
    init(state: PaymentNotReceivedState = .sample, sheetOpen: Bool = true, memo: String = "",
         onBack: @escaping () -> Void = {}, onCancel: @escaping () -> Void = {},
         onSend: @escaping (_ reasonId: String, _ memo: String?, _ done: @escaping (Bool) -> Void) -> Void = { _, _, done in done(false) }) {
        self.state = state
        self.onBack = onBack
        self.onCancel = onCancel
        self.onSend = onSend
        _sheetOpen = State(initialValue: sheetOpen)
        _draft = State(initialValue: PaymentNotReceivedDraft(reasonId: state.defaultReasonId, memo: memo))
    }

    private var isSending: Bool { lock.isSending }

    var body: some View {
        background
            .background(PumColor.bgApp)
            .pumBottomSheet(isPresented: guardedOpen, onDismiss: dismissed) {
                PaymentNotReceivedSheet(state: state, draft: $draft, isSending: isSending, onCancel: cancel, onSend: send)
            }
    }

    /// 지급 완료가 아니면 열리지 않고, 보내는 중에는 막 누름 · 두 손가락 닫기로 닫히지 않는다
    private var guardedOpen: Binding<Bool> {
        Binding(get: { sheetOpen && PaymentNotReceivedState.canOpenSheet(isPaidOut: state.isPaidOut) },
                set: { newValue in
            if PaymentNotReceivedState.allowsSheetChange(to: newValue, isSending: isSending) { sheetOpen = newValue }
        })
    }

    private func dismissed() {
        guard !isSending else { return }
        onCancel()
    }

    // MARK: 뒤 화면

    private var background: some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s16) {
            backButton
            VStack(alignment: .leading, spacing: PumTokens.Space.s4) {
                Text(state.summaryText).pumText(.footnote, weight: .medium).foregroundStyle(PumColor.textSecondary)
                Text(state.netPayText).pumText(.title1).foregroundStyle(PumColor.textPrimary) // 원문 26px 700 → title1 28
                Text("실지급액").pumText(.footnote, weight: .regular).foregroundStyle(PumColor.textSecondary)
            }
            .accessibilityElement(children: .combine)
            paidCard
            Spacer(minLength: 0)
        }
        .padding(.horizontal, PumTokens.Size.screenPad)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    /// 공통 후보: 글자 뒤로(‹ 급여) — C6은 원형 아이콘 버튼
    private var backButton: some View {
        Button(action: onBack) {
            HStack(spacing: PumTokens.Space.s4) {
                Image(systemName: "chevron.left").pumText(.headline, weight: .semibold)
                Text("급여").pumText(.headline)
            }
            .foregroundStyle(PumColor.textPrimary)
            .frame(minWidth: PumTokens.Size.tapMin, minHeight: PumTokens.Size.tapMin, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(isSending) // 보내는 동안 떠나지 않게
        .padding(.top, PumTokens.Space.s8)
        .accessibilityLabel(Text("급여, 뒤로"))
    }

    private var paidCard: some View {
        PumCard {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: PumTokens.Space.s12) { paidTexts; PumBadge(text: "지급 완료", kind: .done).fixedSize() }
                VStack(alignment: .leading, spacing: PumTokens.Space.s8) {
                    paidTexts
                    PumBadge(text: "지급 완료", kind: .done).fixedSize()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(PumTokens.Space.s16)
            .frame(minHeight: PumTokens.Size.tapMin)
        }
        .accessibilityElement(children: .combine)
    }

    private var paidTexts: some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
            Text(state.paidTitle).pumText(.callout, weight: .semibold).foregroundStyle(PumColor.textPrimary)
            Text(state.paidDetail).pumText(.caption, weight: .regular).foregroundStyle(PumColor.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: 동작

    /// 한 번만 — 누르는 즉시 잠그고, 실패일 때만 푼다
    private func send() {
        guard let id = draft.reasonId, lock.begin(canSend: draft.canSend) else { return }
        onSend(id, draft.memoToSend) { success in lock.finish(success: success) }
    }

    private func cancel() {
        guard !isSending else { return }
        sheetOpen = false
        onCancel()
    }
}

#Preview("21c") { PaymentNotReceivedScreen(state: .sample, memo: "국민은행 앱에서 확인했어요") }
#Preview("21c · 큰 글자") { PaymentNotReceivedScreen(state: .sample, memo: "국민은행 앱에서 확인했어요").dynamicTypeSize(.xxxLarge) }
