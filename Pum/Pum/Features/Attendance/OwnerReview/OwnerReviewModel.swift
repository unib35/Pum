// UI-IOS-1r · REQ-026 · REQ-027 — 확인 필요 근무: 유형별 빠른 처리(사장님 근무 탭)
// 금액 · 시간 · 건수 · 설명 문구는 서버 값 그대로 — 화면에서 계산하지 않는다.
import Foundation

enum OwnerReviewFilter: CaseIterable, Sendable {
    case needsReview, processed, all
}

nonisolated enum OwnerReviewAction: Equatable, Sendable {
    case edit, approve, confirm, manualInput, recordPlannedEnd, reject
}

/// 카드 유형. 배지 색 · 버튼 구성은 유형마다 정해져 있다(디자인 1r).
enum OwnerReviewKind: Sendable {
    case overtime          // 연장
    case missingClockOut   // 퇴근 기록 없음
    case late              // 지각
    case unscheduled       // 예정 없는 근무

    var badgeKind: PumBadge.Kind {
        switch self {
        case .overtime, .late: .attention      // 주황 = 확인 필요
        case .missingClockOut: .problem        // 빨강 = 기록 없음
        case .unscheduled: .waiting            // 중립 회색
        }
    }

    /// 왼쪽(보조) 버튼
    var secondary: (title: String, kind: PumButton.Kind, action: OwnerReviewAction) {
        switch self {
        case .overtime, .late: ("수정", .outline, .edit)
        case .missingClockOut: ("직접 입력", .outline, .manualInput) // 직접 입력은 「사업주 입력」으로 남는다(REQ-027)
        case .unscheduled: ("거절", .dangerOutline, .reject)
        }
    }

    /// 오른쪽(주) 버튼 제목. 퇴근 기록 없음은 예정 퇴근 시각이 들어간다.
    func primaryTitle(plannedEnd: String?) -> String {
        switch self {
        case .overtime, .unscheduled: "인정"
        case .late: "확인"
        case .missingClockOut: "\(plannedEnd ?? "") 기록"
        }
    }

    var primaryKind: PumButton.Kind { self == .missingClockOut ? .dark : .primary }

    var primaryAction: OwnerReviewAction {
        switch self {
        case .overtime, .unscheduled: .approve
        case .late: .confirm
        case .missingClockOut: .recordPlannedEnd
        }
    }
}

struct OwnerReviewAmount: Equatable, Sendable {
    enum Sign: Sendable { case plus, minus, none }
    let won: Int
    let sign: Sign

    /// 「+12,400원」 · 「−3,000원」(U+2212) · 「48,000원」
    var text: String {
        switch sign {
        case .plus: "+" + PumFormat.amount(abs(won)) + "원"
        case .minus: PumFormat.deduction(won) + "원"
        case .none: PumFormat.amount(won) + "원"
        }
    }

    var spoken: String {
        switch sign {
        case .plus: "\(PumFormat.amount(abs(won)))원 추가"
        case .minus: "\(PumFormat.amount(abs(won)))원 공제"
        case .none: "\(PumFormat.amount(won))원"
        }
    }
}

struct OwnerReviewItem: Identifiable, Equatable, Sendable {
    let id: Int
    let name: String
    let colorIndex: Int
    let kind: OwnerReviewKind
    /// 「10/2 금」
    let dateText: String
    /// 소리: 「10월 2일 금요일」
    let dateSpoken: String
    let badgeText: String
    /// 회색 상자(연장 · 퇴근 기록 없음). 없으면 nil
    let plannedStart: String?
    let plannedEnd: String?
    let actualStart: String?
    /// 퇴근 기록 없음이면 nil(「—」로 표시)
    let actualEnd: String?
    /// 아래 줄 설명(서버 문구) — 금액 앞까지
    let explanation: String
    let amount: OwnerReviewAmount?

