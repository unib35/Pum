// UI-IOS-1aa · REQ-060 — 서명 패드: 뒤 화면(근로계약서) + 공통 바텀시트(C9)
// 서명 완료 · 본인인증 · PDF 교부 · 서버 저장은 연결 후속 — 클로저로만 넘긴다.
import SwiftUI

struct SignaturePadView: View {
    var onBack: () -> Void = {}
    var onComplete: ([SignatureStroke]) -> Void = { _ in }
    var onDismissSheet: () -> Void = {}

    @State private var sheetOpen: Bool
    @State private var drawing: SignatureDrawing

    init(drawing: SignatureDrawing = .sample, sheetOpen: Bool = true,
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
        VStack(alignment: .leading, spacing: PumTokens.Space.s16) {
            PumNavHeader(title: SignaturePadContent.backTitle, onBack: onBack)
            // 목업 24px 700 → title2 bold
            Text(SignaturePadContent.contractTitle).pumText(.title2, weight: .bold)
                .foregroundStyle(PumColor.textPrimary)
                .accessibilityAddTraits(.isHeader)
            PumCard {
                // 원문 값 15px 600 — PumRow 기본 값 글자보다 굵다
                PumRow(title: SignaturePadContent.periodLabel, isKey: true) { rowValue(SignaturePadContent.period) }
                PumRow(title: SignaturePadContent.wageLabel, isKey: true, isLast: true) { rowValue(SignaturePadContent.wage) }
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
                .padding(.top, PumTokens.Space.s4)
        }
        .padding(.horizontal, PumTokens.Size.screenPad)
        .padding(.bottom, PumTokens.Space.s16)
    }

    private func rowValue(_ s: String) -> some View {
        Text(s).pumText(.body, weight: .semibold).foregroundStyle(PumColor.textPrimary)
            .lineLimit(1).minimumScaleFactor(0.8) // 기간은 한 줄(원문)
    }
}

#Preview("1aa") { SignaturePadView() }
#Preview("1aa · 빈 상태") { SignaturePadView(drawing: SignatureDrawing()) }
#Preview("1aa · 큰 글자") { SignaturePadView().dynamicTypeSize(.xxxLarge) }
