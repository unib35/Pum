// UI-IOS-20e · 20f — MVP 근무 목록 · 하루 고치기 저장 규칙
import Foundation
import Testing
@testable import Pum

@MainActor
struct SoloWorkMonthTests {
    // makeEmployee: 월–금 09:00–18:00, 휴게 60분, 2026-01-01 입사
    private func setUp() throws -> (DataTestStore, Employee, WorkDayFixUseCase) {
        let store = try DataTestStore()
        let (_, employee) = try store.makeEmployee()
        try store.workDays.fillScheduled(for: employee, year: 2026, month: 10)
        let useCase = WorkDayFixUseCase(workDays: store.workDays, now: { Date(timeIntervalSince1970: 0) })
        return (store, employee, useCase)
    }

    @Test func 날짜_id() {
        #expect(SoloWorkMonth.dayID(20261007) == "2026-10-07")
        #expect(SoloWorkMonth.dayKey("2026-10-07") == 20261007)
        #expect(SoloWorkMonth.dateText(20261007) == "10월 7일 수")
    }

    @Test func 예정대로_고침_결근_쉬는날_예정_행() throws {
        let (store, employee, useCase) = try setUp()
        defer { withExtendedLifetime(store) {} }
        try useCase.execute(.worked(start: 480, end: 1080, breakMinutes: 60), reason: "", for: employee, on: 20261007)
        try useCase.execute(.absent, reason: "병원", for: employee, on: 20261008)
        try useCase.execute(.dayOff, reason: "", for: employee, on: 20261009)

        let state = SoloWorkMonth.staffState(employee, year: 2026, month: 10, today: 20261019)
        #expect(state.isSolo)
        #expect(state.summaryText == "월–금 09–18 · 10,320원")
        #expect(state.sectionTitle == "10월 근무")
        let rows = Dictionary(uniqueKeysWithValues: state.days.map { ($0.id, $0) })
        #expect(rows["2026-10-06"]?.status == .asPlanned)
        #expect(rows["2026-10-06"]?.durationText == "8시간")
        #expect(rows["2026-10-07"]?.status == .edited)
        #expect(rows["2026-10-07"]?.extraText == "+1시간")
        #expect(rows["2026-10-08"]?.timeText == "결근")
        #expect(rows["2026-10-09"]?.timeText == "쉬는 날")
        #expect(rows["2026-10-20"]?.status == .upcoming)
        // 쉬는 날은 기록이 남아 다시 채워도 되살아나지 않는다
        #expect(try store.workDays.fillScheduled(for: employee, year: 2026, month: 10) == 0)
    }

    @Test func 근무_요일이_아니면_추가_근무() throws {
        let (store, employee, useCase) = try setUp()
        defer { withExtendedLifetime(store) {} }
        let day = try useCase.execute(.worked(start: 600, end: 840, breakMinutes: 0), reason: "", for: employee, on: 20261010)
        #expect(day.status == .extra)
        let row = SoloWorkMonth.row(day, employee: employee, today: 20261019)
        #expect(row.noteText == "추가 근무")
        #expect(row.extraText == "+4시간")
    }

    @Test func 시트_처음_값() throws {
        let (store, employee, useCase) = try setUp()
        defer { withExtendedLifetime(store) {} }
        let planned = SoloWorkMonth.sheetState(employee, dayKey: 20261006)
        #expect(planned.initialKind == .worked)
        #expect(planned.initialStart == "09:00")
        #expect(planned.plannedText == "예정 09:00 – 18:00 · 휴게 1시간")
        #expect(planned.isSolo)
        let weekend = SoloWorkMonth.sheetState(employee, dayKey: 20261010)
        #expect(weekend.initialKind == .dayOff)
        #expect(weekend.plannedText == "예정 근무 없는 날")
        try useCase.execute(.absent, reason: "병원", for: employee, on: 20261008)
        let absent = SoloWorkMonth.sheetState(employee, dayKey: 20261008)
        #expect(absent.initialKind == .absent)
        #expect(absent.initialReason == "병원")
    }

    @Test func 미리보기는_예정과의_차이() throws {
        let (store, employee, _) = try setUp()
        defer { withExtendedLifetime(store) {} }
        let input = DayFixInput(dayID: "2026-10-07", kind: .worked, start: "08:00", end: "18:00", breakMinutes: 60, reason: "")
        let p = try #require(SoloWorkMonth.preview(input, employee: employee))
        #expect(p.recognizedText == "9시간")
        #expect(p.deltaText == "+1시간")
        #expect(p.deltaDetail == nil)
        let absent = DayFixInput(dayID: "2026-10-07", kind: .absent, start: nil, end: nil, breakMinutes: nil, reason: "")
        #expect(SoloWorkMonth.preview(absent, employee: employee) == nil)
    }
}
