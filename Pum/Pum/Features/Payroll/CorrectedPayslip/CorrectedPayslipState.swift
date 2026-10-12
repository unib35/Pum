// UI-IOS-10h · REQ-075 — 직원 · 정정 명세서: 무엇이 왜 바뀌었는지 먼저
// 금액 · 차액 · 지급 안내 · 바뀐 기록 · 영향 · 사유 · 정정 횟수는 모두 서버 값. 화면은 더하거나 빼지 않는다.
import Foundation

/// 「바뀐 기록」 한 건 — 서버가 준 목록을 그대로 그린다
nonisolated struct CorrectedRecord: Equatable, Sendable, Identifiable {
    var id: String
    /// 예: 「8월 28일 금」 (마지막 글자가 요일)
    var dayText: String
    /// 예: 「퇴근」
    var kindText: String
    /// 「HH:mm」 정정 전 · 후
    var beforeTime: String
    var afterTime: String
    /// 예: 「사업주 정정」
    var sourceText: String
    /// 예: 「연장 · 야간 1시간」 (서버 값)
    var impactText: String

    var titleText: String { "\(dayText) \u{00B7} \(kindText)" }

    var accessibilityText: String {
        "\(Self.spokenDay(dayText))\(kindText), \(Self.spokenTime(beforeTime))에서 \(Self.spokenTime(afterTime))로, \(sourceText), \(impactText)"
    }

    /// 「8월 28일 금」 → 「8월 28일 금요일 」
    static func spokenDay(_ s: String) -> String {
        let week: Set<Character> = ["월", "화", "수", "목", "금", "토", "일"]
        guard let last = s.last, week.contains(last), s.dropLast().last == " " else { return s + " " }
        return s + "요일 "
    }

    /// 「22:00」 → 「오후 10시」, 「09:30」 → 「오전 9시 30분」
    static func spokenTime(_ s: String) -> String {
        let p = s.split(separator: ":")
        guard p.count == 2, let h = Int(p[0]), let m = Int(p[1]) else { return s }
        let period = h < 12 ? "오전" : "오후"
        let h12 = h % 12 == 0 ? 12 : h % 12
        return m == 0 ? "\(period) \(h12)시" : "\(period) \(h12)시 \(m)분"
    }
}

nonisolated struct CorrectedPayslipState: Equatable, Sendable {
    // 서버 값
    var monthText: String
    var workplaceName: String
    var employeeName: String
    var correctedDateText: String
    var correctionCountText: String
    var beforeWon: Int
    var afterWon: Int
    /// 부호 포함 문구(서버 값). 예: 「+22,800」
    var deltaText: String
    var payoutNote: String
    var records: [CorrectedRecord]
    var reasonLabel: String
    var reasonNote: String
    var reasonText: String

    // 원문 문구
    static let title = "급여명세서"
    static let badgeText = "정정본"
    static let netLabel = "실지급액"
    static let deltaLabel = "차액"
    static let recordsSection = "바뀐 기록"
    static let originalTitle = "원래 명세서 보기"

    var headerCaption: String { "급여명세서 \u{00B7} \(monthText)" }
    var beforeText: String { PumFormat.amount(beforeWon) }
    var afterText: String { PumFormat.amount(afterWon) }

    var netAccessibility: String { "\(Self.netLabel), \(beforeText)원에서 \(afterText)원" }
    var deltaAccessibility: String { "\(Self.deltaLabel), \(deltaText)원" }
    var reasonAccessibility: String { "\(reasonLabel), \(reasonNote), \(reasonText)" }

    static let sample = CorrectedPayslipState(
        monthText: "2026년 8월분", workplaceName: "종민김밥 본점", employeeName: "김하늘",
        correctedDateText: "2026.10.02", correctionCountText: "1회",
        beforeWon: 1_062_000, afterWon: 1_084_800, deltaText: "+22,800",
        payoutNote: "차액은 9월 급여(10월 10일)에 함께 지급돼요",
        records: [CorrectedRecord(id: "r1", dayText: "8월 28일 금", kindText: "퇴근",
                                  beforeTime: "22:00", afterTime: "23:00",
                                  sourceText: "사업주 정정", impactText: "연장 \u{00B7} 야간 1시간")],
        reasonLabel: "정정 사유", reasonNote: "내 수정 요청(10월 1일) 반영", reasonText: "마감 청소 1시간 추가 근무")
}
