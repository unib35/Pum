// UI-IOS-6g · REQ-092 — 사장님 알림 설정: 원문 값 · 섹션 순서 · 읽기 문구 · 마케팅 기본 꺼짐
import Testing
@testable import Pum

struct OwnerNotificationSettingsTests {
    let s = OwnerNotificationSettingsState.sample

    @Test func 섹션_순서와_행_수() {
        #expect(s.sections.map(\.title) == ["근무", "급여", "사업장", "서비스"])
        #expect(s.sections.map { $0.rows.count } == [4, 2, 2, 2])
    }

    @Test func 원문_글자() {
        #expect(s.workplaceName == "본점")
        let all = s.sections.flatMap(\.rows)
        #expect(all.map(\.title) == [
            "직원 출퇴근", "출퇴근 이상", "퇴근 미기록", "수정 · 휴무 · 대타 요청",
            "정산 시작 · 직원 확인 회신", "지급일 하루 전",
            "공지 확인 현황", "서류 만료", "서비스 공지", "마케팅",
        ])
        #expect(all.map(\.subtitle) == [
            "출근 · 퇴근할 때마다", "지각 · 조퇴 · 미출근 15분", "예정 퇴근 +30분", nil,
            nil, nil, "미확인 직원이 남았을 때", "보건증 만료 30일 전", "점검 · 정책 변경", "이벤트 · 혜택",
        ])
    }

    @Test func 읽기_문구() {
        #expect(s.sections[0].rows[1].accessibilityText == "출퇴근 이상, 지각 · 조퇴 · 미출근 15분")
        #expect(s.sections[0].rows[3].accessibilityText == "수정 · 휴무 · 대타 요청")
        #expect(s.workplaceAccessibilityLabel == "사업장 선택, 본점")
    }

    @Test func 마케팅만_기본_꺼짐() {
        let off = s.sections.flatMap(\.rows).filter { !$0.isOn }.map(\.id)
        #expect(off == ["marketing"])
    }
}
