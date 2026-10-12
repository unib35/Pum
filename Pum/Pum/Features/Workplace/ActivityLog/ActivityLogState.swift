// UI-IOS-6l · REQ-091 — 활동 기록: 근무 · 계약 · 급여 변경 이력(수정 · 삭제 불가).
// 기록 · 날짜 묶음 · 시각 · 금액 · 필터 이름은 서버가 준 글자 그대로. 화면은 목록을 거르거나 계산하지 않는다(거르기는 서버 몫).
import Foundation

/// 기록 유형 — 급여(초록) · 근무(회색) · 계약(파랑)
nonisolated enum ActivityKind: Equatable, Hashable, Sendable {
    case payroll, work, contract

    /// 배지 글자
    var label: String {
        switch self {
        case .payroll: "급여"
        case .work: "근무"
        case .contract: "계약"
        }
    }
}

nonisolated struct ActivityEntry: Equatable, Identifiable, Sendable {
    var id: String
    /// 예: 「13:21」
    var timeText: String
    /// 예: 「10월 급여 확정 · 4명 4,210,000원」 — 여러 줄 가능
    var title: String
    /// 예: 「박민수 · 대표」
    var actorText: String
    var kind: ActivityKind

    /// 「13:21」 → 「13시 21분」, 「09:00」 → 「9시」. 읽을 수 없는 글자는 그대로 둔다.
    var spokenTime: String {
        let parts = timeText.split(separator: ":")
        guard parts.count == 2, let h = Int(parts[0]), let m = Int(parts[1]) else { return timeText }
        return m == 0 ? "\(h)시" : "\(h)시 \(m)분"
    }

    /// 예: 「13시 21분, 10월 급여 확정 · 4명 4,210,000원, 박민수 · 대표, 급여」
    var accessibilityText: String {
        "\(spokenTime), \(title), \(actorText), \(kind.label)"
    }
}

nonisolated struct ActivityDay: Equatable, Identifiable, Sendable {
    var id: String
    /// 예: 「10월 10일 금」
    var title: String
    var entries: [ActivityEntry]
}

/// 드롭다운 칩 — 현재 고른 값을 서버가 글자로 준다
nonisolated struct ActivityDropdown: Equatable, Identifiable, Sendable {
    var id: String
    var title: String
}

/// 빠른 필터 칩 — 켜짐은 서버 값
nonisolated struct ActivityQuickFilter: Equatable, Identifiable, Sendable {
    var id: String
    var title: String
    var isOn: Bool
}

nonisolated struct ActivityLogState: Equatable, Sendable {
    var searchPlaceholder: String
    /// 전체 직원 · 기간 · 유형
    var dropdowns: [ActivityDropdown]
    var quickFilters: [ActivityQuickFilter]
    /// 최신 날짜 먼저 — 서버 순서 그대로
    var days: [ActivityDay]
    var footerNote: String
}

extension ActivityLogState {
    /// 정상: 2026년 10월 전체 직원, 필터 칩 미선택(원문 5건)
    static let sample = ActivityLogState(
        searchPlaceholder: "직원 이름 · 내용 검색",
        dropdowns: [
            .init(id: "staff", title: "전체 직원"),
            .init(id: "period", title: "2026년 10월"),
            .init(id: "type", title: "유형"),
        ],
        quickFilters: [
            .init(id: "needsCheck", title: "확인 필요만", isOn: false),
            .init(id: "overtime", title: "연장근무만", isOn: false),
            .init(id: "editRequest", title: "수정 요청만", isOn: false),
        ],
        days: [
            .init(id: "10-10", title: "10월 10일 금", entries: [
                .init(id: "a1", timeText: "13:21", title: "10월 급여 확정 · 4명 4,210,000원", actorText: "박민수 · 대표", kind: .payroll),
            ]),
            .init(id: "10-04", title: "10월 4일 일", entries: [
                .init(id: "a2", timeText: "10:02", title: "이종민 수정 요청 승인 · 퇴근 22:00 → 22:30", actorText: "박민수 · 대표", kind: .work),
                .init(id: "a3", timeText: "09:13", title: "근무 수정 요청 · 9/30 퇴근 22:30", actorText: "이종민", kind: .work),
            ]),
            .init(id: "10-03", title: "10월 3일 토", entries: [
                .init(id: "a4", timeText: "22:31", title: "퇴근 기록 · 정책에 따라 자동 확정", actorText: "이종민 · 매장 QR", kind: .work),
                .init(id: "a5", timeText: "16:41", title: "근로계약서 서명", actorText: "이종민 · 휴대폰 본인인증", kind: .contract),
            ]),
        ],
        footerNote: "근무 · 계약 · 급여 변경은 수정하거나 지울 수 없는 기록으로 남아요."
    )
}
