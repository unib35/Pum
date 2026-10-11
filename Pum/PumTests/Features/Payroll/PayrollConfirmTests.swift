// UI-IOS-1v — 시트 제목 · 요약 · 점 목록 · 토글 기본값
import Testing
@testable import Pum

struct PayrollConfirmTests {
    let s = PayrollConfirmState.sample

    @Test func 제목은_월에서() {
        #expect(s.sheetTitle == "10월 급여를 확정할까요?")
        var n = s
        n.month = 11
        #expect(n.sheetTitle == "11월 급여를 확정할까요?" && n.expectedTitle == "11월 총 지급 예정")
    }

    @Test func 요약_문구() {
        #expect(s.amountText == "4,210,000원")
        #expect(s.summaryLeft == "직원 4명 \u{00B7} 근무기록 68건")
        #expect(s.summaryRight == "지급일 11월 10일")
        #expect(s.checkedTitle == "근무기록 68건 모두 확인됐어요")
        #expect(s.yearMonthTitle == "2026년 10월")
    }

    @Test func 점_목록() {
        #expect(s.notes.count == 2)
        #expect(s.notes[0].text == "확정하면 사용된 근무기록 68건이 기준 데이터로 고정돼요")
        #expect(s.notes[0].bold == "고정" && s.notes[1].bold == "정정 내역")
        #expect(s.notes[1].text == "이후 변경이 필요하면 기록을 바꾸지 않고 정정 내역으로 남아요")
    }

    @Test func 토글_기본값과_바꾸기() {
        #expect(s.sendsPayslip && s.remindsPayDay && !s.isConfirming)
        var n = s
        n.sendsPayslip = false
        #expect(!n.sendsPayslip && n.remindsPayDay && n != s)
        #expect(s.payslipAccessibilityLabel == "직원에게 급여명세서 보내기, 카카오 알림톡, 앱 알림")
        #expect(s.reminderAccessibilityLabel == "지급 예정일 알림 받기, 11월 9일 오전 9시")
    }
}
