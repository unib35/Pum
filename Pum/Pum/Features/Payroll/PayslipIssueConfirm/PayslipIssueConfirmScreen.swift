// UI-IOS-10e · REQ-074 — 급여명세서 발행 확인: 10d를 뒤에 그대로 깔고 공통 바텀시트(C9)를 올린다.
// 캡처용 원문 상태: PayslipIssueConfirmScreen(state: .sample)
// 근사: 원문 뒤 화면은 직원 목록이 위에 오게 스크롤된 모양 — 10d는 고치지 않으므로 10d 기본 위치 그대로.
import SwiftUI

struct PayslipIssueConfirmScreen: View {
    var state: PayslipIssueConfirmState = .sample
    var onCancel: () -> Void = {}
    /// 발행 실행. 결과를 done(성공 여부)로 알린다. 연결 전 기본값은 실패(done(false)).
    var onIssue: (_ done: @escaping (Bool) -> Void) -> Void = { done in done(false) }

    @State private var sheetOpen: Bool
    @State private var lock = WorkClosingLock()

    init(state: PayslipIssueConfirmState = .sample, sheetOpen: Bool = true,
         onCancel: @escaping () -> Void = {},
         onIssue: @escaping (_ done: @escaping (Bool) -> Void) -> Void = { done in done(false) }) {
        self.state = state
        self.onCancel = onCancel
        self.onIssue = onIssue
        _sheetOpen = State(initialValue: sheetOpen)
    }

    var body: some View {
        PayslipIssueView(state: state.background)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
            .pumBottomSheet(isPresented: guardedOpen, onDismiss: dismissed) {
                PayslipIssueConfirmSheet(state: state, lock: $lock, onCancel: cancel, onIssue: onIssue)
            }
    }

    /// 처리 중에는 막 누름 · 두 손가락 닫기로 닫히지 않게 한다
    private var guardedOpen: Binding<Bool> {
        Binding(get: { sheetOpen }, set: { newValue in
            if PayslipIssueConfirmState.allowsSheetChange(to: newValue, isIssuing: lock.isClosing) { sheetOpen = newValue }
        })
    }

    private func dismissed() {
        guard !lock.isClosing else { return }
        onCancel()
    }

    private func cancel() {
        guard !lock.isClosing else { return }
        sheetOpen = false
        onCancel()
    }
}

#Preview("10e") { PayslipIssueConfirmScreen(state: .sample) }
#Preview("10e · 큰 글자") { PayslipIssueConfirmScreen(state: .sample).dynamicTypeSize(.xxxLarge) }
