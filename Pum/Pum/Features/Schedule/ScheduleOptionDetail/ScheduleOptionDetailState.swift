// UI-IOS-9c · REQ-051 — 절감안 상세 데이터
// 금액 · 차이 · 이유 · 설명 · 전후 시간 · 증감 글자 · 체크 항목 · 버튼 문구(「4명」 포함)는 서버(엔진) 값 그대로. 화면에서 계산하지 않는다.
// 차이의 부호 · 색은 서버가 준 방향(direction)으로만 정한다. 반영은 직원 수락 경로 — 이 화면은 요청만 보낸다.
import Foundation

/// 줄어든 이유 한 줄
nonisolated struct ScheduleSavingReason: Equatable, Sendable, Identifiable {
    var id: String
    var title: String           // 「불필요한 연장근무 3시간 감소」(서버 문구)
    var detail: String          // 「이종민 금 · 김하늘 토」
    var amount: Int             // 서버가 준 크기(원) — 부호는 direction
    var direction: ScheduleOptionDirection

    /// 원문: 「원」 없이 · 줄면 「−」(원문 글자) · 늘면 「+」
    var amountText: String {
        let n = PumFormat.amount(abs(amount))
        switch direction {
        case .decrease: return "\u{2212}" + n
        case .increase: return "+" + n
        case .same: return n
        }
    }
    var accessibilityText: String {
        let n = PumFormat.amount(abs(amount))
        let delta: String
        switch direction {
        case .decrease: delta = "\(n)원 적음"
        case .increase: delta = "\(n)원 많음"
        case .same: delta = "변화 없음"
        }
        return "\(title), \(detail), \(delta)"
    }
}

/// 직원 한 명의 변경 전 → 후
nonisolated struct ScheduleStaffChange: Equatable, Sendable, Identifiable {
    var id: String
    var name: String
    var colorIndex: Int         // 아바타 색(사람 고정 키 — 표시 전용)
    var beforeText: String?     // 「금 17–23」, 이전 없음은 nil(「—」로 그림)
    var afterText: String       // 「금 17–22」
    var changeText: String      // 서버가 준 증감 글자 「−1h」 · 「이동」 · 「+4h」
    var spokenText: String      // 서버가 준 읽기 문구 — 시간 표기를 화면에서 바꿔 읽지 않는다

    var beforeDisplay: String { beforeText ?? "\u{2014}" }
}

nonisolated struct ScheduleOptionDetailState: Equatable, Sendable {
    var currentAmount: Int          // 서버가 준 현재 주간 예상 인건비(원)
    var newAmount: Int              // 서버가 준 절감안 예상 인건비(원)
    var deltaAmount: Int            // 서버가 준 차이 크기(원) — 부호는 direction
    var direction: ScheduleOptionDirection
    var checks: [ScheduleOptionCheck]   // 필요 인력 충족 · 가능 시간 안 · 소정근로 변경 없음 · 휴게 기준(충족만 초록 체크)
    var reasons: [ScheduleSavingReason]
    var changesTitle: String        // 서버가 준 섹션 제목 「변경 4건 · 직원이 수락하면 반영」
    var changes: [ScheduleStaffChange]
    var sendTitle: String           // 서버가 준 버튼 문구 「4명에게 변경 요청 보내기」

    var title: String { "인건비 절감안" }
    var summaryTitle: String { "주간 예상 인건비" }
    var reasonsTitle: String { "줄어든 이유" }
    var currentText: String { PumFormat.amount(currentAmount) }
    var newText: String { PumFormat.amount(newAmount) + "원" }
    /// 원문: 「−43,000원」
    var deltaText: String {
        let n = PumFormat.amount(abs(deltaAmount)) + "원"
        switch direction {
        case .decrease: return "\u{2212}" + n
        case .increase: return "+" + n
        case .same: return n
        }
    }

    var summaryAccessibilityText: String {
        let n = PumFormat.amount(abs(deltaAmount))
        let delta: String
        switch direction {
        case .decrease: delta = "\(n)원 적음"
        case .increase: delta = "\(n)원 많음"
        case .same: delta = "변화 없음"
        }
        let met = checks.filter(\.met).map(\.title)
        let unmet = checks.filter { !$0.met }.map(\.title)
        var parts = ["\(summaryTitle), \(currentText)원에서 \(newText), \(delta)"]
        if !met.isEmpty { parts.append(met.joined(separator: ", ") + " 충족") }
        if !unmet.isEmpty { parts.append(unmet.joined(separator: ", ") + " 미충족") }
        return parts.joined(separator: ", ")
    }

    /// 원문 캡처 — 가짜 예시 값. 읽기 문구는 원문 기준 값(서버가 준다고 가정)
    static let sample = ScheduleOptionDetailState(
        currentAmount: 1_284_000, newAmount: 1_241_000, deltaAmount: 43_000, direction: .decrease,
        checks: [ScheduleOptionCheck(title: "필요 인력 충족", met: true),
                 ScheduleOptionCheck(title: "가능 시간 안", met: true),
                 ScheduleOptionCheck(title: "소정근로 변경 없음", met: true),
                 ScheduleOptionCheck(title: "휴게 기준", met: true)],
        reasons: [
            ScheduleSavingReason(id: "overtime", title: "불필요한 연장근무 3시간 감소", detail: "이종민 금 \u{00B7} 김하늘 토",
                                 amount: 27_000, direction: .decrease),
            ScheduleSavingReason(id: "move", title: "근무 가능 시간 안에서 재배치", detail: "박서준 토요일 오후로 이동",
                                 amount: 10_000, direction: .decrease),
            ScheduleSavingReason(id: "peak", title: "피크 시간대에만 추가 인력", detail: "토 18\u{2013}22 정우진 4시간",
                                 amount: 6_000, direction: .decrease),
        ],
        changesTitle: "변경 4건 \u{00B7} 직원이 수락하면 반영",
        changes: [
            ScheduleStaffChange(id: "jm", name: "이종민", colorIndex: 0, beforeText: "금 17\u{2013}23", afterText: "금 17\u{2013}22",
                                changeText: "\u{2212}1h", spokenText: "이종민, 금 17시–23시에서 금 17시–22시로, 1시간 줄어듦"),
            ScheduleStaffChange(id: "hn", name: "김하늘", colorIndex: 1, beforeText: "토 17\u{2013}23", afterText: "토 18\u{2013}22",
                                changeText: "\u{2212}2h", spokenText: "김하늘, 토 17시–23시에서 토 18시–22시로, 2시간 줄어듦"),
            ScheduleStaffChange(id: "sj", name: "박서준", colorIndex: 3, beforeText: "토 09\u{2013}15", afterText: "토 11\u{2013}17",
                                changeText: "이동", spokenText: "박서준, 토 9시–15시에서 토 11시–17시로, 시간 이동"),
            ScheduleStaffChange(id: "wj", name: "정우진", colorIndex: 4, beforeText: nil, afterText: "토 18\u{2013}22",
                                changeText: "+4h", spokenText: "정우진, 이전 근무 없음에서 토 18시–22시로, 4시간 늘어남"),
        ],
        sendTitle: "4명에게 변경 요청 보내기")
}
