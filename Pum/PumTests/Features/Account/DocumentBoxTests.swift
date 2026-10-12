// UI-IOS-6k · REQ-061 — 문서함: 원문 값 · 종류별 거르기 · 읽기 문구 · 확인 필요 섹션 숨김
import Testing
@testable import Pum

struct DocumentBoxTests {
    @Test func 원문_값() {
        let s = DocumentBoxState.sample
        #expect(s.attention.map(\.title) == ["변경 근로계약서"])
        #expect(s.attention.first?.detail == "B카페 서면점 · 11/1부터 시급 12,000원")
        #expect(s.attention.first?.statusText == "서명 요청")
        #expect(s.years.map(\.year) == ["2026"])
        #expect(s.years[0].items.map(\.statusText) == ["체결 완료", "지급 완료", "지급 완료", "발급", "42일 남음", "제출 완료"])
        #expect(DocumentFilter.allCases.map(\.title) == ["전체", "계약서", "명세서", "확인서", "제출 서류"])
    }

    @Test func 상태별_배지_종류() {
        #expect(DocumentStatus.signRequest.badgeKind == .attention)
        #expect(DocumentStatus.expiring.badgeKind == .attention)
        #expect(DocumentStatus.signed.badgeKind == .done)
        #expect(DocumentStatus.paid.badgeKind == .done)
        #expect(DocumentStatus.submitted.badgeKind == .waiting)
        #expect(DocumentStatus.issuable.badgeKind == nil)
    }

    @Test func 종류별_거르기() {
        let s = DocumentBoxState.sample
        #expect(s.years(under: .all)[0].items.count == 6)
        #expect(s.years(under: .payslip)[0].items.map(\.id) == ["payslip-main", "payslip-c"])
        #expect(s.years(under: .contract)[0].items.map(\.id) == ["contract-2026"])
        #expect(s.years(under: .certificate)[0].items.map(\.id) == ["work-cert"])
        #expect(s.years(under: .submitted)[0].items.map(\.id) == ["health-cert", "bankbook"])
        #expect(s.attention(under: .contract).count == 1)
        #expect(s.attention(under: .payslip).isEmpty)
    }

    @Test func 빈_연도는_숨김() {
        let items = DocumentBoxState.sample.years[0].items
        let s = DocumentBoxState(attention: [], years: [
            DocumentYearGroup(year: "2025", items: [items[0]]),
            DocumentYearGroup(year: "2026", items: [items[1]]),
        ])
        #expect(s.years(under: .payslip).map(\.year) == ["2026"])
        #expect(s.attention(under: .all).isEmpty)
    }

    @Test func 읽기_문구() {
        let item = DocumentBoxState.sample.years[0].items[1]
        #expect(item.accessibilityText == "급여명세서 9월, 종민김밥 본점 · 1,152,000원, 지급 완료")
    }
}
