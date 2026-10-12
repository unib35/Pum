// UI-IOS-9a · REQ-051 — 필요 인력 입력: 스테퍼 경계 · 요일별 시간대 · 추천 요청 한 번만 · 원문 문구
import Testing
import Foundation
@testable import Pum

struct StaffingNeedsTests {
    @Test func 원문_문구() {
        let s = StaffingNeedsState.sample
        #expect(s.weekText == "10월 12일 \u{2013} 18일")
        #expect(s.sectionTitle == "토요일 \u{00B7} 필요 인력")
        #expect(s.selectedSlots.map(\.rangeText) == ["11:00 \u{2013} 14:00", "14:00 \u{2013} 18:00", "18:00 \u{2013} 22:00"])
        #expect(s.selectedSlots.map(\.count) == [2, 3, 4])
        #expect(s.days.map(\.date) == [12, 13, 14, 15, 16, 17, 18])
        #expect(s.days[5].spoken == "10월 17일 토요일")
        #expect(s.selectedSlots[0].spokenRange == "11:00부터 14:00까지")
        #expect(s.conditions.count == 9)
        #expect(s.missingSubtitle == "김하늘 \u{00B7} 정우진 \u{2014} 입력 전엔 기존 스케줄만 써요")
    }

    @Test func 스테퍼_하한_0() {
        var s = StaffingNeedsState.sample
        let id = s.selectedSlots[0].id // 2명
        let a = s.step(slot: id, by: -1)
        let b = s.step(slot: id, by: -1)
        #expect(a && b)
        let atZero = s.slots.first { $0.id == id }!
        #expect(atZero.count == 0)
        #expect(!s.canDecrement(atZero))
        let changed = s.step(slot: id, by: -1)
        #expect(!changed)
        #expect(s.slots.first { $0.id == id }?.count == 0)
    }

    @Test func 스테퍼_상한은_서버_값() {
        var s = StaffingNeedsState.sample
        s.maxPerSlot = 5
        let id = s.selectedSlots[2].id // 4명
        let a = s.step(slot: id, by: 1)
        #expect(a)
        let atMax = s.slots.first { $0.id == id }!
        #expect(atMax.count == 5)
        #expect(!s.canIncrement(atMax))
        let changed = s.step(slot: id, by: 1)
        #expect(!changed)
        #expect(s.slots.first { $0.id == id }?.count == 5)
        #expect(StaffingNeedsState.defaultMaxPerSlot == 10)
    }

    @Test func 요일을_고르면_그_요일_시간대만() {
        var s = StaffingNeedsState.sample
        s.slots.append(StaffingSlot(id: 9, day: 0, startMinutes: 9 * 60, endMinutes: 12 * 60, count: 1))
        s.select(day: 0)
        #expect(s.selectedDay == 0)
        #expect(s.sectionTitle == "월요일 \u{00B7} 필요 인력")
        #expect(s.selectedSlots.map(\.id) == [9])
        s.select(day: 6)
        #expect(s.selectedSlots.isEmpty)
        s.select(day: 99) // 없는 요일은 무시
        #expect(s.selectedDay == 6)
    }

    @Test func 다른_요일_값은_그대로() {
        var s = StaffingNeedsState.sample
        s.slots.append(StaffingSlot(id: 9, day: 0, startMinutes: 9 * 60, endMinutes: 12 * 60, count: 1))
        let changed = s.step(slot: 9, by: 1)
        #expect(changed)
        #expect(s.selectedSlots.map(\.count) == [2, 3, 4])
        #expect(s.slots.first { $0.id == 9 }?.count == 2)
    }

    @Test func 추천_요청은_한_번만() {
        var s = StaffingNeedsState.sample
        #expect(s.canRecommend)
        let first = s.beginRecommend()
        #expect(first)
        let second = s.beginRecommend()
        #expect(!second)
        #expect(!s.canRecommend)
        s.endRecommend() // 실패일 때만 풀림
        let third = s.beginRecommend()
        #expect(third)
    }
}
