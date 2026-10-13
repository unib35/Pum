import SwiftUI

enum ContractRoute: String, CaseIterable, Hashable {
    case contractReview = "1z"
    case signaturePad = "1aa"
    case contractList = "1ab"
    case workTermsInput = "10a"
    case contractChange = "10c"
    case contractPreview = "10b"
    case wageChangeContract = "19c"
    case contractPDFViewer = "1ap"

    var title: String {
        switch self {
        case .contractReview: "근로계약서 확인"
        case .signaturePad: "서명 패드"
        case .contractList: "계약서 보관함"
        case .workTermsInput: "근로조건 입력"
        case .contractChange: "조건 변경"
        case .contractPreview: "계약서 미리보기"
        case .wageChangeContract: "변경 계약서 받음"
        case .contractPDFViewer: "계약서 전문 PDF"
        }
    }

    /// 버튼을 다음 화면에 이은 화면. 아직 잇지 않은 화면은 예시 데이터로 열린다.
    @MainActor @ViewBuilder
    func view(_ router: AppRouter) -> some View {
        switch self {
        case .contractReview:
            ContractReviewView(startsAgreed: true)
        case .signaturePad:
            SignaturePadView(drawing: .sample)
        case .contractList:
            ContractListView()
        case .workTermsInput:
            WorkTermsInputView(state: .sample)
        case .contractChange:
            ContractChangeView(state: .sample)
        case .contractPreview:
            ContractPreviewView(state: .sample)
        case .wageChangeContract:
            WageChangeContractView(state: .sample)
        case .contractPDFViewer:
            ContractPDFViewerView(state: .sample)
        }
    }

    static let connected: Set<Self> = []
}
