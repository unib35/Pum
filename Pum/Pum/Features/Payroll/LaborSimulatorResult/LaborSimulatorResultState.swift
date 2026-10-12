// UI-IOS-8e · REQ-052 — 시뮬레이션 결과 데이터
// 금액 · 비율 · 인원 · 변화는 서버(엔진)가 준 값 그대로. 화면에서 빼기 · % 계산을 하지 않는다.
// 실제 데이터는 바뀌지 않는다(What-if 전용).
import Foundation

nonisolated struct LaborSimulatorWeekday: Equatable, Sendable, Identifiable {
    var id: String { name }
    var name: String       // 「월」
    var spokenName: String // 「월요일」
    var headcount: Int     // 서버가 준 추가 후 인원
    var change: Int        // 서버가 준 늘고 준 인원(0이면 변화 없음)

    var headcountText: String { "\(headcount)명" }
    var isChanged: Bool { change != 0 }
    /// 「+1」 · 「−1」 · 변화 없음은 「–」(en dash, 원문)
    var changeText: String {
        change > 0 ? "+\(change)" : change < 0 ? "\u{2212}\(-change)" : "\u{2013}"
    }
    var accessibilityText: String {
        let tail = change > 0 ? ", \(change)명 늘어남" : change < 0 ? ", \(-change)명 줄어듦" : ", 변화 없음"
        return "\(spokenName) \(headcountText)\(tail)"
    }
}

nonisolated struct LaborSimulatorResultState: Equatable, Sendable {
    var month: Int
    var currentAmount: Int        // 서버가 준 현재 인건비(원)
    var afterAmount: Int          // 서버가 준 추가 후 인건비(원)
    var deltaAmount: Int          // 서버가 준 차이(원, 부호 포함)
    var deltaPercentText: String  // 서버가 준 비율 문자열, 예 「+12.0%」
    var weekdays: [LaborSimulatorWeekday]
    var weekdaySummary: String    // 서버가 준 설명, 예 「월·수·금 저녁」

    var title: String { "시뮬레이션 결과" }
    var compareTitle: String { "\(month)월 인건비" }
    var currentText: String { PumFormat.amount(currentAmount) }
    var afterText: String { PumFormat.amount(afterAmount) }
    /// 「+504,000원」 — 늘 때 부호만 붙인다(줄 때는 amount가 −를 붙인다)
    var deltaAmountText: String { (deltaAmount > 0 ? "+" : "") + PumFormat.amount(deltaAmount) + "원" }
    var deltaPercentSuffix: String { " \u{00B7} \(deltaPercentText)" }
    var weekdayHeader: String { "요일별 인원 \u{00B7} \(weekdaySummary)" }

    var recommendTitle: String { "다음 주 스케줄 전체를 추천받기" }
    var recommendSubtitle: String { "필요 인력을 넣으면 합법적인 조합 중 총비용이 낮은 안을 비교해요" }
    var recommendTag: String { "9a" } // 원문 글자 그대로(화면 ID 표기)
    var addTitle: String { "새 근무 시간대로 스케줄에 추가" }
    var saveOnlyTitle: String { "저장만 하기" }
    var saveOnlyNotice: String { " \u{00B7} 실제 데이터는 바뀌지 않아요" }

    var compareAccessibilityText: String {
        let direction = deltaAmount < 0 ? "감소" : "증가"
        let pct = deltaPercentText.replacingOccurrences(of: "+", with: "")
            .replacingOccurrences(of: "\u{2212}", with: "").replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: "%", with: "퍼센트")
        return "\(compareTitle), 현재 \(currentText)원, 추가 후 \(afterText)원, \(PumFormat.amount(abs(deltaAmount)))원 \(direction), \(pct)"
    }

    /// 원문 캡처 — 가짜 예시 값
    static let sample = LaborSimulatorResultState(
        month: 10, currentAmount: 4_210_000, afterAmount: 4_714_000,
        deltaAmount: 504_000, deltaPercentText: "+12.0%",
        weekdays: [
            .init(name: "월", spokenName: "월요일", headcount: 3, change: 1),
            .init(name: "화", spokenName: "화요일", headcount: 2, change: 0),
            .init(name: "수", spokenName: "수요일", headcount: 3, change: 1),
            .init(name: "목", spokenName: "목요일", headcount: 1, change: 0),
            .init(name: "금", spokenName: "금요일", headcount: 3, change: 1),
            .init(name: "토", spokenName: "토요일", headcount: 2, change: 0),
            .init(name: "일", spokenName: "일요일", headcount: 0, change: 0),
        ],
        weekdaySummary: "월\u{00B7}수\u{00B7}금 저녁")
}
