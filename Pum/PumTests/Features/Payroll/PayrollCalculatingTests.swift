// UI-IOS-21l · REQ-070 · REQ-095
import Testing
@testable import Pum

struct PayrollCalculatingTests {
    @Test func 원문_값() {
        let s = PayrollCalculatingState.sample
        #expect(s.periodText == "9월분 \u{00B7} 근무 마감 10월 7일")
        #expect(s.progressText == "3 / 6명 \u{00B7} 화면을 나가도 계속 계산해요")
        #expect(s.rows.map(\.name) == ["김하늘", "박서준", "이종민", "최유나", "오세진", "정다은"])
        #expect(s.rows.map(\.amountText) == ["1,062,000원", "880,000원", "1,118,610원", nil, nil, nil])
        #expect(s.rows.map(\.detailText) == [nil, nil, nil, "계산 중", "기다리는 중", "기다리는 중"])
    }

    @Test func 읽기_문구() {
        let s = PayrollCalculatingState.sample
        #expect(s.rows[0].accessibilityText == "김하늘, 완료, 1,062,000원")
        #expect(s.rows[3].accessibilityText == "최유나, 계산 중")
        #expect(s.rows[4].accessibilityText == "오세진, 기다리는 중")
        #expect(s.progressAccessibilityText == "6명 중 3명 계산 끝")
    }

    @Test func 진행_비율_경계() {
        let half = PayrollCalculatingState(periodText: "", doneCount: 3, totalCount: 6, rows: [])
        let none = PayrollCalculatingState(periodText: "", doneCount: 0, totalCount: 6, rows: [])
        let all = PayrollCalculatingState(periodText: "", doneCount: 6, totalCount: 6, rows: [])
        let empty = PayrollCalculatingState(periodText: "", doneCount: 0, totalCount: 0, rows: [])
        #expect(half.progressFraction == 0.5)
        #expect(none.progressFraction == 0)
        #expect(all.progressFraction == 1)
        #expect(empty.progressFraction == 0)
    }

    @Test func 금액은_완료_행만() {
        let waiting = PayrollCalculatingRow(id: 9, name: "정다은", colorIndex: 0, status: .waiting, amountWon: 500_000)
        let done = PayrollCalculatingRow(id: 8, name: "정다은", colorIndex: 0, status: .done, amountWon: 500_000)
        #expect(waiting.amountText == nil)
        #expect(done.amountText == "500,000원")
    }
}
