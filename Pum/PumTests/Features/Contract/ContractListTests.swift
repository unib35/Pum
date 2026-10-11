// UI-IOS-1ab — 계약서 보관함: 기간 · 시급 문구(en dash), 상태별 배지 · 테두리, 변경 단락, 펼침 토글, 이력 순서
import Testing
@testable import Pum

struct ContractListTests {
    let r = ContractListRecord.sample

    @Test func 기간_시급_문구_endash() {
        #expect(r.items[0].summaryText == "2026.10.05 \u{2013} 2027.04.04 · 시급 12,000원")
        #expect(r.items[1].summaryText == "2026.03.01 \u{2013} 2027.02.28 · 시급 11,500원")
        #expect(r.items[2].summaryText == "2026.09.01 \u{2013} 2027.02.28 · 시급 15,000원")
    }

    @Test func 상태별_배지와_테두리() {
        #expect(r.items.map(\.status.badgeText) == ["체결 완료", "변경 서명 대기", "체결 완료"])
        #expect(r.items.map(\.isAttention) == [false, true, false])
    }

    @Test func 변경_단락_조합() {
        let c = r.items[1].change!
        #expect(c.plainText == "11월 1일부터 시급 11,500원 → 12,000원 변경 계약서가 도착했어요.")
        #expect(c.accessibilityText == "11월 1일부터 시급 11,500원에서 12,000원으로 변경 계약서가 도착했어요")
        #expect(r.items[1].showsChange && !r.items[0].showsChange)
    }

    @Test func 펼침_토글() {
        var m = r
        #expect(m.items[0].showsDetail && !m.items[2].showsDetail)
        m.toggle(id: 1)
        #expect(!m.items[0].isExpanded && !m.items[0].showsDetail)
        m.toggle(id: 1)
        #expect(m.items[0].showsDetail)
        m.toggle(id: 3) // 이력 없음 — 펼칠 내용 없어 변하지 않음
        m.toggle(id: 2)
        #expect(!m.items[2].isExpanded && !m.items[1].isExpanded)
    }

    @Test func 이력_순서와_문구() {
        let h = r.items[0].history
        #expect(h.map(\.order) == [1, 2, 3])
        #expect(h.map(\.timeText) == ["10/01 14:20", "10/03 16:41", "10/03 16:41"])
        #expect(h[1].text == "근로자 서명 · 이종민 (휴대폰 본인인증)")
    }

    @Test func 카드_머리_낭독() {
        #expect(r.items[0].headerAccessibilityText == "종민김밥 본점, 체결 완료, 2026.10.05부터 2027.04.04까지, 시급 12,000원, 펼쳐짐")
        #expect(r.items[2].headerAccessibilityText == "C학원, 체결 완료, 2026.09.01부터 2027.02.28까지, 시급 15,000원")
    }
}
