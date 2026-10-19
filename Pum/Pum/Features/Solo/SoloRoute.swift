import SwiftUI

/// MVP 앱(사장님 혼자) 목적지. 디자인 화면을 저장소 값으로 연다.
import SwiftData

enum SoloRoute: Hashable {
    case staffList
    case staffDetail(PersistentIdentifier)
    /// 그날이 있는 달을 열고 그날 고치기 시트를 바로 연다(20g → 20f)
    case staffDay(PersistentIdentifier, Int)
    case registerBasic
    case registerTerms
    case registerContract
    case payroll
    case workClosing
    case payslip(String)

    var screenID: String {
        switch self {
        case .staffList: "solo-1ac"
        case .staffDetail: "solo-20e"
        case .staffDay: "solo-20f"
        case .registerBasic: "solo-20b"
        case .registerTerms: "solo-20c"
        case .registerContract: "solo-20d"
        case .payroll: "solo-1u"
        case .workClosing: "solo-20g"
        case .payslip: "solo-1m"
        }
    }

    var title: String {
        switch self {
        case .staffList: "직원"
        case .staffDetail: "직원 근무"
        case .staffDay: "하루 고치기"
        case .registerBasic: "직원 등록 · 기본 정보"
        case .registerTerms: "직원 등록 · 근로조건"
        case .registerContract: "직원 등록 · 근로계약서"
        case .payroll: "급여"
        case .workClosing: "근무 마감"
        case .payslip: "급여명세서"
        }
    }

    @MainActor @ViewBuilder
    func view(_ router: AppRouter) -> some View {
        switch self {
        case .staffList: SoloStaffListScreen(router: router)
        case .staffDetail(let id): SoloStaffDetailScreen(router: router, employeeID: id)
        case .staffDay(let id, let key): SoloStaffDetailScreen(router: router, employeeID: id, focusDayKey: key)
        case .registerBasic: SoloRegisterBasicScreen(router: router)
        case .registerTerms: SoloRegisterTermsScreen(router: router)
        case .registerContract: SoloRegisterContractScreen(router: router)
        case .payroll: SoloPayrollScreen(router: router)
        case .workClosing: SoloWorkClosingScreen(router: router)
        case .payslip(let id): SoloPayslipScreen(router: router, employeeID: id)
        }
    }
}
