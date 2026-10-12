// UI-IOS-10p · REQ-073 — 휴가 · 퇴직 설정: 원문 값 · 선택지 · 저장 값 · 한 번만 저장 · 음성 안내문
import Testing
@testable import Pum

struct LeaveRetirementTests {
    @Test func 캡처_상태는_원문_값() {
        let s = LeaveRetirementState.sample
        #expect(s.headcountText == "상시 근로자 5.4명 · 5인 이상")
        #expect(s.judgmentText == "10월 1일 자동 판정 · 법정 연차 적용")
        #expect(s.leaveHeader == "연차 · 대상은 주 15시간 이상 직원")
        #expect(s.promotionDetail == "기한 전 서면 통지 · 노무 검토 권장")
        #expect(s.retirementOptions.map(\.title) == ["퇴직금", "퇴직연금 DB형", "퇴직연금 DC형"])
        #expect(s.settings == LeaveRetirementSettings(basisText: "입사일 기준", hourlyUse: true, promotion: false,
                                                      agreedLeave: false, retirement: .severance))
        #expect(LeaveRetirementState.notice == "법정 기준보다 적게는 설정할 수 없어요")
    }

    @Test func 퇴직급여는_서버_선택지만_받는다() {
        var state = LeaveRetirementState.sample
        state.retirementOptions.removeLast()
        var d = LeaveRetirementDraft(state.settings)
        d.select(.definedContribution, in: state)
        #expect(d.retirement == .severance)
        d.select(.definedBenefit, in: state)
        #expect(d.retirement == .definedBenefit)
    }

    @Test func 저장하는_값은_방식과_서버_기준일() {
        var d = LeaveRetirementDraft(LeaveRetirementState.sample.settings)
        d.hourlyUse = false
        d.promotion = true
        d.select(.definedBenefit, in: .sample)
        #expect(d.settings(basisText: "입사일 기준")
                == LeaveRetirementSettings(basisText: "입사일 기준", hourlyUse: false, promotion: true,
                                           agreedLeave: false, retirement: .definedBenefit))
    }

    @Test func 저장은_처리_중에만_한_번() {
        var lock = LeaveRetirementLock()
        let first = lock.begin()
        let second = lock.begin()
        #expect(first)
        #expect(!second)
        lock.finish()
        #expect(!lock.isSaving)
        let third = lock.begin()
        #expect(third)
    }

    @Test func 음성_안내문() {
        let s = LeaveRetirementState.sample
        #expect(s.optionAccessibility(s.retirementOptions[0], isOn: true)
                == "퇴직금, 퇴사 때 평균임금 30일분 × 근속연수, 선택됨, 3개 중 1번째")
        #expect(s.optionAccessibility(s.retirementOptions[2], isOn: false)
                == "퇴직연금 DC형, 매년 적립 · 앱은 적립 할 일만 알려요, 3개 중 3번째")
    }
}
