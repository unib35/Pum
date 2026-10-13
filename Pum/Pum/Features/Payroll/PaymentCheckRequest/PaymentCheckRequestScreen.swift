// UI-IOS-21d · REQ-076 · DEC-003 — 사장님 · 입금 확인 요청: 뒤 화면(「‹ 홈」 · 큰 제목) 위에 공통 바텀시트(C9).
// 캡처용 원문 상태: PaymentCheckRequestScreen(state: .sample)
import SwiftUI

struct PaymentCheckRequestScreen: View {
    var state: PaymentCheckRequestState = .sample
    var onBack: () -> Void = {}
    var onDismiss: () -> Void = {}
    /// 「보낸 게 맞아요」 실행. 결과를 done(성공 여부)로 알린다. 연결 전 기본값은 실패(done(false)).
    var onConfirmSent: (_ done: @escaping (Bool) -> Void) -> Void = { done in done(false) }
    /// 「지급 대기로」 — 21a 되돌리기 확인 시트를 연다. 이 화면에서 상태를 바꾸지 않는다(DEC-003).
    var onRevertToPending: () -> Void = {}

    @State private var sheetOpen: Bool
    @State private var lock = PaymentCheckConfirmLock()

    init(state: PaymentCheckRequestState = .sample, sheetOpen: Bool = true,
         onBack: @escaping () -> Void = {}, onDismiss: @escaping () -> Void = {},
         onConfirmSent: @escaping (_ done: @escaping (Bool) -> Void) -> Void = { done in done(false) },
         onRevertToPending: @escaping () -> Void = {}) {
        self.state = state
        self.onBack = onBack
        self.onDismiss = onDismiss
        self.onConfirmSent = onConfirmSent
        self.onRevertToPending = onRevertToPending
        _sheetOpen = State(initialValue: sheetOpen)
    }

    var body: some View {
        background
            .background(PumColor.bgApp)
            .pumBottomSheet(isPresented: guardedOpen, onDismiss: dismissed) {
                PaymentCheckRequestSheet(state: state, lock: $lock,
                                         onConfirmSent: onConfirmSent, onRevertToPending: onRevertToPending)
            }
    }

    /// 처리 중에는 막 누름 · 두 손가락 닫기로 닫히지 않게 한다
    private var guardedOpen: Binding<Bool> {
        Binding(get: { sheetOpen }, set: { newValue in
            if PaymentCheckRequestState.allowsSheetChange(to: newValue, isConfirming: lock.isConfirming) { sheetOpen = newValue }
        })
    }

    private func dismissed() {
        guard !lock.isConfirming else { return }
        onDismiss()
    }

    private var background: some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s14) {
            backLink
            Text("입금 확인 요청").pumText(.title2).foregroundStyle(PumColor.textPrimary) // 원문 26px 700 — title2(24)로 근사
                .accessibilityAddTraits(.isHeader)
                .padding(.top, PumTokens.Space.s6) // 원문 제목 위 2 + 4
                .padding(.horizontal, PumTokens.Space.s4)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, PumTokens.Size.screenPad)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    /// 공통 후보: 「‹ 홈」 텍스트 뒤로(원문 16px 600) — 공통 C6은 원형 아이콘 뒤로뿐
    private var backLink: some View {
        Button(action: onBack) {
            HStack(spacing: PumTokens.Space.s4) {
                Image(systemName: "chevron.left").font(.system(size: PumLayout.navIcon, weight: .semibold))
                    .accessibilityHidden(true)
                Text("홈").pumText(.headline)
            }
            .foregroundStyle(PumColor.textPrimary)
            .frame(minWidth: PumTokens.Size.tapMin, minHeight: PumTokens.Size.tapMin, alignment: .leading)
            .contentShape(Rectangle())
            .padding(.vertical, -PumTokens.Space.s2) // 원문 머리 줄 40(누름 영역은 44 유지)
        }
        .buttonStyle(.plain)
        .disabled(lock.isConfirming) // 알리는 동안 떠나지 않게
        .accessibilityLabel(Text("홈"))
    }
}

#Preview("21d") { PaymentCheckRequestScreen(state: .sample) }
#Preview("21d · 큰 글자") { PaymentCheckRequestScreen(state: .sample).dynamicTypeSize(.xxxLarge) }
