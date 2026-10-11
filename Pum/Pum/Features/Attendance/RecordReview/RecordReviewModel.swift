// UI-IOS-1ae · REQ-044 · DEC-005 — 근무기록 확인 요청 받음(직원 화면) 데이터
// 근무일 · 인정 근무 · 예상 급여 · 행별 인정 시간 · 금액 · 건수는 서버 값 그대로 — 화면에서 합산 · 계산하지 않는다.
// 「더 보기」 건수만 받은 전체 건수 − 보이는 행 수로 센다(표시용).
import Foundation

/// 기록 한 줄(근무 하루)
nonisolated struct ReviewRow: Identifiable, Equatable, Sendable {
    enum Kind: Equatable, Sendable {
        /// 살펴볼 기록 — 문구는 서버가 준 그대로(예: 대타로 내 기록에서 제외됨)
        case attention(title: String, detail: String)
        /// 확정 — 출퇴근 시각 · 인정 분 · 금액(서버 값)
        case confirmed(start: String, end: String, recognizedMinutes: Int, pay: Int)
    }

    let id: Int
    let month: Int
    let day: Int
    /// 「월」「화」… 한 글자
    let weekday: String
    var kind: Kind

    static let attentionActionText = "확인"
    static let confirmedText = "확정"

    var isAttention: Bool { if case .attention = kind { true } else { false } }
    var dateText: String { "\(month)월 \(day)일 \(weekday)요일" }

    /// 둘째 줄 큰 문구
    var titleText: String {
        switch kind {
        case .attention(let title, _): title
        case .confirmed(let s, let e, _, _): PumFormat.timeRange(s, e)
        }
    }

    /// 아래 보조 줄
    var detailText: String {
        switch kind {
        case .attention(_, let detail): detail
        case .confirmed(_, _, let minutes, let pay):
            "인정 \(PumFormat.duration(minutes: minutes)) \u{00B7} \(PumFormat.amount(pay))원"
        }
    }

    /// 오른쪽 글자(배지 바탕 없음)
    var trailingText: String { isAttention ? Self.attentionActionText : Self.confirmedText }

    /// VoiceOver 한 문장: 「10월 12일 월요일, 대타, 박서준이 근무, 내 기록에서 제외됨, 0원, 확인 필요」
    var accessibilityText: String {
        switch kind {
        case .attention(let title, let detail):
            let spoken = (title + ", " + detail).replacingOccurrences(of: " \u{00B7} ", with: ", ")
            return "\(dateText), \(spoken), 확인 필요"
        case .confirmed(let s, let e, _, _):
            let detail = detailText.replacingOccurrences(of: " \u{00B7} ", with: ", ")
            return "\(dateText), \(s)부터 \(e)까지, \(detail), \(Self.confirmedText)"
        }
    }
}

nonisolated struct RecordReviewState: Equatable, Sendable {
    var workplaceName: String
    var ownerName: String
    var month: Int
    /// 회신 기한(서버 문구, 예: 「10월 31일까지」)
    var deadlineText: String
    var ownerMessage: String
    // 요약(서버 값)
    var workDays: Int
    var recognizedMinutes: Int
    var expectedPay: Int
    var totalCount: Int
    var normalCount: Int
    var attentionCount: Int
    /// 먼저 보이는 행(전체 중 일부)
    var rows: [ReviewRow]

    static let daysLabel = "근무일"
    static let recognizedLabel = "인정 근무"
    static let payLabel = "예상 급여"
    static let deadlineSuffix = " 회신"

    /// 원문: 두 줄로 끊어 쓴다
    var titleLines: [String] { ["\(month)월 근무기록을", "확인해 주세요"] }
    var titleText: String { titleLines.joined(separator: " ") }

    var subtitlePrefix: String { "\(workplaceName) \u{00B7} \(ownerName) 사장님 요청 \u{00B7} " }
    var subtitleText: String { subtitlePrefix + deadlineText + Self.deadlineSuffix }

    var messageAccessibilityText: String { "사장님 메시지, \(ownerMessage)" }

    var daysText: String { "\(workDays)일" }
    var recognizedText: String { PumFormat.duration(minutes: recognizedMinutes) }
    var payText: String { PumFormat.amount(expectedPay) }

    var countLead: String { "기록 \(totalCount)건 중 " }
    var normalText: String { "\(normalCount)건 정상" }
    /// 살펴볼 것이 0건이면 오른쪽 문구 없음(디자인에 이 상태 없음 — 보고)
    var attentionText: String? { attentionCount > 0 ? "\(attentionCount)건 살펴보세요" : nil }

    var summaryAccessibilityText: String {
        var parts = ["\(Self.daysLabel) \(daysText)", "\(Self.recognizedLabel) \(recognizedText)",
                     "\(Self.payLabel) \(payText)원", countLead + normalText]
        if let a = attentionText { parts.append(a) }
        return parts.joined(separator: ", ")
    }

    /// 더 보기 건수 = 받은 전체 건수 − 보이는 행 수 (0 이하면 숨김)
    var moreCount: Int { max(totalCount - rows.count, 0) }
    var moreText: String? { moreCount > 0 ? "\(moreCount)건 더 보기" : nil }

    static let sample = RecordReviewState(
        workplaceName: "종민김밥 본점", ownerName: "박민수", month: 10, deadlineText: "10월 31일까지",
        ownerMessage: "\u{201C}11월 10일 급여 확정 전에 한 번 봐주세요. 다른 부분 있으면 수정 요청 남겨주시면 됩니다.\u{201D}",
        workDays: 17, recognizedMinutes: 82 * 60 + 30, expectedPay: 1_188_000,
        totalCount: 17, normalCount: 16, attentionCount: 1,
        rows: [
            ReviewRow(id: 12, month: 10, day: 12, weekday: "월",
                      kind: .attention(title: "대타 \u{00B7} 박서준이 근무", detail: "내 기록에서 제외됨 \u{00B7} 0원")),
            ReviewRow(id: 30, month: 10, day: 30, weekday: "금",
                      kind: .confirmed(start: "16:57", end: "22:04", recognizedMinutes: 4 * 60 + 37, pay: 55_400)),
            ReviewRow(id: 28, month: 10, day: 28, weekday: "수",
                      kind: .confirmed(start: "17:00", end: "22:00", recognizedMinutes: 4 * 60 + 30, pay: 54_000)),
        ]
    )
}
