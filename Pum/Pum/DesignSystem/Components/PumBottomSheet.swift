// C9 Bottom Sheet — 화면 위에 아래에서 올라오는 시트(손잡이 · 뒤 막 · M3 · 동작 줄이기 · VoiceOver 닫기)
// 1j(대타 요청) · 1aa(서명 패드)에서 쓴다. 시트 높이는 내용만큼, 화면을 넘으면(큰 글자) 안에서 스크롤.
// 사용: someView.pumBottomSheet(isPresented: $open) { 내용 }
import SwiftUI

enum PumBottomSheetStyle {
    /// 뒤 막: 토큰에 scrim 색이 없다(충돌 #31) — 먹색(textPrimary) 35%, 1j 캡처 기준 추정
    static let scrimOpacity = 0.35
    /// 손잡이: 목업 약 36×5, gray300
    static let handleWidth: CGFloat = 40 // 원문 40(DEC-012)
    static let handleHeight: CGFloat = 5
    /// 시트가 차지할 수 있는 최대 높이 비율 — 위쪽은 뒤 화면이 보이게 남긴다
    static let maxHeightRatio: CGFloat = 0.9
}

extension View {
    /// C9 바텀시트. `onDismiss`는 막을 누르거나 VoiceOver로 닫을 때(두 손가락 문지르기) 불린다.
    func pumBottomSheet<Sheet: View>(
        isPresented: Binding<Bool>,
        onDismiss: @escaping () -> Void = {},
        @ViewBuilder content: @escaping () -> Sheet
    ) -> some View {
        modifier(PumBottomSheetModifier(isPresented: isPresented, onDismiss: onDismiss, sheet: content))
    }
}

private struct PumBottomSheetModifier<Sheet: View>: ViewModifier {
    @Binding var isPresented: Bool
    let onDismiss: () -> Void
    let sheet: () -> Sheet
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        ZStack(alignment: .bottom) {
            content
                .accessibilityHidden(isPresented) // 시트가 열리면 뒤 화면은 읽지 않는다
            if isPresented {
                Button(action: dismiss) {
                    PumColor.textPrimary.opacity(PumBottomSheetStyle.scrimOpacity)
                        .ignoresSafeArea()
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text("닫기"))
                .transition(.opacity)
                GeometryReader { geo in
                    VStack(spacing: 0) {
                        Spacer(minLength: geo.size.height * (1 - PumBottomSheetStyle.maxHeightRatio))
                        PumBottomSheetPanel(bottomInset: geo.safeAreaInsets.bottom, onDismiss: dismiss, content: sheet)
                    }
                    .ignoresSafeArea(.container, edges: .bottom)
                }
                // M22: 동작 줄이기면 올라오는 대신 페이드
                .transition(reduceMotion ? .opacity : .move(edge: .bottom))
            }
        }
        .animation(PumMotion.respecting(reduceMotion, PumMotion.sheet), value: isPresented) // M3
    }

    private func dismiss() {
        isPresented = false
        onDismiss()
    }
}

/// 시트 판: 손잡이 + 내용(짧으면 내용 높이, 넘치면 스크롤) + 위 모서리 xl · bgApp 바탕(홈 인디케이터까지)
struct PumBottomSheetPanel<Content: View>: View {
    var bottomInset: CGFloat = 0
    var onDismiss: () -> Void = {}
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(PumTokens.ColorToken.gray300)
                .frame(width: PumBottomSheetStyle.handleWidth, height: PumBottomSheetStyle.handleHeight)
                .padding(.top, PumTokens.Space.s10) // 원문 위 10 · 아래 16~18(DEC-012)
                .padding(.bottom, PumTokens.Space.s16)
                .accessibilityHidden(true)
            // 높이 상한은 부모가 준다 — 시트 전체에 maxHeight 프레임을 걸면 짧은 내용도 늘어난다
            ViewThatFits(in: .vertical) {
                content()
                ScrollView { content() }.scrollBounceBehavior(.basedOnSize)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, bottomInset)
        .background(
            UnevenRoundedRectangle(topLeadingRadius: PumTokens.Radius.xl, topTrailingRadius: PumTokens.Radius.xl, style: .continuous)
                .fill(PumColor.bgApp)
                .ignoresSafeArea(.container, edges: .bottom)
        )
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isModal)
        // 모달이라 뒤의 막(「닫기」)에 VoiceOver가 닿지 않는다 — 두 손가락 문지르기로 닫는다
        .accessibilityAction(.escape, onDismiss)
    }
}
