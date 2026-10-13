import SwiftUI

enum PayrollRoute: String, CaseIterable, Hashable {
    case payslip = "1m"
    case expectedPay = "1l"
    case multiWorkplacePay = "1n"
    case ownerPayroll = "1u"
    case payrollConfirm = "1v"
    case recordReviewRequest = "1ad"
    case paymentChecklist = "7a"
    case workClosing = "8a"
    case workClosingProblems = "8b"
    case workClosingConfirm = "8c"
    case paymentDoneConfirm = "7c"
    case paymentSend = "7b"
    case paymentSendMasked = "21e"
    case laborSimulatorResult = "8e"
    case laborSimulator = "8d"
    case paymentNotReceived = "21c"
    case paymentCheckRequest = "21d"
    case payslipIssue = "10d"
    case payslipIssueConfirm = "10e"
    case correctionRecalc = "10g"
    case correctedPayslip = "10h"
    case payrollCalculating = "21l"
    case payrollInquiry = "6n"
    case wageYearTransition = "19a"
    case newWageSheet = "19b"
    case workClosingDirect = "20g"
    case payslipSendDirect = "20h"
    case paymentUndo = "21a"
    case paymentUndone = "21b"

    var title: String {
        switch self {
        case .payslip: "급여명세서"
        case .expectedPay: "예상 급여"
        case .multiWorkplacePay: "여러 사업장"
        case .ownerPayroll: "급여 정산"
        case .payrollConfirm: "급여 확정 시트"
        case .recordReviewRequest: "확인 요청 시트"
        case .paymentChecklist: "월급날 지급 체크리스트"
        case .workClosing: "근무 마감"
        case .workClosingProblems: "문제 기록 처리"
        case .workClosingConfirm: "근무 마감 확인"
        case .paymentDoneConfirm: "지급 완료 확인"
        case .paymentSend: "직원별 지급 시트"
        case .paymentSendMasked: "지급 시트 · 계좌 가림"
        case .laborSimulatorResult: "시뮬레이션 결과"
        case .laborSimulator: "인건비 시뮬레이터"
        case .paymentNotReceived: "아직 입금 안 됐어요"
        case .paymentCheckRequest: "입금 확인 요청"
        case .payslipIssue: "급여명세서 발행"
        case .payslipIssueConfirm: "명세서 발행 확인"
        case .correctionRecalc: "정정 재계산"
        case .correctedPayslip: "정정 명세서"
        case .payrollCalculating: "급여 계산 중"
        case .payrollInquiry: "급여 계산 문의"
        case .wageYearTransition: "연도 전환"
        case .newWageSheet: "새 시급 정하기"
        case .workClosingDirect: "근무 마감 · 앱 없는 직원"
        case .payslipSendDirect: "명세서 보내기"
        case .paymentUndo: "지급 완료 취소"
        case .paymentUndone: "되돌린 뒤"
        }
    }

    /// 버튼을 다음 화면에 이은 화면. 아직 잇지 않은 화면은 예시 데이터로 열린다.
    @MainActor @ViewBuilder
    func view(_ router: AppRouter) -> some View {
        switch self {
        case .payslip:
            PayslipView()
        case .expectedPay:
            ExpectedPayView()
        case .multiWorkplacePay:
            MultiWorkplacePayView()
        case .ownerPayroll:
            OwnerPayrollView()
        case .payrollConfirm:
            PayrollConfirmView()
        case .recordReviewRequest:
            RecordReviewRequestView()
        case .paymentChecklist:
            PaymentChecklistView(state: .sample)
        case .workClosing:
            WorkClosingView(state: .sample)
        case .workClosingProblems:
            WorkClosingProblemsView(state: .sample)
        case .workClosingConfirm:
            WorkClosingConfirmView(state: .sample)
        case .paymentDoneConfirm:
            PaymentDoneConfirmScreen(state: .sample)
        case .paymentSend:
            PaymentSendScreen(state: .sample)
        case .paymentSendMasked:
            PaymentSendScreen(state: .masked)
        case .laborSimulatorResult:
            LaborSimulatorResultView(state: .sample)
        case .laborSimulator:
            LaborSimulatorView(state: .sample)
        case .paymentNotReceived:
            PaymentNotReceivedScreen(state: .sample, memo: "국민은행 앱에서 확인했어요")
        case .paymentCheckRequest:
            PaymentCheckRequestScreen(state: .sample)
        case .payslipIssue:
            PayslipIssueView(state: .sample)
        case .payslipIssueConfirm:
            PayslipIssueConfirmScreen(state: .sample)
        case .correctionRecalc:
            CorrectionRecalcView(state: .sample)
        case .correctedPayslip:
            CorrectedPayslipView(state: .sample)
        case .payrollCalculating:
            PayrollCalculatingView(state: .sample)
        case .payrollInquiry:
            PayrollInquiryView(state: .sample)
        case .wageYearTransition:
            WageYearTransitionView(state: .sample, sheet: .sample)
        case .newWageSheet:
            WageYearTransitionView(state: .sample, sheet: .sample, startsWithSheetOpen: true)
        case .workClosingDirect:
            WorkClosingDirectView(state: .sample)
        case .payslipSendDirect:
            PayslipSendDirectView(state: .sample)
        case .paymentUndo:
            PaymentUndoView(state: .sample, startsWithSheetOpen: true)
        case .paymentUndone:
            PaymentUndoView(state: .reverted)
        }
    }

    static let connected: Set<Self> = []
}
