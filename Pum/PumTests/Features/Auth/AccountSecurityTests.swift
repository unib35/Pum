// UI-IOS-6a · REQ-090 — 계정 · 로그인 및 보안: 원문 값 · 읽기 문구 · Apple 연결 표시
import Testing
@testable import Pum

struct AccountSecurityTests {
    let s = AccountSecurityState.sample

    @Test func 원문_값() {
        #expect(s.name == "이종민")
        #expect(s.verifiedBadge == "본인인증 완료")
        #expect(s.verifiedDetail == "2026.10.03 · 휴대폰")
        #expect(s.phone == "010-4821-7733")
        #expect(s.email == "jongmin.lee@kakao.com")
        #expect(s.loginMethod == "카카오")
        #expect(s.biometricTitle == "Face ID로 급여 정보 잠금")
        #expect(s.biometricDetail == "급여 · 명세서 · 계좌를 열 때 확인")
        #expect(s.biometricLockOn)
        #expect(s.deviceSummary == "이 iPhone · iPad (마지막 접속 9/28)")
        #expect(s.deviceCountText == "2대")
    }

    @Test func 고정_글자() {
        #expect(AccountSecurityState.headerTitle == "계정")
        #expect(AccountSecurityState.securityHeader == "로그인 및 보안")
        #expect(AccountSecurityState.manageHeader == "계정 관리")
        #expect(AccountSecurityState.appleConnect == "연결하기")
        #expect(AccountSecurityState.withdrawTitle == "회원 탈퇴")
    }

    @Test func 읽기_문구() {
        #expect(s.rowAccessibility(.phone) == "휴대폰, 010-4821-7733")
        #expect(s.rowAccessibility(.name) == "이름, 이종민")
        #expect(s.rowAccessibility(.email) == "이메일, jongmin.lee@kakao.com")
        #expect(s.loginMethodAccessibility == "로그인 방식, 카카오")
        #expect(s.deviceAccessibility == "로그인 기기, 이 iPhone · iPad (마지막 접속 9/28), 2대")
        #expect(s.profileAccessibility == "이종민, 본인인증 완료, 2026.10.03 · 휴대폰")
    }

    @Test func Apple_미연결이면_연결하기() {
        #expect(!s.isAppleConnected)
        #expect(s.appleStatusText == nil)
    }

    @Test func Apple_연결되면_상태_글자() {
        let linked = AccountSecurityState(
            name: s.name, verifiedBadge: s.verifiedBadge, verifiedDetail: s.verifiedDetail,
            phone: s.phone, email: s.email, loginMethod: s.loginMethod, appleStatusText: "연결됨",
            biometricTitle: s.biometricTitle, biometricDetail: s.biometricDetail,
            biometricLockOn: false, deviceSummary: s.deviceSummary, deviceCount: 1)
        #expect(linked.isAppleConnected)
        #expect(linked.appleStatusText == "연결됨")
        #expect(linked.deviceCountText == "1대")
    }
}
