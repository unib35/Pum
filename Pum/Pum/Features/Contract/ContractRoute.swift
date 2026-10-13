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
            ContractReviewView(
                startsAgreed: true,
                onBack: router.back,
                onSign: { router.navigate(.contract(.signaturePad)) },
                onViewFull: { router.navigate(.contract(.contractPDFViewer)) }
            )
        case .signaturePad:
            SignaturePadView(
                drawing: .sample,
                onBack: router.back,
                onComplete: { _ in
                    if router.role == .owner {
                        router.backToRoot()
                    } else {
                        router.replace(with: .onboarding(.onboardingChecklist))
                    }
                },
                onDismissSheet: router.back
            )
        case .contractList:
            ContractListView(
                onBack: router.back,
                onViewPDF: { _ in router.navigate(.contract(.contractPDFViewer)) },
                onConfirmChange: { _ in router.navigate(.contract(.wageChangeContract)) }
            )
        case .workTermsInput:
            WorkTermsInputView(
                state: .sample,
                onBack: router.back,
                onPreview: { router.navigate(.contract(.contractPreview)) }
            )
        case .contractChange:
            ContractChangeView(
                state: .sample,
                onBack: router.back,
                onSend: { done in
                    done(true)
                    router.backToRoot()
                }
            )
        case .contractPreview:
            ContractPreviewView(
                state: .sample,
                onBack: router.back,
                onShowFull: { router.navigate(.contract(.contractPDFViewer)) },
                onSignAndSend: { done in
                    done(true)
                    router.navigate(.contract(.signaturePad))
                }
            )
        case .wageChangeContract:
            WageChangeContractView(
                state: .sample,
                onBack: router.back,
                onOpenFull: { router.navigate(.contract(.contractPDFViewer)) },
                onSign: { router.navigate(.contract(.signaturePad)) }
            )
        case .contractPDFViewer:
            ContractPDFViewerView(
                state: .sample,
                onBack: router.back
            )
        }
    }

    static let connected: Set<Self> = [
        .contractReview, .signaturePad, .contractList, .workTermsInput, .contractChange, .contractPreview,
        .wageChangeContract, .contractPDFViewer,
    ]
}
