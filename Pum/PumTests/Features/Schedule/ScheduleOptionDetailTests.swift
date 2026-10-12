// UI-IOS-9c · REQ-051 — 절감안 상세 문구 · 서버 값 그대로
import Testing
import Foundation
@testable import Pum

struct ScheduleOptionDetailTests {
    let s = ScheduleOptionDetailState.sample

    @Test func 원문_문구() {
        #expect(s.title == "인건비 절감안")
        #expect(s.summaryTitle == "주간 예상 인건비")
        #expect(s.currentText == "1,284,000")
        #expect(s.newText == "1,241,000원")
        #expect(s.deltaText == "\u{2212}43,000원")
        #expect(s.checks.map(\.title) == ["필요 인력 충족", "가능 시간 안", "소정근로 변경 없음", "휴게 기준"])
        #expect(s.checks.map(\.met) == [true, true, true, true])
        #expect(s.reasonsTitle == "줄어든 이유")
        #expect(s.reasons.map(\.title) == ["불필요한 연장근무 3시간 감소", "근무 가능 시간 안에서 재배치", "피크 시간대에만 추가 인력"])
        #expect(s.reasons.map(\.detail) == ["이종민 금 \u{00B7} 김하늘 토", "박서준 토요일 오후로 이동", "토 18\u{2013}22 정우진 4시간"])
        #expect(s.reasons.map(\.amountText) == ["\u{2212}27,000", "\u{2212}10,000", "\u{2212}6,000"])
        #expect(s.changesTitle == "변경 4건 \u{00B7} 직원이 수락하면 반영")
        #expect(s.changes.map(\.name) == ["이종민", "김하늘", "박서준", "정우진"])
        #expect(s.changes.map(\.beforeDisplay) == ["금 17\u{2013}23", "토 17\u{2013}23", "토 09\u{2013}15", "\u{2014}"])
        #expect(s.changes.map(\.afterText) == ["금 17\u{2013}22", "토 18\u{2013}22", "토 11\u{2013}17", "토 18\u{2013}22"])
        #expect(s.changes.map(\.changeText) == ["\u{2212}1h", "\u{2212}2h", "이동", "+4h"])
        #expect(s.sendTitle == "4명에게 변경 요청 보내기")
    }

    @Test func 음성_읽기() {
        #expect(s.summaryAccessibilityText.hasPrefix("주간 예상 인건비, 1,284,000원에서 1,241,000원, 43,000원 적음"))
        #expect(s.summaryAccessibilityText.hasSuffix("필요 인력 충족, 가능 시간 안, 소정근로 변경 없음, 휴게 기준 충족"))
        #expect(s.reasons[0].accessibilityText == "불필요한 연장근무 3시간 감소, 이종민 금 \u{00B7} 김하늘 토, 27,000원 적음")
        #expect(s.changes[0].spokenText == "이종민, 금 17시–23시에서 금 17시–22시로, 1시간 줄어듦")
    }

    @Test func 방향은_서버_값으로만() {
        var r = s.reasons[0]
        r.direction = .increase
        r.amount = 777
        #expect(r.amountText == "+777")
        r.direction = .same
        #expect(r.amountText == "777")
        var t = s
        t.direction = .increase
        t.deltaAmount = 5_000
        #expect(t.deltaText == "+5,000원")
        #expect(t.summaryAccessibilityText.contains("5,000원 많음"))
    }

    @Test func 이전_없음은_대시() {
        var c = s.changes[0]
        c.beforeText = nil
        #expect(c.beforeDisplay == "\u{2014}")
    }

    @Test func 미충족_체크는_읽기에_표시() {
        var t = s
        t.checks[1].met = false
        #expect(t.summaryAccessibilityText.contains("가능 시간 안 미충족"))
    }

    @Test func 요청은_한_번만_실패일_때만_풀림() {
        var lock = WorkClosingLock()
        let first = lock.begin(canClose: true)
        let second = lock.begin(canClose: true)
        #expect(first)
        #expect(!second)
        lock.finish(success: false)
        #expect(!lock.isClosing)
        _ = lock.begin(canClose: true)
        lock.finish(success: true)
        #expect(lock.isClosing)
    }
}
