// UI-IOS-6l · REQ-091 — 활동 기록: 원문 값 · 묶음 순서 · 읽기 문구 · 유형별 배지
import Testing
@testable import Pum

struct ActivityLogTests {
    let state = ActivityLogState.sample

    @Test func 원문_값_그대로() {
        #expect(state.searchPlaceholder == "직원 이름 · 내용 검색")
        #expect(state.dropdowns.map(\.title) == ["전체 직원", "2026년 10월", "유형"])
        #expect(state.quickFilters.map(\.title) == ["확인 필요만", "연장근무만", "수정 요청만"])
        #expect(state.quickFilters.allSatisfy { !$0.isOn })
        #expect(state.footerNote == "근무 · 계약 · 급여 변경은 수정하거나 지울 수 없는 기록으로 남아요.")
        let first = state.days[0].entries[0]
        #expect(first.title == "10월 급여 확정 · 4명 4,210,000원")
        #expect(first.actorText == "박민수 · 대표")
    }

    @Test func 묶음_순서와_건수() {
        #expect(state.days.map(\.title) == ["10월 10일 금", "10월 4일 일", "10월 3일 토"])
        #expect(state.days.map { $0.entries.count } == [1, 2, 2])
        #expect(state.days.flatMap(\.entries).map(\.timeText) == ["13:21", "10:02", "09:13", "22:31", "16:41"])
    }

    @Test func 읽기_문구() {
        #expect(state.days[0].entries[0].accessibilityText == "13시 21분, 10월 급여 확정 · 4명 4,210,000원, 박민수 · 대표, 급여")
        #expect(state.days[1].entries[1].spokenTime == "9시 13분")
        let onHour = ActivityEntry(id: "x", timeText: "09:00", title: "t", actorText: "a", kind: .work)
        #expect(onHour.spokenTime == "9시")
        let odd = ActivityEntry(id: "y", timeText: "?", title: "t", actorText: "a", kind: .work)
        #expect(odd.spokenTime == "?")
    }

    @Test func 유형별_배지_글자() {
        #expect(ActivityKind.payroll.label == "급여")
        #expect(ActivityKind.work.label == "근무")
        #expect(ActivityKind.contract.label == "계약")
        #expect(state.days.flatMap(\.entries).map(\.kind) == [.payroll, .work, .work, .work, .contract])
    }
}
