// UI-IOS-1ah — 근무기록 삭제 시트: 시트 제목 · 확정 전/후 메뉴 · 사람 줄 · 안내 문구
import Testing
@testable import Pum

struct OwnerRecordActionsTests {
    let s = OwnerRecordActionsState.sample

    @Test func 시트_제목과_사람_줄_문구() {
        #expect(s.sheetTitle == "정우진 \u{00B7} 10월 1일 근무기록")
        #expect(s.personTitle == "정우진 \u{00B7} 10월 1일 목")
        #expect(s.subtitleText == "13:00 \u{2013} 17:00 \u{00B7} 4시간 \u{00B7} 48,000원")
        #expect(s.personAccessibilityText == "정우진 \u{00B7} 10월 1일 목, 13:00 \u{2013} 17:00 \u{00B7} 4시간 \u{00B7} 48,000원, 예정 없는 근무")
    }

    @Test func 확정_전_메뉴는_세_개_삭제는_빨강() {
        #expect(s.menu.map(\.title) == ["시간 수정", "결근 처리", "기록 삭제"])
        #expect(s.menu.map(\.isDestructive) == [false, false, true])
        #expect(OwnerRecordAction.delete.accessibilityHint == "사유를 남기고 삭제해요")
        #expect(OwnerRecordAction.editTime.accessibilityHint == nil)
    }

    @Test func 확정_후에는_삭제_숨김() {
        var x = s
        x.isPayrollConfirmed = true
        #expect(x.menu == [.editTime, .markAbsent])
    }

    @Test func 안내_카드_문구() {
        #expect(s.guideText == "삭제 규칙 \u{2014} 급여 확정 전 기록은 사유를 남기고 삭제할 수 있어요(직원에게 알림). 이미 확정\u{00B7}지급된 급여에 포함된 기록은 삭제 대신 정정 내역으로 남고 다음 급여에서 조정돼요.")
        #expect(OwnerRecordActionsState.cancelText == "취소")
        #expect(s.recordMethod == "매장 QR")
        #expect(s.payrollStatusText == "아직 확정 전")
    }
}
