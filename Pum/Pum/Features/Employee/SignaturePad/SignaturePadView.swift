// UI-IOS-1aa · REQ-060 — 서명 패드: 뒤 화면(근로계약서) + 공통 바텀시트(C9)
// 서명 완료 · 본인인증 · PDF 교부 · 서버 저장은 연결 후속 — 클로저로만 넘긴다.
import SwiftUI

struct SignaturePadView: View {
    var onBack: () -> Void = {}
    var onComplete: ([SignatureStroke]) -> Void = { _ in }
    var onDismissSheet: () -> Void = {}

    @State private var sheetOpen: Bool
    @State private var drawing: SignatureDrawing

    /// 실제 진입은 빈 서명 — 예시 획(`.sample`)은 비교 캡처 · 프리뷰에서만
    init(drawing: SignatureDrawing = SignatureDrawing(), sheetOpen: Bool = true,
         onBack: @escaping () -> Void = {},
         onComplete: @escaping ([SignatureStroke]) -> Void = { _ in },
         onDismissSheet: @escaping () -> Void = {}) {
        _drawing = State(initialValue: drawing)
        _sheetOpen = State(initialValue: sheetOpen)
        self.onBack = onBack
        self.onComplete = onComplete
        self.onDismissSheet = onDismissSheet
    }

    var body: some View {
        backScreen
            .pumBottomSheet(isPresented: $sheetOpen, onDismiss: onDismissSheet) { sheet }
    }

    // MARK: 뒤 화면

    private var backScreen: some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s14) {
            PumNavHeader(title: SignaturePadContent.backTitle, onBack: onBack)
            // 목업 24px 700 → title2 bold
            Text(SignaturePadContent.contractTitle).pumText(.title2, weight: .bold)
                .foregroundStyle(PumColor.textPrimary)
                .accessibilityAddTraits(.isHeader)
            // 원문: 카드 안쪽 위 6 · 아래 4, 줄 위아래 11, 구분선은 안쪽 18에서 시작.
            // 공통 PumRow는 안쪽 16 · 줄 12 · 최소 44라 화면 안에서 같은 모양으로 만든다
            PumCard {
                VStack(spacing: 0) {
                    termRow(SignaturePadContent.periodLabel, SignaturePadContent.period, isLast: false)
                    termRow(SignaturePadContent.wageLabel, SignaturePadContent.wage, isLast: true)
                }
                .padding(.top, PumTokens.Space.s6)
                .padding(.bottom, PumTokens.Space.s4)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, PumTokens.Size.screenPad)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(PumColor.bgApp)
    }

    // MARK: 시트

    private var sheet: some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s12) {
            HStack(alignment: .firstTextBaseline, spacing: PumTokens.Space.s8) {
                Text(SignaturePadContent.sheetTitle).pumText(.title3, weight: .bold) // 목업 20px 700
                    .foregroundStyle(PumColor.textPrimary)
                    .accessibilityAddTraits(.isHeader)
                Spacer(minLength: PumTokens.Space.s8)
                Text(SignaturePadContent.signer).pumText(.footnote) // 목업 13px 400
                    .foregroundStyle(PumColor.textSecondary)
            }
            SignatureCanvasView(drawing: $drawing)
            Text(SignaturePadContent.notice).pumText(.caption)
                .foregroundStyle(PumColor.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, PumTokens.Space.s4) // 시트 좌우보다 약 4 안쪽
            PumButton(title: SignaturePadContent.complete) { onComplete(drawing.validStrokes) }
                .disabled(!drawing.hasSignature)
        }
        .padding(.horizontal, PumTokens.Size.screenPad)
        .padding(.top, PumTokens.Space.s6) // 원문 손잡이 아래 6(공통 시트가 12를 이미 둠)
        .padding(.bottom, PumTokens.Space.s10) // 원문 아래 44 − 홈 막대 34
    }

    /// 키–값 줄: 기간은 한 줄(원문), 큰 글자에서 넘치면 값이 아래로
    private func termRow(_ key: String, _ value: String, isLast: Bool) -> some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: PumTokens.Space.s12) {
                keyText(key)
                Spacer(minLength: 0)
                valueText(value).lineLimit(1).fixedSize()
            }
            VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                keyText(key)
                valueText(value)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, PumTokens.Space.s10) // 원문 11 — 가까운 토큰
        .padding(.horizontal, PumTokens.Space.s18)
        .overlay(alignment: .bottom) {
            if !isLast {
                Rectangle().fill(PumColor.borderHairline).frame(height: 1)
                    .padding(.horizontal, PumTokens.Space.s18)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private func keyText(_ s: String) -> some View {
        Text(s).pumText(.body, weight: .regular).foregroundStyle(PumColor.textSecondary)
    }

    /// 원문 값 15px 600
    private func valueText(_ s: String) -> some View {
        Text(s).pumText(.body, weight: .semibold).foregroundStyle(PumColor.textPrimary)
            .multilineTextAlignment(.trailing)
    }
}

#Preview("1aa") { SignaturePadView(drawing: .sample) }
#Preview("1aa · 빈 상태") { SignaturePadView(drawing: SignatureDrawing()) }
#Preview("1aa · 큰 글자") { SignaturePadView().dynamicTypeSize(.xxxLarge) }
