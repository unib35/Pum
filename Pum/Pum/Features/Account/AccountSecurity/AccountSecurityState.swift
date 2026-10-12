// UI-IOS-6a · REQ-090 — 계정 · 로그인 및 보안 상태. 서버/설정 값을 그대로 담는다(모두 let).
// 휴대폰 · 이메일은 화면 표시만 — print · 로그 금지.
import Foundation

/// 고칠 수 있는 정보 행
nonisolated enum AccountField: Hashable, Sendable {
    case name, phone, email
}

nonisolated struct AccountSecurityState: Equatable, Sendable {
    static let headerTitle = "계정"
    static let securityHeader = "로그인 및 보안"
    static let manageHeader = "계정 관리"
    static let nameTitle = "이름"
    static let phoneTitle = "휴대폰"
    static let emailTitle = "이메일"
    static let loginMethodTitle = "로그인 방식"
    static let appleTitle = "Apple 계정"
    static let appleConnect = "연결하기"
    static let devicesTitle = "로그인 기기"
    static let logoutTitle = "로그아웃"
    static let withdrawTitle = "회원 탈퇴"

    let name: String
    let verifiedBadge: String
    /// 「2026.10.03 · 휴대폰」 — 서버 값
    let verifiedDetail: String
    let phone: String
    let email: String
    /// 「카카오」
    let loginMethod: String
    /// Apple 계정이 연결됐을 때의 상태 글자(서버 값, 예 「연결됨」). nil이면 미연결 → 「연결하기」. 원문에 연결됨 모양은 없어 판단.
    let appleStatusText: String?
    /// 「Face ID로 급여 정보 잠금」 — 기기가 Touch ID면 서버/기기 값으로 바꾼다
    let biometricTitle: String
    let biometricDetail: String
    let biometricLockOn: Bool
    /// 「이 iPhone · iPad (마지막 접속 9/28)」
    let deviceSummary: String
    let deviceCount: Int

    var isAppleConnected: Bool { appleStatusText != nil }
    var deviceCountText: String { "\(deviceCount)대" }

    func value(for field: AccountField) -> String {
        switch field {
        case .name: name
        case .phone: phone
        case .email: email
        }
    }

    func title(for field: AccountField) -> String {
        switch field {
        case .name: Self.nameTitle
        case .phone: Self.phoneTitle
        case .email: Self.emailTitle
        }
    }

    /// 행을 한 번에 읽는 문구: 「휴대폰, 010-4821-7733」
    func rowAccessibility(_ field: AccountField) -> String { "\(title(for: field)), \(value(for: field))" }

    var profileAccessibility: String { "\(name), \(verifiedBadge), \(verifiedDetail)" }
    var loginMethodAccessibility: String { "\(Self.loginMethodTitle), \(loginMethod)" }
    var deviceAccessibility: String { "\(Self.devicesTitle), \(deviceSummary), \(deviceCountText)" }

    static let sample = AccountSecurityState(
        name: "이종민", verifiedBadge: "본인인증 완료", verifiedDetail: "2026.10.03 · 휴대폰",
        phone: "010-4821-7733", email: "jongmin.lee@kakao.com", loginMethod: "카카오",
        appleStatusText: nil,
        biometricTitle: "Face ID로 급여 정보 잠금", biometricDetail: "급여 · 명세서 · 계좌를 열 때 확인",
        biometricLockOn: true,
        deviceSummary: "이 iPhone · iPad (마지막 접속 9/28)", deviceCount: 2)
}
