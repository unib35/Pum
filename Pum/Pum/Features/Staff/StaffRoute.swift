import SwiftUI

enum StaffRoute: String, CaseIterable, Hashable {
    case staffInvite = "1x"
    case staffList = "1ac"
    case staffDetail = "2l"
    case offboarding = "10n"
    case leaveBalance = "10q"
    case offboardingNotEligible = "10r"
    case offboardingPension = "10s"
    case managerPermissions = "6h"
    case employmentStatus = "6j"
    case managerInvite = "17h"
    case managerInviteReceived = "17i"
    case ownerTransferReceived = "17k"
    case ownerTransfer = "17j"
    case employmentCertIssue = "19e"
    case staffAddPreviewHost = "20a"
    case directRegisterBasic = "20b"
    case directRegisterContract = "20d"
    case directRegisterTerms = "20c"
    case appLessStaff = "20e"
    case dayFix = "20f"

    var title: String {
        switch self {
        case .staffInvite: "직원 초대"
        case .staffList: "직원 관리"
        case .staffDetail: "직원 상세"
        case .offboarding: "퇴사 정산"
        case .leaveBalance: "연차 현황"
        case .offboardingNotEligible: "퇴사 정산 · 대상 아님"
        case .offboardingPension: "퇴사 정산 · 퇴직연금 DC"
        case .managerPermissions: "관리자 권한"
        case .employmentStatus: "재직 상태"
        case .managerInvite: "관리자 초대"
        case .managerInviteReceived: "관리자 초대 받음"
        case .ownerTransferReceived: "대표 권한 이전 요청 받음"
        case .ownerTransfer: "대표 변경"
        case .employmentCertIssue: "재직증명서 발급"
        case .staffAddPreviewHost: "직원 추가"
        case .directRegisterBasic: "직접 등록 · 기본 정보"
        case .directRegisterContract: "직접 등록 · 근로계약서"
        case .directRegisterTerms: "직접 등록 · 근로조건"
        case .appLessStaff: "앱 없는 직원"
        case .dayFix: "하루 고치기"
        }
    }

    /// 버튼을 다음 화면에 이은 화면. 아직 잇지 않은 화면은 예시 데이터로 열린다.
    @MainActor @ViewBuilder
    func view(_ router: AppRouter) -> some View {
        switch self {
        case .staffInvite:
            StaffInviteView(draft: .sample, showsPhoneFocus: true)
        case .staffList:
            StaffListView()
        case .staffDetail:
            StaffDetailView(state: .sample)
        case .offboarding:
            OffboardingView(state: .sample)
        case .leaveBalance:
            LeaveBalanceView(state: .sample)
        case .offboardingNotEligible:
            OffboardingView(state: .notEligible)
        case .offboardingPension:
            OffboardingView(state: .dcPension)
        case .managerPermissions:
            ManagerPermissionsView(state: .sample)
        case .employmentStatus:
            EmploymentStatusView(state: .sample)
        case .managerInvite:
            ManagerInviteView(state: .sample)
        case .managerInviteReceived:
            RoleOfferReceivedView(state: .managerInvite)
        case .ownerTransferReceived:
            RoleOfferReceivedView(state: .ownerTransfer)
        case .ownerTransfer:
            OwnerTransferView(state: .sample)
        case .employmentCertIssue:
            EmploymentCertIssueView(state: .sample)
        case .staffAddPreviewHost:
            StaffAddPreviewHost(state: .sample)
        case .directRegisterBasic:
            DirectRegisterBasicView(state: .sample)
        case .directRegisterContract:
            DirectRegisterContractView(state: .sample)
        case .directRegisterTerms:
            DirectRegisterTermsView(state: .sample)
        case .appLessStaff:
            AppLessStaffView(state: .sample, sheet: .sample)
        case .dayFix:
            AppLessStaffView(state: .sample, sheet: .sample, startsWithSheetOpen: true)
        }
    }

    static let connected: Set<Self> = []
}
