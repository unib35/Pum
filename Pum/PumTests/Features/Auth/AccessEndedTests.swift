// UI-IOS-6s — 만료 · 접근 종료 공통 틀: 원문 값 · 읽기 문구 · 카드 없음 상태
import Testing
@testable import Pum

struct AccessEndedTests {
    let s = AccessEndedState.inviteExpired

    @Test func 원문_값() {
        #expect(s.title == "초대가 만료됐어요")
        #expect(s.message == "초대 링크는 보낸 날로부터 7일 동안만 쓸 수 있어요. 사장님께 새 초대를 요청해주세요.")
        #expect(s.primaryTitle == "사장님께 새 초대 요청")
        #expect(s.secondaryTitle == "다른 코드 입력")
        #expect(s.card?.initial == "종")
        #expect(s.card?.name == "종민김밥 본점")
        #expect(s.card?.badgeText == "만료")
        #expect(s.card?.rows.map(\.value) == ["2026.10.01", "2026.10.08"])
    }

    @Test func 읽기_문구() {
        #expect(s.card?.spokenText == "종민김밥 본점, 박민수 사장님, 만료")
        #expect(s.card?.rows.first?.spokenText == "보낸 날, 2026.10.01")
        #expect(s.card?.rows.last?.spokenText == "만료, 2026.10.08")
    }

    @Test func 카드_없는_상태와_타일_글자() {
        let none = AccessEndedState(title: "제목", message: "안내", card: nil, primaryTitle: "가", secondaryTitle: "나")
        #expect(none.card == nil)
        let c = AccessEndedState.Card(tileText: "A", name: "이름", subtitle: "부제", badgeText: "배지", rows: [])
        #expect(c.initial == "A")
        #expect(c.rows.isEmpty)
    }
}
