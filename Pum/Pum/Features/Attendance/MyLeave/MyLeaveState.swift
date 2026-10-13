// UI-IOS-19g · REQ-073 — 직원 · 내 연차(단시간은 시간 단위). 모든 시간 · 날짜 · 문구는 서버 값.
// 연차 계산 · 시간 환산은 엔진 몫 — 화면은 받은 문자열만 보여준다.
import Foundation

/// 줄 하나 — 이름(왼쪽)과 값(오른쪽), 필요하면 이름 아래 작은 풀이
nonisolated struct MyLeaveRow: Identifiable, Equatable, Sendable {
    let title: String
    let detail: String?
    let value: String
    var id: String { title + value }

    init(title: String, detail: String? = nil, value: String) {
        self.title = title
        self.detail = detail
        self.value = value
    }

    /// VoiceOver — 「이름, 풀이, 값」
    var spoken: String {
        [title, detail, value].compactMap { $0 }.joined(separator: ", ")
    }
}

nonisolated struct MyLeaveState: Equatable, Sendable {
    static let backTitle = "근무"
    static let title = "내 연차"
    static let remainingTitle = "남은 연차"
    static let accrualHeader = "생기는 연차"
    static let usedHeader = "쓴 연차"
    static let requestTitle = "연차로 쉬기"
    static let footerNotice = "승인 전까지는 예정대로 근무예요"

    /// 「종민김밥 본점 · 주 18시간 · 시간 단위」
    let subtitle: String
    /// 「하루 3.6시간 기준」
    let perDayText: String
    /// 「14.4시간」
    let remainingText: String
    /// 「쓴 7.2시간」
    let usedText: String
    /// 「생긴 21.6시간 · 6개월 개근」
    let earnedText: String
    /// 막대에서 쓴 몫(0–1000, 서버 값). 화면은 나누지 않는다.
    let usedPermille: Int
    /// 막대에 쓰는 몫 — 서버 값이 0–1000 밖이면 끝에 붙인다
    var barUsedPermille: Int { Self.clampedPermille(usedPermille) }
    static func clampedPermille(_ value: Int) -> Int { min(max(value, 0), 1000) }
    let accrualRows: [MyLeaveRow]
    let usedRows: [MyLeaveRow]

    /// 남은 연차 카드 읽기 — 「남은 연차, 14.4시간, 하루 3.6시간 기준, 쓴 7.2시간, 생긴 21.6시간 · 6개월 개근」
    var summarySpoken: String {
        [Self.remainingTitle, remainingText, perDayText, usedText, earnedText].joined(separator: ", ")
    }

    static let sample = MyLeaveState(
        subtitle: "종민김밥 본점 · 주 18시간 · 시간 단위",
        perDayText: "하루 3.6시간 기준",
        remainingText: "14.4시간",
        usedText: "쓴 7.2시간",
        earnedText: "생긴 21.6시간 · 6개월 개근",
        usedPermille: 333,
        accrualRows: [
            MyLeaveRow(title: "다음에 생기는 날", value: "10월 9일 · 3.6시간"),
            MyLeaveRow(title: "1년 미만 연차 사용 기한", value: "2027.3.8"),
            MyLeaveRow(title: "1년이 되는 날", detail: "15일 × 3.6시간", value: "2027.3.9 · 54시간"),
        ],
        usedRows: [
            MyLeaveRow(title: "9월 15일 화", value: "3.6시간"),
            MyLeaveRow(title: "7월 21일 화", value: "3.6시간"),
        ]
    )
}
