// UI-IOS-10h · REQ-075 — 직원 정정 명세서: 서버 값 그대로 · 원문 문구 · 읽기 문구
import Testing
import Foundation
@testable import Pum

struct CorrectedPayslipTests {
    let s = CorrectedPayslipState.sample

    @Test func 원문_문구() {
        #expect(s.headerCaption == "급여명세서 \u{00B7} 2026년 8월분")
        #expect(s.beforeText == "1,062,000")
        #expect(s.afterText == "1,084,800")
        #expect(s.deltaText == "+22,800")
        #expect(s.payoutNote == "차액은 9월 급여(10월 10일)에 함께 지급돼요")
        #expect(s.correctionCountText == "1회")
        #expect(s.records[0].titleText == "8월 28일 금 \u{00B7} 퇴근")
        #expect(s.records[0].impactText == "연장 \u{00B7} 야간 1시간")
    }

    @Test func 읽기_문구() {
        #expect(s.netAccessibility == "실지급액, 1,062,000원에서 1,084,800원")
        #expect(s.records[0].accessibilityText == "8월 28일 금요일 퇴근, 오후 10시에서 오후 11시로, 사업주 정정, 연장 \u{00B7} 야간 1시간")
        #expect(s.reasonAccessibility == "정정 사유, 내 수정 요청(10월 1일) 반영, 마감 청소 1시간 추가 근무")
    }

    @Test func 시각_읽기() {
        #expect(CorrectedRecord.spokenTime("09:30") == "오전 9시 30분")
        #expect(CorrectedRecord.spokenTime("00:00") == "오전 12시")
        #expect(CorrectedRecord.spokenTime("12:00") == "오후 12시")
    }
}
