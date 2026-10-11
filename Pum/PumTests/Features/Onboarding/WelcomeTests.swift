// UI-IOS-2a — 시작: 슬로건 5개 문구 · 순서, 다음 인덱스, 자동 전환 조건, 원문 캡처 상태
import Testing
@testable import Pum

struct WelcomeTests {
    @Test func 슬로건_5개_순서와_문구() {
        let s = WelcomeSlogan.all
        #expect(s.count == 5)
        #expect(s.map(\.id) == [0, 1, 2, 3, 4])
        #expect(s[0].title == "일한 만큼,\n정확하게 받기")
        #expect(s[2].title == "이번 달 얼마 받을지\n매일 알 수 있어요")
        #expect(s[2].detail == "기본급·주휴수당·공제까지\n계산 근거를 바로 확인해요.")
        #expect(s[4].title == "급여명세서까지\n한 번에")
    }

    @Test func 접근성_문장은_줄바꿈_없이_한_문장() {
        #expect(WelcomeSlogan.all[1].accessibilityText
            == "출근은 QR 한 번, 퇴근은 버튼 한 번 예정 시간이 아니라 실제 기록으로 근무시간이 만들어져요.")
    }

    @Test func 다음_인덱스는_마지막_다음_처음으로() {
        #expect(WelcomeRotation.next(after: 0, count: 5) == 1)
        #expect(WelcomeRotation.next(after: 3, count: 5) == 4)
        #expect(WelcomeRotation.next(after: 4, count: 5) == 0)
        #expect(WelcomeRotation.next(after: 9, count: 5) == 0)
        #expect(WelcomeRotation.next(after: -1, count: 5) == 0)
        #expect(WelcomeRotation.next(after: 2, count: 0) == 0)
    }

    @Test func 주기_3점2초_16초_반복() {
        #expect(WelcomeRotation.interval == 3.2)
        #expect(WelcomeRotation.interval * Double(WelcomeSlogan.all.count) == 16)
    }

    @Test func 자동_전환_조건() {
        #expect(WelcomeRotation.shouldAutoAdvance(enabled: true, voiceOver: false, reduceMotion: false, count: 5))
        #expect(!WelcomeRotation.shouldAutoAdvance(enabled: true, voiceOver: true, reduceMotion: false, count: 5))
        #expect(!WelcomeRotation.shouldAutoAdvance(enabled: false, voiceOver: false, reduceMotion: false, count: 5))
        #expect(!WelcomeRotation.shouldAutoAdvance(enabled: true, voiceOver: false, reduceMotion: false, count: 1))
    }

    @Test func 시작_위치_보정() {
        #expect(WelcomeRotation.clamped(2, count: 5) == 2)
        #expect(WelcomeRotation.clamped(-3, count: 5) == 0)
        #expect(WelcomeRotation.clamped(99, count: 5) == 4)
    }

    @Test func 원문_캡처_상태는_3번째_고정() {
        #expect(WelcomeState.sample.startIndex == 2)
        #expect(!WelcomeState.sample.autoAdvance)
        #expect(WelcomeSlogan.all[WelcomeState.sample.startIndex].title.hasPrefix("이번 달 얼마 받을지"))
        #expect(WelcomeState().autoAdvance)
    }

    @Test func 동작_줄이기면_자동_전환_안_함() {
        #expect(!WelcomeRotation.shouldAutoAdvance(enabled: true, voiceOver: false, reduceMotion: true, count: 5))
    }

    @Test func 이전_슬로건은_처음_이전이_마지막() {
        #expect(WelcomeRotation.previous(before: 0, count: 5) == 4)
        #expect(WelcomeRotation.previous(before: 3, count: 5) == 2)
    }
}
