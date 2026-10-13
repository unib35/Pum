import SwiftUI

enum AccountRoute: String, CaseIterable, Hashable {
    case notificationSettings = "4b"
    case myInfo = "4a"
    case afterLeaving = "10o"
    case accountSecurity = "6a"
    case withdraw = "6b"
    case consents = "6d"
    case policies = "6c"
    case appPermissions = "6f"
    case ownerNotificationSettings = "6g"
    case documentBox = "6k"
    case helpCenter = "6m"
    case privacyAppInfo = "6o"
    case forceUpdate = "6t"
    case maintenance = "6w"
    case employmentCertRequest = "19d"
    case employmentCertIssued = "19f"

    var title: String {
        switch self {
        case .notificationSettings: "알림 설정"
        case .myInfo: "내 정보"
        case .afterLeaving: "퇴사 후"
        case .accountSecurity: "계정 · 로그인 및 보안"
        case .withdraw: "회원 탈퇴"
        case .consents: "내 동의 내역"
        case .policies: "약관 및 정책"
        case .appPermissions: "앱 권한"
        case .ownerNotificationSettings: "사장님 알림 설정"
        case .documentBox: "문서함"
        case .helpCenter: "고객센터"
        case .privacyAppInfo: "개인정보 · 앱 정보"
        case .forceUpdate: "업데이트 필수"
        case .maintenance: "점검 중"
        case .employmentCertRequest: "재직증명서 요청"
        case .employmentCertIssued: "발급된 재직증명서"
        }
    }

    /// 버튼을 다음 화면에 이은 화면. 아직 잇지 않은 화면은 예시 데이터로 열린다.
    @MainActor @ViewBuilder
    func view(_ router: AppRouter) -> some View {
        switch self {
        case .notificationSettings:
            NotificationSettingsView(state: .sample)
        case .myInfo:
            MyInfoView(state: .sample)
        case .afterLeaving:
            AfterLeavingView(state: .sample)
        case .accountSecurity:
            AccountSecurityView(state: .sample)
        case .withdraw:
            WithdrawView(state: .sample)
        case .consents:
            ConsentsView(state: .sample)
        case .policies:
            PoliciesView(state: .sample)
        case .appPermissions:
            AppPermissionsView(state: .sample)
        case .ownerNotificationSettings:
            OwnerNotificationSettingsView(state: .sample)
        case .documentBox:
            DocumentBoxView(state: .sample)
        case .helpCenter:
            HelpCenterView(state: .sample)
        case .privacyAppInfo:
            PrivacyAppInfoView(state: .sample)
        case .forceUpdate:
            ForceUpdateView(state: .sample)
        case .maintenance:
            MaintenanceView(state: .sample)
        case .employmentCertRequest:
            EmploymentCertRequestView(state: .sample)
        case .employmentCertIssued:
            EmploymentCertIssuedView(state: .sample)
        }
    }

    static let connected: Set<Self> = []
}
