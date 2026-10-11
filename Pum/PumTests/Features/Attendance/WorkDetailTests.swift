// UI-IOS-1h — 근무 상세 계산 근거(REQ-071) · 타임라인 위치
import Foundation
import Testing
@testable import Pum

struct WorkDetailTests {
    let r = WorkDetailRecord.sample

    @Test func 인정_근무는_실제_근무에서_휴게를_뺀다() {
        #expect(r.recognizedMinutes == 303) // (22:31 − 16:58) − 30분
        #expect(r.recognizedText == "5시간 03분")
    }

    @Test func 기본급은_시급_곱하기_인정_분_나누기_60_정수_원() {
        #expect(r.basePay == 60_600)
        #expect(r.basePayText == "60,600원")
        var odd = r
        odd.hourlyWage = 10_030 // 10,030 × 303 ÷ 60 = 50,651.5 → 버림
        #expect(odd.basePay == 50_651)
    }

    @Test func 문구는_원문_그대로() {
        #expect(r.subtitle == "종민김밥 본점 · 시급 12,000원")
        #expect(r.plannedRange == "17:00 \u{2013} 22:00")
        #expect(r.actualRange == "16:58 \u{2013} 22:31")
        #expect(r.breakText == "30분")
        #expect(r.timelineLabel == "예정 17:00–22:00, 실제 16:58–22:31, 휴게 30분")
    }

    @Test func 타임라인_축은_16시에서_23시_눈금_8개() {
        let a = WorkTimelineAxis()
        #expect(a.tickLabels == ["16:00", "17:00", "18:00", "19:00", "20:00", "21:00", "22:00", "23:00"])
        #expect(a.position(16 * 60) == 0)
        #expect(a.position(23 * 60) == 1)
        #expect(abs(a.position(19 * 60 + 30) - 3.5 / 7) < 0.0001)
        #expect(a.position(10 * 60) == 0 && a.position(23 * 60 + 40) == 1)
    }

    @Test func 막대와_휴게_구간_위치() {
        let a = WorkTimelineAxis()
        let planned = a.span(r.plannedStart, r.plannedEnd)
        #expect(abs(planned.start - 1.0 / 7) < 0.0001 && abs(planned.length - 5.0 / 7) < 0.0001)
        let actual = a.span(r.actualStart, r.actualEnd)
        #expect(abs(actual.start - 58.0 / 420) < 0.0001)
        let br = a.span(r.breakStart, r.breakStart + r.breakMinutes)
        #expect(abs(br.start - 210.0 / 420) < 0.0001 && abs(br.length - 30.0 / 420) < 0.0001)
        #expect(br.start >= actual.start && br.start + br.length <= actual.start + actual.length)
    }
}
