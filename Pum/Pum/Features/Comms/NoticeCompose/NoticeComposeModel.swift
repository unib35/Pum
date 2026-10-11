// UI-IOS-3c · REQ-040 — 사장님 공지 작성 데이터. 공지에는 수락 버튼이 없고, 응답이 필요한 건 연결된 「요청」(근무 모집)으로 따로 보낸다.
// 근무 모집 요약 · 재알림 일수 · 받는 사람 수는 서버 값 그대로(화면 계산 없음).
import Foundation

nonisolated enum NoticeCategory: String, CaseIterable, Sendable, Identifiable {
    case businessHours, dinner, rules, training, other
    var id: String { rawValue }
    var title: String {
        switch self {
        case .businessHours: "영업시간"
        case .dinner: "회식"
        case .rules: "운영 규칙"
        case .training: "교육"
        case .other: "기타"
        }
    }
}

nonisolated enum NoticeAudience: String, CaseIterable, Sendable, Identifiable {
    case all, hall, selected
    var id: String { rawValue }
}

/// 연결된 근무 모집. 요약 문구는 서버 포맷 그대로 「10월 5일 12:00 – 20:00 · 2명 · 휴일 1.5배」
nonisolated struct NoticeComposeRecruitment: Equatable, Sendable {
    var summaryText: String
}

nonisolated struct NoticeComposeState: Equatable, Sendable {
    var category: NoticeCategory?
    var title: String
    var body: String
    var audience: NoticeAudience
    /// 「전체 N명」의 N (서버 값)
    var totalStaffCount: Int
    var requestsReadReceipt: Bool
    /// 미확인 직원에게 다시 알리는 날짜(서버 값)
    var reminderDays: Int
    /// nil이면 근무 모집이 연결되지 않은 것
    var recruitment: NoticeComposeRecruitment?
    var isSending = false

    static let screenTitle = "공지 작성"
    static let recipientLabel = "받는 사람"
    static let hallTitle = "홀"
    static let selectTitle = "선택"
    static let readReceiptTitle = "읽음 확인 받기"
    static let recruitmentTitle = "근무 모집 연결"
    static let photoTitle = "사진"
    static let fileTitle = "파일"
    static let sendWithRecruitmentTitle = "공지 + 근무 모집 보내기"
    /// TODO(디자인 없음): 근무 모집이 연결되지 않았을 때의 버튼 문구는 원문에 없다 — 임시 「공지 보내기」. 디자인 확정 시 교체.
    static let sendOnlyTitle = "공지 보내기"

    var allTitle: String { "전체 \(totalStaffCount)명" }
    var reminderText: String { "미확인 직원에게 \(reminderDays)일 후 다시 알림" }
    var sendTitle: String { recruitment == nil ? Self.sendOnlyTitle : Self.sendWithRecruitmentTitle }

    var hasContent: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    /// 비활성 이유 문구는 디자인 없음(README 충돌 #30과 같은 처리 — 회색 비활성만)
    var canSend: Bool { hasContent && !isSending }

    /// 보내기 시작 — 이미 처리 중이거나 내용이 없으면 false(두 번 보내지 않는다, 1ad와 같은 방식)
    mutating func beginSend() -> Bool {
        guard canSend else { return false }
        isSending = true
        return true
    }

    /// 보내기 실패 — 처리 중을 풀어 다시 보낼 수 있게(실패 안내 문구는 디자인 없음, 연결 때)
    mutating func failSend() { isSending = false }

    /// 원문 값(3c)
    static let sample = NoticeComposeState(
        category: .businessHours,
        title: "추석 연휴 영업 안내",
        body: """
        추석 연휴 영업시간 안내드립니다.

        10월 5일(월) 12:00 – 20:00 단축 영업
        10월 6일(화) 휴무
        10월 7일(수) 정상 영업

        5일은 예약이 많아 추가 인력이 필요합니다.
        """,
        audience: .all, totalStaffCount: 5,
        requestsReadReceipt: true, reminderDays: 2,
        recruitment: .init(summaryText: "10월 5일 12:00 – 20:00 · 2명 · 휴일 1.5배"))

    /// 실제 진입용 빈 상태 — 제목 · 본문 비어 있음, 근무 모집 없음. 카테고리 기본값은 디자인 없음(미선택).
    static func empty(totalStaffCount: Int) -> NoticeComposeState {
        .init(category: nil, title: "", body: "", audience: .all, totalStaffCount: totalStaffCount,
              requestsReadReceipt: false, reminderDays: 2, recruitment: nil)
    }
}
