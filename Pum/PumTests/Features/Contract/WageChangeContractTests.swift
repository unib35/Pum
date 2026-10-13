// UI-IOS-19c · REQ-082 · REQ-060 — 변경 계약서 받음: 원문 값 · 읽기 문구 · 금액 표기
import Testing
@testable import Pum

struct WageChangeContractTests {
    @Test func 캡처_상태는_원문_값() {
        let s = WageChangeContractState.sample
        #expect(s.sentText == "오늘 10:40")
        #expect(s.senderInitial == "박")
        #expect(s.senderText == "박민수 사장님 · 종민김밥 본점")
        #expect(s.wageHeading == "시급 · 2027년 1월 1일부터")
        #expect(s.newLabel == "1월부터")
        #expect(s.currentWageText == "10,320원")
        #expect(s.newWageText == "10,700원")
        #expect(s.workRowTitle == "근무일 · 시간 · 휴게")
        #expect(s.workRowValue == "그대로")
        #expect(s.payDayValue == "매월 10일 그대로")
        #expect(s.impactBasisText == "9월 근무 기준 · 주휴 포함")
        #expect(s.impactDifferenceText == "+16,530원")
        #expect(s.footerNotice == "서명하지 않아도 1월 1일부터 10,700원으로 계산돼요")
        #expect(WageChangeContractState.fullTitle == "계약서 전문")
        #expect(WageChangeContractState.signTitle == "서명하기")
    }

    @Test func 읽기_문구() {
        let s = WageChangeContractState.sample
        #expect(s.wageSpoken == "시급, 2027년 1월 1일부터, 지금 10,320원, 1월부터 10,700원")
        #expect(s.impactSpoken == "예상 월 급여, 9월 근무 기준 · 주휴 포함, +16,530원")
        #expect(s.sentSpoken == "결정 필요, 오늘 10:40")
    }

    @Test func 금액_표기() {
        #expect(WageChangeContractState.wonText(10_320) == "10,320원")
        #expect(WageChangeContractState.differenceText(16_530) == "+16,530원")
        #expect(WageChangeContractState.differenceText(0) == "0원")
    }
}
