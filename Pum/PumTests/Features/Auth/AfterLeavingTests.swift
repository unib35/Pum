// UI-IOS-10o · REQ-080 — 퇴사 후: 서버 값 표시 · 읽기 문구
import Testing
import Foundation
@testable import Pum

struct AfterLeavingTests {
    let s = AfterLeavingState.sample

    @Test func 원문_문구() {
        #expect(s.workplaceName == "종민김밥 본점")
        #expect(s.leftTitle == "2026년 10월 31일 퇴사")
        #expect(s.periodText == "2025.8.18 \u{2013} 2026.10.31 \u{00B7} 1년 2개월")
        #expect(s.statusText == "소속 종료")
        #expect(s.payItems.map(\.title) == ["10월 급여", "퇴직금", "미사용 연차 수당"])
        #expect(s.documents.map(\.valueText) == ["1건", "15장", "2025.8 \u{2013} 2026.10"])
        #expect(s.retentionNote == "계약서 \u{00B7} 명세서 \u{00B7} 근무기록은 퇴사 후 3년간 보관돼요.")
    }

    @Test func 금액은_정수_원_상태는_서버_글자() {
        #expect(s.payItems.map { $0.amount.text } == ["880,000원", "계산 중", "88,000원"])
        #expect(s.payItems[1].amount.isStatus)
        #expect(!s.payItems[0].amount.isStatus)
    }

    @Test func 읽기_문구() {
        #expect(s.payItems[1].spoken == "퇴직금, 계산 중, 사업주 확정 후 알려드려요")
        #expect(s.payItems[0].spoken == "10월 급여, 지급 대기 \u{00B7} 11월 14일까지, 880,000원")
        #expect(s.documents[1].spoken == "급여명세서, 15장")
        #expect(s.headerSpoken == "2026년 10월 31일 퇴사, 2025.8.18 \u{2013} 2026.10.31 \u{00B7} 1년 2개월, 소속 종료")
        #expect(s.certificateSpoken == "경력증명서 요청, 근무 기간 \u{00B7} 업무 \u{00B7} 사업주 확인")
    }

    @Test func 문서_종류() {
        #expect(s.documents.map(\.kind) == [.contract, .payslip, .workRecord])
    }
}
