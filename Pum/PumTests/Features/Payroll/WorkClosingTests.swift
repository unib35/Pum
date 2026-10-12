// UI-IOS-8a · REQ-028 · REQ-070 — 근무 마감 문구 · 마감 가능 조건
import Testing
@testable import Pum

struct WorkClosingTests {
    let s = WorkClosingState.sample

    @Test func 원문_문구() {
        #expect(s.title == "10월 근무 마감")
        #expect(s.subtitle == "종민김밥 본점 \u{00B7} 10월 1일 \u{2013} 31일")
        #expect(s.normalText == "정상 71건" && s.problemText == "처리 필요 5건")
        #expect(s.employeeText == "5명" && s.recordText == "76건" && s.totalWorkText == "382h 20m")
        #expect(s.reviewTitle == "문제 있는 기록 5건 확인")
        #expect(s.confirmRequestSubtitle == "5명 중 3명 \"이상 없음\" \u{00B7} 선택 단계")
    }

    @Test func 처리_필요가_남으면_마감_못_함() {
        #expect(!s.canClose)
        #expect(s.closeTitle == "10월 근무 마감 \u{00B7} 5건 남음")
    }

    @Test func 처리_필요_0건이면_마감_가능() {
        var n = s
        n.problemCount = 0
        #expect(n.canClose)
        #expect(n.closeTitle == "10월 근무 마감")
    }

    @Test func 유형별_건수와_읽기() {
        #expect(s.count(of: .needsCheck) == 3)
        #expect(s.count(of: .missingClockOut) == 1)
        #expect(s.count(of: .editRequest) == 1)
        #expect(WorkClosingCategory.missingClockOut.title == "퇴근 미기록")
        #expect(WorkClosingCategory.needsCheck.spokenTitle == "확인 필요, 연장, 지각, 예정 외")
        #expect(s.barAccessibilityText == "76건 중 정상 71건, 처리 필요 5건")
    }
}
