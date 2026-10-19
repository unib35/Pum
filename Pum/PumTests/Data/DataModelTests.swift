import Foundation
import SwiftData
import Testing
@testable import Pum

@MainActor
struct DataWorkplaceEmployeeTests {
    @Test func 사업장_만들기와_목록() throws {
        let store = try DataTestStore()
        let first = try store.workplaces.create(name: "품카페", isFiveOrMore: true, deduction: .business3_3, payday: 25)
        try store.workplaces.create(name: "두번째", isFiveOrMore: false, deduction: .none, payday: 40)

        let all = try store.workplaces.all()
        #expect(all.map(\.name) == ["품카페", "두번째"])
        #expect(first.initial == "품")
        #expect(first.deduction == .business3_3)
        #expect(first.deductionRaw == "business3_3")
        #expect(all[1].payday == 31) // 1–31로 맞춘다
    }

    @Test func 사업장_고치기() throws {
        let store = try DataTestStore()
        let workplace = try store.workplaces.create(name: "품카페", isFiveOrMore: false, deduction: .none, payday: 10)
        try store.workplaces.update(workplace) {
            $0.isFiveOrMore = true
            $0.deduction = .business3_3
            $0.payday = 0
        }
        let saved = try #require(try store.workplaces.all().first)
        #expect(saved.isFiveOrMore)
        #expect(saved.deduction == .business3_3)
        #expect(saved.payday == 1)
    }

    @Test func 직원_만들기와_목록_퇴사자_거르기() throws {
        let store = try DataTestStore(today: 20261019)
        let workplace = try store.workplaces.create(name: "품카페", isFiveOrMore: false, deduction: .none, payday: 10)
        let other = try store.workplaces.create(name: "다른곳", isFiveOrMore: false, deduction: .none, payday: 10)
        try store.employees.create(in: workplace, name: "김민지", phone: "01012345678", birthDayKey: 20000101,
                                   hireDayKey: 20260101, colorIndex: 2, memo: "주말")
        let left = try store.employees.create(in: workplace, name: "이서준", phone: nil, birthDayKey: nil,
                                              hireDayKey: 20260101, colorIndex: 3, memo: "")
        try store.employees.create(in: other, name: "박다른", phone: nil, birthDayKey: nil,
                                   hireDayKey: 20260101, colorIndex: 0, memo: "")
        try store.employees.update(left) { $0.leaveDayKey = 20260930 }

        #expect(try store.employees.list(in: workplace, includeLeft: true).map(\.name) == ["김민지", "이서준"])
        #expect(try store.employees.list(in: workplace, includeLeft: false).map(\.name) == ["김민지"])
        let kim = try #require(try store.employees.list(in: workplace, includeLeft: false).first)
        #expect(kim.phone == "01012345678")
        #expect(kim.colorIndex == 2)
        #expect(kim.workplace?.name == "품카페")
    }

    @Test func 계약서_사진_저장() throws {
        let store = try DataTestStore()
        let (_, employee) = try store.makeEmployee()
        let photo = try store.employees.addContractPhoto(Data([1, 2, 3]), to: employee)
        #expect(employee.contractPhotos?.count == 1)
        #expect(photo.imageData == Data([1, 2, 3]))
        try store.employees.deleteContractPhoto(photo)
        #expect(try store.count(ContractPhoto.self) == 0)
    }
}

@MainActor
struct DataWorkTermsTests {
    @Test func 날짜에_맞는_근로조건_고르기() throws {
        let store = try DataTestStore()
        let (_, employee) = try store.makeEmployee(hireDayKey: 20260101)
        try store.employees.addTerms(WorkTerms(effectiveFromDayKey: 20260701, wageType: .monthly, amount: 2_200_000,
                                               workWeekdays: [1, 2, 3], startMinute: 600, endMinute: 1140,
                                               breakMinutes: 60), to: employee)

        #expect(employee.terms(on: 20251231) == nil) // 입사 전
        #expect(employee.terms(on: 20260101)?.amount == 10_320)
        #expect(employee.terms(on: 20260630)?.wageType == .hourly)
        #expect(employee.terms(on: 20260701)?.wageType == .monthly)
        #expect(employee.terms(on: 20261019)?.amount == 2_200_000)
        #expect(try store.employees.termsHistory(of: employee).map(\.effectiveFromDayKey) == [20260101, 20260701])
    }

    @Test func 고르기_순수함수_순서와_무관() {
        let items = [(20260701, "b"), (20260101, "a"), (20261101, "c")]
        #expect(WorkTermsPicker.pick(items, on: 20260815) { $0.0 }?.1 == "b")
        #expect(WorkTermsPicker.pick(items, on: 20261101) { $0.0 }?.1 == "c")
        #expect(WorkTermsPicker.pick(items, on: 20251231) { $0.0 } == nil)
    }

    @Test func 근무요일은_1에서_7만_정렬해_저장() {
        let terms = WorkTerms(effectiveFromDayKey: 20260101, wageType: .hourly, amount: 10_320,
                              workWeekdays: [5, 1, 9, 0, 3], startMinute: 540, endMinute: 1080, breakMinutes: 60)
        #expect(terms.workWeekdaysRaw == [1, 3, 5])
        #expect(terms.workWeekdays == [1, 3, 5])
        #expect(terms.wageTypeRaw == "hourly")
    }
}

@MainActor
struct DataSeoulDayKeyTests {
    @Test func 요일과_달_길이() {
        #expect(SeoulDayKey.weekday(20261001) == 4) // 목
        #expect(SeoulDayKey.weekday(20260201) == 7) // 일
        #expect(SeoulDayKey.daysInMonth(year: 2026, month: 2) == 28)
        #expect(SeoulDayKey.daysInMonth(year: 2028, month: 2) == 29)
        #expect(SeoulDayKey.daysInMonth(year: 2026, month: 12) == 31)
        #expect(SeoulDayKey.keys(year: 2026, month: 4).last == 20260430)
    }

    @Test func 서울_시간으로_날짜_키() {
        // 2026-10-18 15:30 UTC = 2026-10-19 00:30 서울
        let date = Date(timeIntervalSince1970: 1_792_337_400)
        #expect(SeoulDayKey.from(date) == 20261019)
    }
}
