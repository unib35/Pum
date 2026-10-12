// UI-IOS-6d · REQ-090 — 내 동의 내역: 원문 값 · 읽기 문구 · 필수 행 토글 없음 · 변경 예정 없음
import Testing
@testable import Pum

struct ConsentsTests {
    let s = ConsentsState.sample

    @Test func 원문_값() {
        #expect(ConsentsState.headerTitle == "내 동의 내역")
        #expect(s.pendingChange?.effectiveText == "시행 2027.01.01")
        #expect(s.pendingChange?.summary == "서비스 이용약관 v1.2 → v1.3")
        #expect(s.consents.map(\.title) == ["서비스 이용약관", "개인정보 수집 · 이용", "전자문서 · 전자서명", "위치정보 이용", "마케팅 정보 수신"])
        #expect(s.consents.map(\.detail) == ["2026.10.03 동의 · v1.2", "2026.10.03 동의 · v1.4", "2026.10.03 동의 · v1.0",
                                              "2026.10.05 동의 · v1.1 · 위치 출근", "동의 안 함"])
        #expect(s.consents.map(\.isOn).suffix(2) == [true, false])
        #expect(ConsentsState.thirdPartyHeader == "제3자 제공 · 사업장별")
        #expect(s.thirdParties.map(\.title) == ["종민김밥 본점", "B카페 서면점", "C학원"])
        #expect(s.thirdParties.map(\.detail) == ["2026.10.03 · 근무기록 · 계좌 · 서류", "2026.03.01 · 근무기록 · 계좌", "2026.09.01 · 근무기록 · 계좌"])
        #expect(ConsentsState.footnote == "필수 동의 철회는 해당 사업장 퇴사 또는 회원 탈퇴로 진행돼요.")
    }

    @Test func 읽기_문구() {
        #expect(s.consents[0].spoken == "서비스 이용약관, 필수, 2026.10.03 동의 · v1.2")
        #expect(s.consents[3].spoken == "위치정보 이용, 선택, 2026.10.05 동의 · v1.1 · 위치 출근")
        #expect(s.thirdParties[0].spoken == "종민김밥 본점, 필수, 2026.10.03 · 근무기록 · 계좌 · 서류")
        #expect(s.pendingChange?.spoken == "변경 예정, 시행 2027.01.01, 서비스 이용약관 v1.2 → v1.3")
    }

    @Test func 필수_행엔_토글_없음() {
        #expect(s.consents.filter { !$0.hasToggle }.map(\.id) == ["terms", "privacy", "esign"])
        #expect(s.consents.filter(\.hasToggle).map(\.id) == ["location", "marketing"])
        #expect(s.thirdParties.allSatisfy { !$0.hasToggle })
    }

    @Test func 변경_예정이_nil이면_카드_없음() {
        let none = ConsentsState(pendingChange: nil, consents: s.consents, thirdParties: s.thirdParties)
        #expect(none.pendingChange == nil)
        #expect(none.consents.count == 5)
    }
}
