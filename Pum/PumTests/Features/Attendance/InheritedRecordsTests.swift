// UI-IOS-20l · REQ-007 · DEC-001 — 지난 근무기록: 원문 값 · 빈 목록 · 읽기 문구
import Testing
@testable import Pum

struct InheritedRecordsTests {
    @Test func 원문_값() {
        let s = InheritedRecordsState.sample
        #expect(InheritedRecordsState.backTitle == "근무기록")
        #expect(s.workplaceName == "종민김밥 본점")
        #expect(s.title == "지난 근무기록")
        #expect(s.subtitle == "앱 연결 전 · 사장님이 입력한 기록이에요.")
        #expect(s.months.map(\.title) == ["9월", "8월", "7월"])
        #expect(s.months.map(\.detail) == ["12일 · 55시간 10분 · 명세서 받음", "13일 · 58시간 30분 · 명세서 받음", "14일 · 63시간 · 명세서 받음"])
        #expect(InheritedRecordsState.ownerInputText == "사업주 입력")
        #expect(s.appRecordsTitle == "10월 12일 월 부터")
        #expect(InheritedRecordsState.appRecordsDetail == "앱으로 출퇴근한 기록")
        #expect(InheritedRecordsState.appRecordsBadge == "✓ 사업장 확인")
        #expect(InheritedRecordsState.disputeTitle == "기록이 실제와 다르면")
        #expect(InheritedRecordsState.disputeDetail == "날짜를 골라 실제 시간과 사유를 보내요 · 사장님이 확인해요")
        #expect(InheritedRecordsState.disputeButton == "이의 제기")
    }

    @Test func 빈_목록은_월_카드를_그리지_않는다() {
        let s = InheritedRecordsState.sample
        let empty = InheritedRecordsState(workplaceName: s.workplaceName, title: s.title, subtitle: s.subtitle,
                                          months: [], appRecordsTitle: s.appRecordsTitle)
        #expect(s.showsMonthCard)
        #expect(!empty.showsMonthCard)
    }

    @Test func 읽기_문구() {
        let s = InheritedRecordsState.sample
        #expect(s.months[0].readout == "9월, 12일 · 55시간 10분 · 명세서 받음, 사업주 입력")
        #expect(s.appRecordsReadout == "10월 12일 월 부터, 앱으로 출퇴근한 기록, 사업장 확인")
        #expect(s.disputeReadout == "기록이 실제와 다르면, 날짜를 골라 실제 시간과 사유를 보내요 · 사장님이 확인해요, 이의 제기")
    }
}
