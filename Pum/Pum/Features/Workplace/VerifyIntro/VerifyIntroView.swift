// UI-IOS-5b · REQ-010 — 「직원 초대」를 눌렀을 때 뜨는 사업장 인증 안내 시트(사장님). 직원 초대 화면 위 시트.
// 막을 눌러도 닫힌다(= 나중에 할게요). 실제 인증 흐름은 후속(onStart).
import SwiftUI

struct VerifyIntroView: View {
    let state: VerifyIntroState
    @State private var sheetOpen: Bool
    var onBack: () -> Void
    var onStart: () -> Void
    var onLater: () -> Void

    @ScaledMetric(relativeTo: .body) private var qrBox = VerifyIntroLocal.qrBox

    init(state: VerifyIntroState = .sample, sheetOpen: Bool = true,
         onBack: @escaping () -> Void = {},
         onStart: @escaping () -> Void = {},
         onLater: @escaping () -> Void = {}) {
        self.state = state
        _sheetOpen = State(initialValue: sheetOpen)
        self.onBack = onBack
        self.onStart = onStart
        self.onLater = onLater
    }

    var body: some View {
        background
            .background(PumColor.bgApp)
            .pumBottomSheet(isPresented: $sheetOpen, onDismiss: onLater) {
                VerifyIntroSheet(state: state, onStart: onStart, onLater: later)
            }
    }

    private func later() {
        sheetOpen = false
        onLater()
    }

    /// 뒤 화면(시트에 덮여 어둡게): 머리 + QR 카드. 시트가 열리면 공통 C9가 VoiceOver에서 숨긴다.
    private var background: some View {
        VStack(spacing: PumTokens.Space.s16) {
            PumNavHeader(title: VerifyIntroState.screenTitle, onBack: onBack)
            PumCard {
                VStack(spacing: PumTokens.Space.s16) {
                    RoundedRectangle(cornerRadius: PumTokens.Radius.xl, style: .continuous)
                        .fill(PumColor.surfaceFill)
                        .frame(width: qrBox, height: qrBox)
                        .accessibilityHidden(true)
                    Text(state.qrCaption).pumText(.headline, weight: .bold) // 16px 700 → 17
                        .foregroundStyle(PumColor.textPrimary)
                }
                .padding(PumTokens.Space.s24)
                .frame(maxWidth: .infinity)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, PumTokens.Size.screenPad)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}

#Preview("5b") { VerifyIntroView() }
#Preview("5b · 큰 글자") { VerifyIntroView().dynamicTypeSize(.accessibility3) }
