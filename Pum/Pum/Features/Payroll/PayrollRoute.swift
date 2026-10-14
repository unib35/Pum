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
            PayslipView(onBack: router.back)
        case .expectedPay:
            ExpectedPayView(onWorkplace: { router.navigate(.home(.workplaceSwitcher)) })
        case .multiWorkplacePay:
            MultiWorkplacePayView()
        case .ownerPayroll:
            OwnerPayrollView(
                onProcess: { router.navigate(.payroll(.workClosingProblems)) },
                onConfirm: { router.navigate(.payroll(.payrollCalculating)) }
            )
        case .payrollConfirm:
            PayrollConfirmView(
                onConfirm: { _ in router.replace(with: .payroll(.payslipIssue)) },
                onCancel: router.back
            )
        case .recordReviewRequest:
            RecordReviewRequestView(
                onSend: { _ in router.navigate(.attendance(.recordReview)) },
                onClose: router.back
            )
        case .paymentChecklist:
            PaymentChecklistView(
                state: .sample,
                onBack: router.back,
                onSend: { _ in router.navigate(.payroll(.paymentSend)) }
            )
        case .workClosing:
            WorkClosingView(
                state: .sample,
                onBack: router.back,
                onOpenCategory: { _ in router.navigate(.payroll(.workClosingProblems)) },
                onOpenEmployeeConfirm: { router.navigate(.payroll(.recordReviewRequest)) },
                onReviewProblems: { router.navigate(.payroll(.workClosingProblems)) },
                onClose: { done in
                    done(true)
                    router.navigate(.payroll(.workClosingConfirm))
                }
            )
        case .workClosingProblems:
            WorkClosingProblemsView(state: .sample, onBack: router.back)
        case .workClosingConfirm:
            WorkClosingConfirmView(
                state: .sample,
                onBack: router.back,
                onCancel: router.back,
                onConfirm: { done in
                    done(true)
                    router.backToRoot()
                    router.select(.pay)
                }
            )
        case .paymentDoneConfirm:
            PaymentDoneConfirmScreen(
                state: .sample,
                onCancel: router.back,
                onConfirm: { done in
                    done(true)
                    router.back()
                    router.back()
                }
            )
        case .paymentSend:
            PaymentSendScreen(
                state: .sample,
                onMarkPaid: { router.navigate(.payroll(.paymentDoneConfirm)) },
                onClose: router.back
            )
        case .paymentSendMasked:
            PaymentSendScreen(
                state: .masked,
                onMarkPaid: { router.navigate(.payroll(.paymentDoneConfirm)) },
                onClose: router.back
            )
        case .laborSimulatorResult:
            LaborSimulatorResultView(
                state: .sample,
                onBack: router.back,
                onOpenRecommend: { router.navigate(.schedule(.staffingNeeds)) },
                onSaveOnly: router.back
            )
        case .laborSimulator:
            LaborSimulatorView(
                state: .sample,
                onClose: router.back,
                onShowResult: { router.navigate(.payroll(.laborSimulatorResult)) }
            )
        case .paymentNotReceived:
            PaymentNotReceivedScreen(
                state: .sample,
                memo: "국민은행 앱에서 확인했어요",
                onBack: router.back,
                onCancel: router.back,
                onSend: { _, _, done in
                    done(true)
                    router.replace(with: .payroll(.paymentCheckRequest))
                }
            )
        case .paymentCheckRequest:
            PaymentCheckRequestScreen(
                state: .sample,
                onBack: router.back,
                onDismiss: router.back,
                onConfirmSent: { done in
                    done(true)
                    router.replace(with: .payroll(.paymentUndo))
                },
                onRevertToPending: router.back
            )
        case .payslipIssue:
            PayslipIssueView(
                state: .sample,
                onBack: router.back,
                onIssue: { _ in router.navigate(.payroll(.payslipIssueConfirm)) }
            )
        case .payslipIssueConfirm:
            PayslipIssueConfirmScreen(
                state: .sample,
                onCancel: router.back,
                onIssue: { done in
                    done(true)
                    router.replace(with: .payroll(.payslip))
                }
            )
        case .correctionRecalc:
            CorrectionRecalcView(
                state: .sample,
                onBack: router.back,
                onConfirm: { _, done in
                    done(true)
                    router.replace(with: .payroll(.correctedPayslip))
                }
            )
        case .correctedPayslip:
            CorrectedPayslipView(
                state: .sample,
                onBack: router.back,
                onShowOriginal: { router.navigate(.payroll(.payslip)) }
            )
        case .payrollCalculating:
            PayrollCalculatingView(state: .sample, onBack: router.back)
        case .payrollInquiry:
            PayrollInquiryView(state: .sample, onClose: router.back, onSend: { _ in router.back() })
        case .wageYearTransition:
            WageYearTransitionView(
                state: .sample,
                sheet: .sample,
                onBack: router.back,
                onSetWages: { router.navigate(.payroll(.newWageSheet)) }
            )
        case .newWageSheet:
            WageYearTransitionView(
                state: .sample,
                sheet: .sample,
                startsWithSheetOpen: true,
                onBack: router.back,
                onSend: { _, done in
                    done(true)
                    router.replace(with: .employee(.wageChangeContract))
                }
            )
        case .workClosingDirect:
            WorkClosingDirectView(
                state: .sample,
                onBack: router.back,
                onOpenDay: { _, _ in router.navigate(.employee(.dayFix)) },
                onClose: { done in
                    done(true)
                    router.navigate(.payroll(.payslipSendDirect))
                }
            )
        case .payslipSendDirect:
            PayslipSendDirectView(
                state: .sample,
                onBack: router.back,
                onSend: { done in done(true) }
            )
        case .paymentUndo:
            PaymentUndoView(
                state: .sample,
                startsWithSheetOpen: true,
                onBack: router.back,
                onUndo: { _, done in
                    done(true)
                    router.replace(with: .payroll(.paymentUndone))
                }
            )
        case .paymentUndone:
            PaymentUndoView(state: .reverted, onBack: router.back)
        }
    }

    static let connected: Set<Self> = [
        .payslip, .expectedPay, .ownerPayroll, .payrollConfirm, .recordReviewRequest, .paymentChecklist,
        .workClosing, .workClosingProblems, .workClosingConfirm, .paymentDoneConfirm, .paymentSend,
        .paymentSendMasked, .laborSimulatorResult, .laborSimulator, .paymentNotReceived, .paymentCheckRequest,
        .payslipIssue, .payslipIssueConfirm, .correctionRecalc, .correctedPayslip, .payrollCalculating,
        .payrollInquiry, .wageYearTransition, .newWageSheet, .workClosingDirect, .payslipSendDirect,
        .paymentUndo, .paymentUndone
    ]
}