    var hasTimeBox: Bool { plannedStart != nil && plannedEnd != nil && actualStart != nil }
    var plannedRange: String? {
        guard let s = plannedStart, let e = plannedEnd else { return nil }
        return PumFormat.timeRange(s, e)
    }
    /// 「16:58 – 」(en dash). 끝 시각은 강조색으로 따로 그린다
    var actualLead: String? { actualStart.map { "\($0) \u{2013} " } }
    /// 주요 버튼 VoiceOver: 「박서준, 퇴근 15:00으로 기록」처럼 무엇을 하는지까지
    var primaryAccessibilityTitle: String {
        if case .missingClockOut = kind, let end = plannedEnd { return "\(name), 퇴근 \(end)으로 기록" }
        return "\(name) \(primaryTitle)"
    }
    var actualEndText: String { actualEnd ?? "\u{2014}" }
    /// 금액이 이어 붙으면 구분점을 넣는다
    var explanationText: String { amount == nil ? explanation : explanation + " \u{00B7} " }

    var primaryTitle: String { kind.primaryTitle(plannedEnd: plannedEnd) }
    var avatarInitial: String { PumAvatar.initial(for: name) }

    /// VoiceOver: 카드 한 문장(버튼은 따로)
    var accessibilitySummary: String {
        var parts = [name, dateSpoken, badgeText]
        if let ps = plannedStart, let pe = plannedEnd { parts.append("예정 \(ps)부터 \(pe)") }
        if let a = actualStart {
            parts.append(actualEnd.map { "실제 \(a)부터 \($0)" } ?? "실제 \(a)부터 퇴근 기록 없음")
        }
        parts.append(explanation)
        if let amount { parts.append(amount.spoken) }
        return parts.joined(separator: ", ")
    }
}

struct OwnerReviewState: Equatable, Sendable {
    var filter: OwnerReviewFilter = .needsReview
    var items: [OwnerReviewItem]
    /// 「확인 필요」 숫자 배지(서버 값)
    var needsReviewCount: Int
    /// 「처리됨 12」(서버 값)
    var processedCount: Int
    /// 「정상 근무 12건은 정책에 따라 자동 확정됐어요」(서버 값)
    var autoConfirmedCount: Int
    /// 탭 바 근무 배지 — 원문 탭 바에는 배지가 없다
    var workTabBadge = 0

    var autoConfirmedText: String { "정상 근무 \(autoConfirmedCount)건은 정책에 따라 자동 확정됐어요" }
    var processedTitle: String { "처리됨 \(processedCount)" }

    static let sample = OwnerReviewState(
        items: [
            .init(id: 1, name: "김하늘", colorIndex: 1, kind: .overtime, dateText: "10/2 금", dateSpoken: "10월 2일 금요일",
                  badgeText: "연장근무", plannedStart: "17:00", plannedEnd: "22:00", actualStart: "16:58", actualEnd: "23:02",
                  explanation: "예정보다 1시간 2분 늦게 퇴근", amount: .init(won: 12_400, sign: .plus)),
            .init(id: 2, name: "박서준", colorIndex: 3, kind: .missingClockOut, dateText: "10/2 금", dateSpoken: "10월 2일 금요일",
                  badgeText: "퇴근 기록 없음", plannedStart: "09:00", plannedEnd: "15:00", actualStart: "09:03", actualEnd: nil,
                  explanation: "예정 퇴근 15:00으로 처리할까요?", amount: nil),
            .init(id: 3, name: "최유나", colorIndex: 2, kind: .late, dateText: "10/1 목", dateSpoken: "10월 1일 목요일",
                  badgeText: "지각 15분", plannedStart: nil, plannedEnd: nil, actualStart: nil, actualEnd: nil,
                  explanation: "예정 09:00 \u{2192} 실제 09:15 출근", amount: .init(won: 3_000, sign: .minus)),
            .init(id: 4, name: "정우진", colorIndex: 4, kind: .unscheduled, dateText: "10/1 목", dateSpoken: "10월 1일 목요일",
                  badgeText: "예정 없는 근무", plannedStart: nil, plannedEnd: nil, actualStart: nil, actualEnd: nil,
                  explanation: "13:00 \u{2013} 17:00 \u{00B7} 4시간", amount: .init(won: 48_000, sign: .none)),
        ],
        needsReviewCount: 4, processedCount: 12, autoConfirmedCount: 12)
}
