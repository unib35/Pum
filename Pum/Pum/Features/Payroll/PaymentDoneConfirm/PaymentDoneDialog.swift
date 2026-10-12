// UI-IOS-7c · REQ-076 — C10 Confirm 가운데 다이얼로그. 공통 후보 — C10, 21a가 두 번째 사용처.
// 「지급 완료」는 한 번만 — 누르는 즉시 잠그고, 실패일 때만 푼다. 처리 중에는 취소 · 막 누름 · 두 손가락 닫기도 막는다.
// 색: 파랑 = 주 행동(지급 완료), 회색 = 취소. 시트가 아니므로 막 색만 C9과 같은 값을 쓴다.
import SwiftUI

struct PaymentDoneDialog: View {
    var state: PaymentDoneConfirmState = .sample
    var onCancel: () -> Void = {}
    /// 지급 완료 처리. 결과를 done(성공 여부)로 알린다. 연결 전 기본값은 실패(done(false)).
    var onConfirm: (_ done: @escaping (Bool) -> Void) -> Void = { done in done(false) }

    @State private var lock = WorkClosingLock() // 같은 의미(한 번만 · 실패일 때만 풀림)라 재사용
    @AccessibilityFocusState private var titleFocused: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shown = false

    /// 원문 다이얼로그 폭 약 290pt
    private static let maxWidth: CGFloat = 290
    private var isProcessing: Bool { lock.isClosing }

    var body: some View {
        ZStack {
            Button(action: dismiss) {
                PumColor.textPrimary.opacity(PumBottomSheetStyle.scrimOpacity) // C9과 같은 값
                    .ignoresSafeArea()
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityHidden(true) // 모달 — 닫기는 취소 버튼 · 두 손가락 문지르기

            GeometryReader { geo in
                ViewThatFits(in: .vertical) {
                    panel
                    ScrollView { panel }.scrollBounceBehavior(.basedOnSize)
                }
                .frame(maxWidth: Self.maxWidth)
                .frame(maxHeight: geo.size.height * 0.9)
                .padding(.horizontal, PumTokens.Size.screenPad)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .opacity(shown ? 1 : 0)
            .scaleEffect(shown || reduceMotion ? 1 : 0.96)
        }
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isModal)
        .accessibilityAction(.escape) { dismiss() }
        .onAppear {
            withAnimation(PumMotion.respecting(reduceMotion, PumMotion.base)) { shown = true }
            titleFocused = true
        }
    }

    // MARK: 판

    private var panel: some View {
        VStack(spacing: 0) {
            VStack(spacing: PumTokens.Space.s12) {
                Text(state.title).pumText(.headline, weight: .bold).foregroundStyle(PumColor.textPrimary)
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityFocused($titleFocused)
                infoBox
                Text(state.noticeLine1 + "\n" + state.noticeLine2)
                    .pumText(.footnote, weight: .regular).foregroundStyle(PumColor.textSecondary)
                    .multilineTextAlignment(.center)
                    .accessibilityLabel(Text(state.noticeSpoken))
            }
            .padding(.horizontal, PumTokens.Space.s18)
            .padding(.top, PumTokens.Space.s20)
            .padding(.bottom, PumTokens.Space.s16)
            Rectangle().fill(PumColor.borderHairline).frame(height: 1)
            HStack(spacing: 0) {
                actionButton(state.cancelTitle, weight: .regular, color: PumColor.textSecondary, action: cancel)
                Rectangle().fill(PumColor.borderHairline).frame(width: 1)
                actionButton(isProcessing ? state.processingTitle : state.confirmTitle,
                             weight: .bold, color: PumColor.accent, action: confirm)
            }
            .fixedSize(horizontal: false, vertical: true)
        }
        .background(PumColor.surfaceCard, in: RoundedRectangle(cornerRadius: PumTokens.Radius.xl, style: .continuous)) // 원문 흰 상자
        .clipShape(RoundedRectangle(cornerRadius: PumTokens.Radius.xl, style: .continuous))
        .pumFloatShadow()
    }

    private var infoBox: some View {
        VStack(spacing: PumTokens.Space.s6) {
            row(state.recipientKey, state.recipientName, spoken: state.recipientName)
            row(state.accountKey, state.maskedAccountText, spoken: state.accountSpoken)
            row(state.amountKey, state.amountText, spoken: state.amountText)
        }
        .padding(.horizontal, PumTokens.Space.s14)
        .padding(.vertical, PumTokens.Space.s12)
        .frame(maxWidth: .infinity)
        .background(PumColor.bgApp, in: RoundedRectangle(cornerRadius: PumTokens.Radius.md, style: .continuous)) // 원문 연회색 안쪽 상자
    }

    /// 키–값 행: 넓으면 한 줄, 좁으면(큰 글자) 값이 아래로. 행 하나가 한 덩어리로 읽힌다
    private func row(_ key: String, _ value: String, spoken: String) -> some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: PumTokens.Space.s8) {
                keyText(key)
                Spacer(minLength: 0)
                valueText(value).fixedSize()
            }
            VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                keyText(key)
                valueText(value)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("\(key), \(spoken)"))
    }

    private func keyText(_ s: String) -> some View {
        Text(s).pumText(.callout, weight: .regular).foregroundStyle(PumColor.textSecondary)
    }

    private func valueText(_ s: String) -> some View {
        Text(s).pumText(.callout, weight: .bold).foregroundStyle(PumColor.textPrimary)
    }

    private func actionButton(_ title: String, weight: Font.Weight, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title).pumText(.body, weight: weight).foregroundStyle(color)
                .multilineTextAlignment(.center)
                .padding(.horizontal, PumTokens.Space.s8)
                .frame(maxWidth: .infinity, minHeight: PumTokens.Size.tapMin, maxHeight: .infinity)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(isProcessing)
    }

    // MARK: 동작

    /// 한 번만 — 누르는 즉시 잠그고, 실패일 때만 푼다
    private func confirm() {
        guard lock.begin(canClose: true) else { return }
        onConfirm { success in lock.finish(success: success) }
    }

    private func cancel() {
        guard !isProcessing else { return }
        onCancel()
    }

    /// 막 누름 · 두 손가락 문지르기 — 취소와 같다(처리 중 제외)
    private func dismiss() {
        guard PaymentDoneConfirmState.allowsDismiss(isProcessing: isProcessing) else { return }
        onCancel()
    }
}

#Preview("7c 다이얼로그") { PaymentDoneDialog().background(PumColor.bgApp) }
