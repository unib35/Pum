// UI-IOS-7c · REQ-076 — 지급 완료 확인 화면(캡처 · 미리보기 호스트): 7a 위에 막 + 다이얼로그.
// 원문 뒤 화면은 대기 목록만 보이지만, 실제 흐름처럼 7a 전체를 뒤에 둔다.
import SwiftUI

struct PaymentDoneConfirmScreen: View {
    var state: PaymentDoneConfirmState = .sample
    var onCancel: () -> Void = {}
    var onConfirm: (_ done: @escaping (Bool) -> Void) -> Void = { done in done(false) }

    var body: some View {
        ZStack {
            PaymentChecklistView(state: .sample)
                .accessibilityHidden(true) // 다이얼로그가 열리면 뒤 화면은 읽지 않는다
            PaymentDoneDialog(state: state, onCancel: onCancel, onConfirm: onConfirm)
        }
        .background(PumColor.bgApp)
    }
}

#Preview("7c") { PaymentDoneConfirmScreen(state: .sample) }
#Preview("7c · 큰 글자") { PaymentDoneConfirmScreen(state: .sample).dynamicTypeSize(.xxxLarge) }
