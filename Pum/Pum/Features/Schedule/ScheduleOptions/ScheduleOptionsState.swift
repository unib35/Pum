// UI-IOS-9b · REQ-051 — 추천 3안 데이터
// 금액 · 차이 · 건수 · 설명 · 부족 표시 · 충족 체크는 서버(엔진) 값 그대로. 화면에서 빼기 · 비교 · 정렬을 하지 않는다.
// 차이의 부호 · 색은 서버가 준 방향(direction)으로만 정한다.
import Foundation

/// 서버가 준 현재 대비 방향
nonisolated enum ScheduleOptionDirection: Equatable, Sendable {
    case decrease, increase, same
}

nonisolated struct ScheduleOptionCheck: Equatable, Sendable {
    var title: String
    var met: Bool
}

nonisolated struct ScheduleOption: Equatable, Sendable, Identifiable {
    var id: String
    var name: String            // 「인건비 절감」
    var totalAmount: Int        // 서버가 준 예상 총비용(원, 수당 · 사업주 부담 포함)
    var deltaAmount: Int        // 서버가 준 현재 대비 차이 크기(원) — 부호는 direction
    var direction: ScheduleOptionDirection
    var changeCount: Int        // 서버가 준 변경 건수
    var note: String            // 서버가 준 설명, 예 「근무자 5명」 · 「기존 일정 변경 최소화」
    var staffingMet: Bool       // 필요 인력 충족
    var availabilityMet: Bool   // 가능 시간 충족
    var conditionsMet: Bool     // 근로조건 충족
    var detailTitle: String     // 이 안을 골랐을 때 하단 버튼 문구(서버 값)

    var totalText: String { PumFormat.amount(totalAmount) }
    /// 원문: 「원」 없이 · 줄면 「−」(원문 글자) · 늘면 「+」
    var deltaText: String {
        let n = PumFormat.amount(abs(deltaAmount))
        switch direction {
        case .decrease: return "\u{2212}" + n
        case .increase: return "+" + n
        case .same: return n
        }
    }
    var changeText: String { "변경 \(changeCount)건 \u{00B7} \(note)" }

    /// 충족 체크 항목 — 충족만 초록 체크, 아니면 체크 없이 글자만
    var checks: [ScheduleOptionCheck] {
        [ScheduleOptionCheck(title: "필요 인력", met: staffingMet),
         ScheduleOptionCheck(title: "가능 시간", met: availabilityMet),
         ScheduleOptionCheck(title: "근로조건", met: conditionsMet)]
    }

    var accessibilityText: String {
        let amount = PumFormat.amount(abs(deltaAmount))
        let delta: String
        switch direction {
        case .decrease: delta = "현재보다 \(amount)원 적음"
        case .increase: delta = "현재보다 \(amount)원 많음"
        case .same: delta = "현재와 같음"
        }
        let met = checks.filter(\.met).map(\.title)
        let unmet = checks.filter { !$0.met }.map(\.title)
        var parts = [name, "\(totalText)원", delta, changeText.replacingOccurrences(of: " \u{00B7} ", with: ", ")]
        if !met.isEmpty { parts.append(met.joined(separator: " \u{00B7} ") + " 충족") }
        if !unmet.isEmpty { parts.append(unmet.joined(separator: " \u{00B7} ") + " 미충족") }
        return parts.joined(separator: ", ")
    }
}

nonisolated struct ScheduleOptionsState: Equatable, Sendable {
    var weekLabel: String        // 「10/12 – 18 주간」
    var currentAmount: Int       // 서버가 준 현재 스케줄 주간 총비용(원)
    var shortageText: String?    // 서버가 준 부족 표시, 예 「토 18–22 1명 부족」(없으면 알약 없음)
    var options: [ScheduleOption]
    var selectedID: String       // 처음 선택된 안

    var title: String { "추천 스케줄" }
    var currentTitle: String { "현재 스케줄 \u{00B7} \(weekLabel)" }
    var currentText: String { PumFormat.amount(currentAmount) }
    var notice: String { "금액은 실제 적용되는 수당과 사업주 부담을 모두 포함한 예상 총비용이에요." }

    func option(id: String) -> ScheduleOption? { options.first { $0.id == id } }

    var currentAccessibilityText: String {
        "현재 스케줄 \(weekLabel), \(currentText)원" + (shortageText.map { ", \($0)" } ?? "")
    }

    /// 원문 캡처 — 가짜 예시 값(2 · 3안의 버튼 문구는 원문에 없어 같은 꼴로 둔 임시 값)
    static let sample = ScheduleOptionsState(
        weekLabel: "10/12 \u{2013} 18 주간",
        currentAmount: 1_284_000,
        shortageText: "토 18\u{2013}22 1명 부족",
        options: [
            ScheduleOption(id: "saving", name: "인건비 절감", totalAmount: 1_241_000, deltaAmount: 43_000, direction: .decrease,
                           changeCount: 4, note: "근무자 5명", staffingMet: true, availabilityMet: true, conditionsMet: true,
                           detailTitle: "절감안 변경 내용 보기"),
            ScheduleOption(id: "balanced", name: "균형", totalAmount: 1_278_000, deltaAmount: 6_000, direction: .decrease,
                           changeCount: 2, note: "기존 일정 변경 최소화", staffingMet: true, availabilityMet: true, conditionsMet: true,
                           detailTitle: "균형안 변경 내용 보기"),
            ScheduleOption(id: "keep", name: "기존 일정 유지", totalAmount: 1_324_000, deltaAmount: 40_000, direction: .increase,
                           changeCount: 1, note: "부족한 시간대만 추가", staffingMet: true, availabilityMet: true, conditionsMet: true,
                           detailTitle: "유지안 변경 내용 보기"),
        ],
        selectedID: "saving")
}
