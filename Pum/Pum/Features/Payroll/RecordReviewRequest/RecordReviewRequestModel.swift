// UI-IOS-1ad · REQ-044 — 급여 확정 전 근무기록 확인 요청 시트 데이터
// 기간 · 기한 후보 날짜 · 대상 인원 · 회신 현황은 서버가 준 값 그대로. 화면에서 계산하지 않는다.
import Foundation

/// 회신 기한 고르기(REQ-044: 월말 / 급여일 전 / 지정일)
nonisolated enum RecordReviewDeadlineChoice: Equatable, Sendable, CaseIterable {
    case endOfMonth, beforePayday, custom

    var title: String {
        switch self {
        case .endOfMonth: "월말"
        case .beforePayday: "급여일 3일 전"
        case .custom: "날짜 선택"
        }
    }
}

/// 직원 한 명의 회신 상태
nonisolated struct RecordReviewReplyPerson: Equatable, Sendable, Identifiable {
    enum Reply: Equatable, Sendable {
        case ok                       // 이상 없음
        case editRequested(Int)       // 수정 요청 N건
        case pending                  // 미회신
    }
    let name: String
    let reply: Reply
    var id: String { name }

    /// 칩 글자 — 원문 「이종민 ✓」 · 「김하늘 · 수정 요청 1」 · 「정우진 · 미회신」
    var chipText: String {
        switch reply {
        case .ok: "\(name) \u{2713}"
        case .editRequested(let n): "\(name) \u{00B7} 수정 요청 \(n)"
        case .pending: "\(name) \u{00B7} 미회신"
        }
    }
}

nonisolated struct RecordReviewRequestState: Equatable, Sendable {
    var periodLabel: String             // 서버가 준 확인 대상 기간, 예 「10월 1일 – 10월 31일」
    var monthTitle: String              // 뒤 화면 「2026년 10월」
    var replyDeadlineLabel: String      // 뒤 화면 「회신 기한」 값 — 예 「10월 31일」
    var endOfMonthDeadline: String      // 후보 1 — 예 「10월 31일 (금)」
    var beforePaydayDeadline: String    // 후보 2 — 예 「11월 7일 (금)」
    /// 후보 3(날짜 선택) — 사장님이 고른 뒤 서버가 준 값. 고르기 전에는 nil
    var customDeadline: String?
    var targetCount: Int                // 서버가 준 대상 직원 수
    var people: [RecordReviewReplyPerson]
    var repliedCount: Int               // 서버가 센 회신 수
    var totalCount: Int
    var autoSendSubtitle: String        // 서버가 준 자동 보내기 시각, 예 「매월 말일 오전 9시」

    // 화면 상태
    var choice: RecordReviewDeadlineChoice = .endOfMonth
    var autoSends = true
    var message = RecordReviewRequestState.defaultMessage
    /// 보내기 누른 뒤 처리 중(M26) — 기본 false
    var isSending = false

    /// 원문 기본 문구 — 1ae 직원 화면에 보이는 그 메시지(따옴표 없이). 사장님이 고칠 수 있다.
    static let defaultMessage = "11월 10일 급여 확정 전에 한 번 봐주세요. 다른 부분 있으면 수정 요청 남겨주시면 됩니다."

    static let sheetTitle = "근무기록 확인 요청"
    static let sheetSubtitle = "직원이 자기 10월 근무기록을 보고 \"이상 없음\" 또는 \"수정 요청\"으로 답해요. 급여 확정 전 분쟁을 줄여줘요."
    static let periodTitle = "확인 대상 기간"
    static let deadlineTitle = "회신 기한"
    static let targetTitle = "대상 직원"
    static let autoSendTitle = "매달 자동으로 보내기"
    static let statusTitle = "직원 확인 현황"

    var deadlineText: String {
        switch choice {
        case .endOfMonth: endOfMonthDeadline
        case .beforePayday: beforePaydayDeadline
        case .custom: customDeadline ?? ""
        }
    }
    var targetText: String { "전체 \(targetCount)명" }
    var replyDeadlineText: String { "회신 기한 \(replyDeadlineLabel)" }
    var progressText: String { "\(repliedCount) / \(totalCount)" }
    var progressFraction: Double { totalCount > 0 ? min(1, Double(repliedCount) / Double(totalCount)) : 0 }
    var sendTitle: String { "\(targetCount)명에게 요청 보내기" }
    var canSend: Bool { targetCount > 0 && !isSending }

    /// VoiceOver 한 문장 — 「직원 확인 현황, 5명 중 3명 회신, 김하늘 수정 요청 1건, 정우진 미회신」
    var statusAccessibilityLabel: String {
        var parts = [Self.statusTitle, "\(totalCount)명 중 \(repliedCount)명 회신"]
        for p in people {
            switch p.reply {
            case .ok: break
            case .editRequested(let n): parts.append("\(p.name) 수정 요청 \(n)건")
            case .pending: parts.append("\(p.name) 미회신")
            }
        }
        return parts.joined(separator: ", ")
    }

    /// 보내기 시작 — 이미 처리 중이거나 대상이 0명이면 false(두 번 보내지 않는다)
    mutating func beginSend() -> Bool {
        guard canSend else { return false }
        isSending = true
        return true
    }

    /// 원문 캡처(시트 열림 · 「월말」 선택 · 자동 보내기 켜짐) — 가짜 예시 값
    static let sample = RecordReviewRequestState(
        periodLabel: "10월 1일 \u{2013} 10월 31일",
        monthTitle: "2026년 10월",
        replyDeadlineLabel: "10월 31일",
        endOfMonthDeadline: "10월 31일 (금)",
        beforePaydayDeadline: "11월 7일 (금)",
        customDeadline: nil,
        targetCount: 5,
        people: [
            RecordReviewReplyPerson(name: "이종민", reply: .ok),
            RecordReviewReplyPerson(name: "최유나", reply: .ok),
            RecordReviewReplyPerson(name: "박서준", reply: .ok),
            RecordReviewReplyPerson(name: "김하늘", reply: .editRequested(1)),
            RecordReviewReplyPerson(name: "정우진", reply: .pending)
        ],
        repliedCount: 3,
        totalCount: 5,
        autoSendSubtitle: "매월 말일 오전 9시")
}
