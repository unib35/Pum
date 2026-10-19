import SwiftUI

/// MVP 앱(사장님 혼자) 목적지. 디자인 화면을 저장소 값으로 연다.
enum SoloRoute: Hashable {
    case staffList
    case registerBasic
    case registerTerms
    case registerContract

    var screenID: String {
        switch self {
        case .staffList: "solo-1ac"
        case .registerBasic: "solo-20b"
        case .registerTerms: "solo-20c"
        case .registerContract: "solo-20d"
        }
    }

    var title: String {
        switch self {
        case .staffList: "직원"
        case .registerBasic: "직원 등록 · 기본 정보"
        case .registerTerms: "직원 등록 · 근로조건"
        case .registerContract: "직원 등록 · 근로계약서"
        }
    }

    @MainActor @ViewBuilder
    func view(_ router: AppRouter) -> some View {
        switch self {
        case .staffList: SoloStaffListScreen(router: router)
        case .registerBasic: SoloRegisterBasicScreen(router: router)
        case .registerTerms: SoloRegisterTermsScreen(router: router)
        case .registerContract: SoloRegisterContractScreen(router: router)
        }
    }
}
