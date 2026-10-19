// DEC-031 · DEC-033 — MVP 직원 등록 · 목록 문구
import Foundation
import Testing
@testable import Pum

struct SoloFormatTests {
    @Test func 요일_표기() {
        #expect(SoloFormat.weekdays([1, 3, 5]) == "월·수·금")
        #expect(SoloFormat.weekdays([1, 2, 3, 4, 5]) == "월–금")
        #expect(SoloFormat.weekdays([6, 7]) == "토·일")
        #expect(SoloFormat.weekdays([]) == "")
    }

    @Test func 시간_표기() {
        #expect(SoloFormat.hours(start: 1020, end: 1320) == "17–22")
        #expect(SoloFormat.hours(start: 570, end: 1080) == "09:30–18")
        #expect(SoloFormat.hours(start: 1320, end: 1560) == "22–02")
        #expect(SoloFormat.breakAndDuration(start: 1020, end: 1320, breakMinutes: 30) == "휴게 30분 · 하루 4시간 30분")
        #expect(SoloFormat.breakAndDuration(start: 540, end: 600, breakMinutes: 0) == "휴게 없음 · 하루 1시간")
    }

    @Test func 날짜_표기() {
        #expect(SoloFormat.date(20260701) == "2026. 7. 1 수")
    }

    @Test func 최저임금() {
        #expect(MinimumWage.hourly(year: 2026) == 10_320)
        #expect(MinimumWage.hourly(year: 2030) == 10_320) // 고시 전에는 마지막 값
    }
}

struct SoloRegisterStateTests {
    @Test func 휴대폰은_MVP에서_선택() {
        let draft = DirectRegisterBasicDraft(name: "김민지", phone: "")
        #expect(!DirectRegisterBasicState.empty.canProceed(draft))
        var solo = DirectRegisterBasicState.empty
        solo.isSolo = true
        #expect(solo.canProceed(draft))
        #expect(!solo.canProceed(.init(name: " ", phone: "")))
    }

    @Test func 월급은_최저시급_곱하기_209와_비교() {
        let state = DirectRegisterTermsState.soloSample
        var draft = DirectRegisterTermsDraft(hourlyWage: 10_320 * 209, weekdays: [1], isMonthly: true)
        #expect(state.minimumAmount(draft) == 2_156_880)
        #expect(state.canProceed(draft))
        #expect(state.minimumText(draft) == "최저 월 2,156,880원")
        draft.hourlyWage -= 1
        #expect(state.isBelowMinimum(draft))
        #expect(!state.canProceed(draft))
        #expect(state.value(draft).isMonthly)
    }

    @Test func 계약서_사진은_MVP에서_선택() {
        let empty = DirectRegisterContractState.empty
        #expect(!empty.canRegister(empty.initialDraft))
        let solo = DirectRegisterContractState(photos: [], method: .photo, copyGiven: false, isSolo: true)
        #expect(solo.canRegister(solo.initialDraft))
    }
}

@MainActor
struct RegisterEmployeeUseCaseTests {
    private func registration(hire: Int) -> EmployeeRegistration {
        EmployeeRegistration(name: "김민지", phone: nil, hireDayKey: hire, wageType: .monthly, amount: 2_200_000,
                             weekdays: [1, 2, 3, 4, 5], startMinute: 540, endMinute: 1080, breakMinutes: 60,
                             contractPhotos: [Data([1, 2, 3])])
    }

    @Test func 직원_조건_사진을_저장하고_이번_달을_채운다() throws {
        let store = try DataTestStore()
        let workplace = try store.workplaces.create(name: "품카페", isFiveOrMore: false, deduction: .none, payday: 10)
        let useCase = RegisterEmployeeUseCase(employees: store.employees, workDays: store.workDays, today: { 20261019 })

        let employee = try useCase.execute(registration(hire: 20261001), in: workplace)

        #expect(employee.workplace?.name == "품카페")
        let terms = try #require(employee.terms(on: 20261019))
        #expect(terms.wageType == .monthly)
        #expect(terms.amount == 2_200_000)
        #expect(employee.contractPhotos?.count == 1)
        // 2026년 10월 평일 22일
        #expect(try store.workDays.days(of: employee, year: 2026, month: 10).count == 22)
    }

    @Test func 입사_전이면_근무를_채우지_않는다() throws {
        let store = try DataTestStore()
        let workplace = try store.workplaces.create(name: "품카페", isFiveOrMore: false, deduction: .none, payday: 10)
        let useCase = RegisterEmployeeUseCase(employees: store.employees, workDays: store.workDays, today: { 20261019 })

        let employee = try useCase.execute(registration(hire: 20261101), in: workplace)

        #expect(try store.workDays.days(of: employee, year: 2026, month: 10).isEmpty)
    }

    @Test func 목록_행_문구() throws {
        let store = try DataTestStore()
        let (_, employee) = try store.makeEmployee()
        let member = SoloStaffListScreen.member(employee, today: 20261019)
        #expect(member.scheduleText == "월–금 09–18")
        #expect(member.wageText == "10,320")
        #expect(member.wageUnit == "원/h")
        #expect(!member.showsStatus)
    }
}
