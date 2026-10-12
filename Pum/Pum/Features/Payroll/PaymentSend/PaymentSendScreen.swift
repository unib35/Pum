// UI-IOS-7b · 21e · 21f — 캡처 · 미리보기용 호스트. 7a 지급 체크리스트 위에 지급 시트(C9)를 연 상태.
// (원문 뒤 화면은 대기 목록만 보이지만, 실제 흐름처럼 7a 위에 띄운다.) 7a 연결 · 화면 등록은 하지 않는다.
// 21f(Face ID 확인)는 iOS 시스템 화면이라 그리지 않는다 — onReveal(done)을 부모가 채운다.
import SwiftUI

struct PaymentSendScreen: View {
    /// Face ID(LocalAuthentication) + 서버 조회는 부모가 한다. 전체 번호를 done으로 넘기고, 실패 · 취소면 nil.
    var onReveal: (_ done: @escaping (String?) -> Void) -> Void = { done in done(nil) }
    var onMarkPaid: () -> Void = {}   // 7c 확인 다이얼로그를 여는 클로저
    var onClose: () -> Void = {}

    @State private var model: PaymentSendModel
    @State private var sheetOpen: Bool
    @Environment(\.scenePhase) private var scenePhase

    init(state: PaymentSendState = .sample, sheetOpen: Bool = true,
         onReveal: @escaping (_ done: @escaping (String?) -> Void) -> Void = { done in done(nil) },
         onMarkPaid: @escaping () -> Void = {}, onClose: @escaping () -> Void = {}) {
        self.onReveal = onReveal
        self.onMarkPaid = onMarkPaid
        self.onClose = onClose
        _model = State(initialValue: PaymentSendModel(state: state))
        _sheetOpen = State(initialValue: sheetOpen)
    }

    var body: some View {
        PaymentChecklistView(state: .sample)
            .background(PumColor.bgApp)
            .pumBottomSheet(isPresented: $sheetOpen, onDismiss: closed) {
                PaymentSendSheet(model: model, onReveal: onReveal, onMarkPaid: onMarkPaid)
            }
            // 감시는 호스트에서 한 번만(시트 내용은 여러 번 만들어질 수 있다)
            .onChange(of: scenePhase) { _, phase in model.scenePhaseChanged(phase) }
            .onChange(of: sheetOpen) { _, open in if !open { model.mask() } } // 어떤 경로로 닫혀도 지움
    }

    private func closed() {
        model.mask() // 닫으면 전체 번호를 지운다
        onClose()
    }
}

#Preview("7b") { PaymentSendScreen(state: .sample) }
#Preview("21e") { PaymentSendScreen(state: .masked) }
#Preview("21e · Face ID 성공") {
    PaymentSendScreen(state: .masked, onReveal: { done in done("123456-78-901234") })
}
#Preview("7b · 큰 글자") { PaymentSendScreen(state: .sample).dynamicTypeSize(.xxxLarge) }
#Preview("21e · 큰 글자") { PaymentSendScreen(state: .masked).dynamicTypeSize(.xxxLarge) }
