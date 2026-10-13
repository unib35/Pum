import SwiftUI

enum WorkplaceRoute: String, CaseIterable, Hashable {
    case ownerWorkplaces = "1w"
    case attendancePolicy = "1an"
    case workplaceCreate = "2i"
    case workplaceSettings = "4c"
    case verifyIntro = "5b"
    case businessVerify = "5c"
    case authorityVerify = "5e"
    case duplicateBusiness = "5d"
    case checkInMethod = "10l"
    case checkInQR = "10m"
    case leaveRetirement = "10p"
    case activityLog = "6l"

    var title: String {
        switch self {
        case .ownerWorkplaces: "전체 사업장"
        case .attendancePolicy: "근태 정책"
        case .workplaceCreate: "사업장 만들기"
        case .workplaceSettings: "사업장 설정"
        case .verifyIntro: "사업장 인증 시트"
        case .businessVerify: "사업자 확인"
        case .authorityVerify: "관리 권한 확인"
        case .duplicateBusiness: "사업자번호 중복"
        case .checkInMethod: "출근 확인 방식"
        case .checkInQR: "출근 QR"
        case .leaveRetirement: "휴가 · 퇴직"
        case .activityLog: "활동 기록"
        }
    }

    /// 버튼을 다음 화면에 이은 화면. 아직 잇지 않은 화면은 예시 데이터로 열린다.
    @MainActor @ViewBuilder
    func view(_ router: AppRouter) -> some View {
        switch self {
        case .ownerWorkplaces:
            OwnerWorkplacesView()
        case .attendancePolicy:
            AttendancePolicyView()
        case .workplaceCreate:
            WorkplaceCreateView(state: .sample)
        case .workplaceSettings:
            WorkplaceSettingsView(state: .sample)
        case .verifyIntro:
            VerifyIntroView(state: .sample)
        case .businessVerify:
            BusinessVerifyView(state: .sample)
        case .authorityVerify:
            AuthorityVerifyView(state: .sample)
        case .duplicateBusiness:
            DuplicateBusinessView(state: .sample)
        case .checkInMethod:
            CheckInMethodView(state: .sample)
        case .checkInQR:
            CheckInQRView(state: .sample)
        case .leaveRetirement:
            LeaveRetirementView(state: .sample)
        case .activityLog:
            ActivityLogView(state: .sample)
        }
    }

    static let connected: Set<Self> = []
}
