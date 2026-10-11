// UI-IOS-1z — 근로계약서 확인: 7행 순서 · 문구 · 보조 줄 · 덧붙임 · 서명 활성 조건 · 부제
import Testing
@testable import Pum

struct ContractReviewTests {
    let r = ContractReviewRecord.sample

    @Test func 계약조건_7행_순서_문구() {
        #expect(r.terms.map(\.label) == ["계약 기간", "근무 장소", "업무 내용", "근무일·시간", "시급", "임금 지급일", "4대보험"])
        #expect(r.terms.map(\.value) == [
            "2026.10.05 \u{2013} 2027.04.04", "종민김밥 본점", "홀 서빙·마감",
            "월·수·금 17:00 \u{2013} 22:00", "12,000원", "매월 10일 · 계좌이체", "고용·산재 가입"])
    }

    @Test func 보조_줄과_덧붙임() {
        #expect(r.terms[3].subline == "휴게 30분 · 주 13.5시간")
        #expect(r.terms[4].suffix == " · 주휴수당 별도")
        #expect(r.terms.filter { $0.subline != nil }.count == 1)
        #expect(r.terms.filter { $0.suffix != nil }.count == 1)
    }

    @Test func 근무일시간_낭독() {
        #expect(r.terms[3].accessibilityText == "근무일·시간, 월·수·금 17:00부터 22:00, 휴게 30분, 주 13.5시간")
    }

    @Test func 서명하기는_동의해야_활성() {
        #expect(ContractReviewRecord.canSign(agreed: true))
        #expect(!ContractReviewRecord.canSign(agreed: false))
    }

    @Test func 부제_문구() {
        #expect(r.subtitleText == "종민김밥 본점 · 박민수 사장님이 보냄 · 10월 1일")
        #expect(r.statusText == "서명 대기")
    }

}
