// UI-IOS-2b — 휴대폰 인증: 숫자만 6자리 · 칸 나누기 · 남은 시간 문구 · 타이머 정지
import Foundation
import Testing
@testable import Pum

struct PhoneVerifyTests {
    @Test func 원문_샘플() {
        let s = PhoneVerifyState.sample
        #expect(s.code == "482")
        #expect(s.remainingText == "02:41 남음")
        #expect(s.subtitleLead == "010-4821-7733으로 보냈어요 · ")
        #expect(s.accessibilityCodeText == "인증번호, 6자리 중 3자리 입력됨")
        #expect(!s.isComplete)
    }

    @Test func 숫자만_여섯자리까지() {
        #expect(PhoneVerifyState.sanitized("12a3-4 5678") == "123456")
        #expect(PhoneVerifyState.sanitized("") == "")
        #expect(PhoneVerifyState.sanitized("٣٤٥") == "") // 아라비아 숫자는 받지 않는다
    }

    @Test func 칸_나누기와_현재_칸() {
        let s = PhoneVerifyState.sample
        #expect(s.digit(at: 0) == "4")
        #expect(s.digit(at: 2) == "2")
        #expect(s.digit(at: 3) == nil)
        #expect(s.digit(at: -1) == nil)
        #expect(s.activeIndex == 3)
        let full = PhoneVerifyState(phoneDisplay: "x", code: "123456", remainingSeconds: 1)
        #expect(full.isComplete)
        #expect(full.activeIndex == nil)
        let empty = PhoneVerifyState.entry(phoneDisplay: "x", remainingSeconds: 180)
        #expect(empty.activeIndex == 0)
    }

    @Test func 시간_문구와_0초_정지() {
        var s = PhoneVerifyState(phoneDisplay: "x", remainingSeconds: 1)
        #expect(s.remainingText == "00:01 남음")
        s.tick()
        #expect(s.remainingSeconds == 0)
        s.tick()
        #expect(s.remainingSeconds == 0)
        #expect(s.remainingText == "00:00 남음")
        let big = PhoneVerifyState(phoneDisplay: "x", remainingSeconds: 600)
        #expect(big.remainingText == "10:00 남음")
    }

    @Test func 남은_시간은_만료_시각_기준() {
        var s = PhoneVerifyState.sample
        let now = Date()
        s.update(deadline: now.addingTimeInterval(100.2), now: now)
        #expect(s.remainingSeconds == 101)
        s.update(deadline: now, now: now.addingTimeInterval(5))
        #expect(s.remainingSeconds == 0)
    }

    @Test func 다시_보내면_입력을_비우고_시간을_처음으로() {
        var s = PhoneVerifyState.sample
        s.restart()
        #expect(s.code.isEmpty)
        #expect(s.remainingSeconds == s.validSeconds)
    }
}
