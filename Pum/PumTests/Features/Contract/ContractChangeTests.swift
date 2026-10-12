// UI-IOS-10c · REQ-060 — 변경 계약서: 원문 값 · 영향 basis 규칙 · 고정 안내 · 한 번만 보내기 · 음성 안내문
import Testing
@testable import Pum

struct ContractChangeTests {
    @Test func 캡처_상태는_원문_값() {
        let s = ContractChangeState.sample
        #expect(s.employeeName == "김하늘")
        #expect(s.subtitle == "현재 계약 · 2026.10.6부터")
        #expect(s.oldWageText == "11,500")
        #expect(s.newWageText == "12,000원")
        #expect(s.unchangedTitle == "그대로인 조건 7개")
        #expect(s.unchangedSummary == "근무 요일 · 시간 · 휴게 · 급여일 …")
        #expect(s.nextPeriodTitle == "11월 1일부터")
        #expect(s.impactTitle == "11월 예상 급여")
        #expect(ContractChangeState.beforeSignTitle == "서명 전까지")
        #expect(ContractChangeState.beforeSignValue == "기존 조건으로 계산")
        #expect(s.hasChanges)
    }

    @Test func 영향은_basis가_같을_때만_보인다() {
        var s = ContractChangeState.sample
        let impact = s.visibleImpact(for: .nextPeriod)
        #expect(impact?.detailText == "근무 78시간 + 주휴 포함")
        #expect(ContractChangeState.differenceText(impact?.differenceWon ?? 0) == "+47,000원")
        #expect(s.visibleImpact(for: .custom) == nil)
        s.basis.newHourlyWon = 12_500
        #expect(s.visibleImpact(for: .nextPeriod) == nil)
    }

    @Test func 차이_글자는_부호만_붙인다() {
        #expect(ContractChangeState.differenceText(-3_000) == "\u{2212}3,000원")
        #expect(ContractChangeState.differenceText(0) == "0원")
    }

    @Test func 바뀐_조건이_없으면_변경_없음() {
        var s = ContractChangeState.sample
        s.basis.newHourlyWon = s.currentHourlyWon
        #expect(!s.hasChanges)
    }

    @Test func 보내기는_한_번만_실패일_때만_푼다() {
        var lock = ContractChangeSendLock()
        let first = lock.begin()
        let second = lock.begin()
        #expect(first)
        #expect(!second)
        lock.finish(success: true)
        #expect(lock.isSending)
        lock.finish(success: false)
        #expect(!lock.isSending)
        let again = lock.begin()
        #expect(again)
    }

    @Test func 음성_안내문() {
        let s = ContractChangeState.sample
        #expect(s.wageSpoken == "시급, 11,500원에서 12,000원으로")
        #expect(s.unchangedSpoken == "그대로인 조건 7개, 근무 요일 · 시간 · 휴게 · 급여일 …")
        #expect(ContractChangeState.startSpoken(title: "11월 1일부터", detail: "다음 급여 기간 시작일", isOn: true)
                == "11월 1일부터, 다음 급여 기간 시작일, 선택됨")
        #expect(ContractChangeState.startSpoken(title: "날짜 직접 선택", detail: nil, isOn: false)
                == "날짜 직접 선택, 선택 안 됨")
    }
}
