// 인증 인터페이스 — REQ-001 · REQ-011 (가입 시 휴대폰 본인확인)
// 실제 구현은 Supabase Auth(전화번호 OTP) 예정. SMS 발송 업체는 미정(유료)이라 지금은 가짜 구현만 둔다.
// 계약: docs/api/contract.md
import Foundation

nonisolated struct PumSession: Equatable, Sendable {
    let userID: UUID
    let phone: String
    let accessToken: String
    let expiresAt: Date
}

nonisolated enum AuthError: Error, Equatable, Sendable {
    case invalidPhone
    case invalidCode(remainingAttempts: Int)
    case codeExpired
    case tooManyAttempts(retryAfter: Date)
    case network
}

protocol AuthService: Sendable {
    /// 인증번호 요청. 번호 형식이 틀리면 `.invalidPhone`.
    func requestCode(phone: String) async throws
    /// 인증번호 확인 → 세션
    func verify(phone: String, code: String) async throws -> PumSession
    func currentSession() async -> PumSession?
    func signOut() async
}

/// 미리보기 · 테스트 · 로컬 실행용. 네트워크를 쓰지 않는다. 인증번호는 항상 "000000".
actor MockAuthService: AuthService {
    nonisolated static let testCode = "000000"
    private var session: PumSession?
    private var attempts = 0
    private let maxAttempts = 5

    func requestCode(phone: String) async throws {
        guard Self.isValidKoreanMobile(phone) else { throw AuthError.invalidPhone }
        attempts = 0
    }

    func verify(phone: String, code: String) async throws -> PumSession {
        guard Self.isValidKoreanMobile(phone) else { throw AuthError.invalidPhone }
        guard code == Self.testCode else {
            attempts += 1
            if attempts >= maxAttempts { throw AuthError.tooManyAttempts(retryAfter: Date().addingTimeInterval(3600)) }
            throw AuthError.invalidCode(remainingAttempts: maxAttempts - attempts)
        }
        let s = PumSession(userID: UUID(), phone: phone, accessToken: "mock-token", expiresAt: Date().addingTimeInterval(3600))
        session = s
        return s
    }

    func currentSession() async -> PumSession? { session }
    func signOut() async { session = nil }

    /// 010으로 시작하는 11자리(하이픈 허용)
    nonisolated static func isValidKoreanMobile(_ phone: String) -> Bool {
        let digits = phone.filter(\.isNumber)
        return digits.count == 11 && digits.hasPrefix("010") && phone.allSatisfy { $0.isNumber || $0 == "-" }
    }
}
