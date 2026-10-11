// UI-IOS-4c · REQ-026 · REQ-093 — 사업장 설정: 서버 값 문구 조합 · 관리자 표시
import Testing
@testable import Pum

struct WorkplaceSettingsTests {
    let s = WorkplaceSettingsState.sample

    @Test func 정보_줄은_업종_직원수_주소_조합() {
        #expect(s.infoLine == "음식점 · 직원 5명 · 부산 김해시 장유로 12")
        #expect(s.infoAccessibilityText == "종민김밥 본점, 음식점 · 직원 5명 · 부산 김해시 장유로 12")
    }

    @Test func 직원수가_바뀌면_정보_줄도_바뀐다() {
        var t = s
        t.staffCount = 7
        #expect(t.infoLine == "음식점 · 직원 7명 · 부산 김해시 장유로 12")
    }

    @Test func 근태_값_문구는_원문_그대로() {
        #expect(s.checkInMethod == "QR + 위치 100m")
        #expect(s.overtimePolicy == "B · 45분 초과 시 확인")
        #expect(s.reminderValue == "+6시간 종료")
        #expect(s.storeQRAction == "인쇄 · 재발급")
    }

    @Test func 급여_값_문구는_원문_그대로() {
        #expect(s.payday == "매월 10일 · 전월 1–말일")
        #expect(s.premiumRules == "법정 기준 · 휴일 1.5배")
        #expect(s.reviewRequestSubtitle == "매월 말일 자동 발송")
        #expect(s.reviewRequestOn)
        #expect(s.contractTemplate == "표준 · 단시간")
    }

    @Test func 관리자_두_명_역할은_서버_값() {
        #expect(s.admins.count == 2)
        #expect(s.admins[0].roleLabel == "대표")
        #expect(s.admins[1].roleLabel == "매니저 · 근태만")
        #expect(s.admins[0].initial == "박")
        #expect(s.admins[1].initial == "유")
    }

    @Test func 본인_관리자만_나_표시가_읽힌다() {
        #expect(s.admins[0].accessibilityText == "박민수, 나, 대표")
        #expect(s.admins[1].accessibilityText == "최유나, 매니저 · 근태만")
    }

    @Test func 관리자_아바타는_먹색과_연주황() {
        #expect(PumAvatarPalette.person(index: s.admins[0].colorIndex) == PumAvatarPalette.people[5])
        #expect(PumAvatarPalette.person(index: s.admins[1].colorIndex) == PumAvatarPalette.people[2])
    }

    @Test func 사업장_글자와_색() {
        #expect(s.workplaceInitial == "종")
        #expect(s.workplaceColorIndex == 0)
    }

    @Test func 폐업은_대표만() {
        var s = WorkplaceSettingsState.sample
        #expect(s.isMeRepresentative)
        s.admins = s.admins.map { WorkplaceAdmin(id: $0.id, name: $0.name, initial: $0.initial, colorIndex: $0.colorIndex,
                                                 isMe: $0.id == "a2", roleLabel: $0.roleLabel) }
        #expect(!s.isMeRepresentative) // 매니저가 보면 숨김
    }
}
