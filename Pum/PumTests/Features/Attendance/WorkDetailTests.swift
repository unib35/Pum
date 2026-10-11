// UI-IOS-1h — 근무 상세 계산 근거(REQ-071) · 타임라인 위치
import Foundation
import Testing
@testable import Pum

struct WorkDetailTests {
    let r = WorkDetailRecord.sample

    @Test func 엔진_값을_그대로_표시() {
        #expect(r.recognizedText == "5시간 03분")
        #expect(r.basePayText == "60,600원")
        // 샘플 값이 계산 규칙(실제 − 휴게, 시급 × 분 ÷ 60 버림)과 맞는지 — 규칙 자체는 서버 엔진 테스트(TC)에서
        let expectedMinutes = (r.actualEnd - r.actualStart) - r.breakMinutes
        #expect(r.recognizedMinutes == expectedMinutes)
        #expect(r.basePay == r.hourlyWage * expectedMinutes / 60)
    }

    @Test func 딱_떨어지는_시간은_N시간() {
        var x = r
        x.breakMinutes = 60
        x.recognizedMinutes = 300
        #expect(x.breakText == "1시간")
        #expect(x.recognizedText == "5시간")
    }

    @Test func 이력_ID는_같은_시각이어도_겹치지_않는다() {
        let ids = r.history.map(\.id)
        #expect(Set(ids).count == ids.count)
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
