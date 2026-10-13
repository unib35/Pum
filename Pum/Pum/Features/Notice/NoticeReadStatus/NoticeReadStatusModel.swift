// UI-IOS-3d · REQ-040 — 사장님 공지 확인 현황 데이터.
// 수 · 시각 · 횟수 · 다음 근무일 · 근무 모집 현황은 서버 값 그대로(화면 계산 없음). 막대 비율만 확인 수 / 전체로 그린다.
import Foundation

/// 미확인 직원 한 명
nonisolated struct NoticeUnreadPerson: Equatable, Sendable, Identifiable {
    var id: String
    var name: String
    var colorIndex: Int            // 사람별 아바타 색(같은 사람은 항상 같은 색) — 사람 ID 기준으로 서버가 정한 값
    var remindCount: Int           // 알림 보낸 횟수(서버 값)
    var nextShiftText: String      // 「10/5」(서버 포맷)
    /// 서버가 번호 공개를 허용한 사람만 전화 버튼을 보인다
    var canCall: Bool

    var detailText: String { "알림 \(remindCount)회 보냄 · 다음 근무 \(nextShiftText)" }
}

/// 확인한 직원 한 명
nonisolated struct NoticeReadPerson: Equatable, Sendable, Identifiable {
    var id: String
    var name: String
    var colorIndex: Int
    var readAtText: String         // 「10/3 14:31」(서버 포맷)
}

/// 연결된 근무 모집(서버 값)
nonisolated struct NoticeLinkedRecruitment: Equatable, Sendable {
    var dateTimeText: String       // 「10/5 12–20」
    var recruitCount: Int          // 모집 인원
    var confirmedCount: Int        // 확정
    var waitingCount: Int          // 대기

    /// 「10/5 12–20 · 2명 중 」 + 강조 「1명 확정」 + 「 · 1명 대기」
    var prefixText: String { "\(dateTimeText) · \(recruitCount)명 중 " }
    var confirmedText: String { "\(confirmedCount)명 확정" }
    var suffixText: String { " · \(waitingCount)명 대기" }
    var accessibilityText: String { "연결된 근무 모집, \(dateTimeText), \(recruitCount)명 중 \(confirmedCount)명 확정, \(waitingCount)명 대기" }
}

nonisolated struct NoticeReadStatusState: Equatable, Sendable {
    var title: String
    var postedAtText: String       // 「10월 3일 14:20」
    var totalCount: Int            // 전체 대상(서버 값)
    var readCount: Int             // 확인 수(서버 값)
    var unread: [NoticeUnreadPerson]
    var read: [NoticeReadPerson]
    /// nil이면 연결된 근무 모집 카드를 숨긴다
    var recruitment: NoticeLinkedRecruitment?

    var metaText: String { "\(postedAtText) · 전체 \(totalCount)명" }
    /// 진행 막대 비율(그리기 전용). 전체 0이면 0.
    var progress: Double { totalCount > 0 ? min(1, max(0, Double(readCount) / Double(totalCount))) : 0 }
    var progressAccessibilityText: String { "\(totalCount)명 중 \(readCount)명 확인" }
    var unreadHeaderText: String { "미확인 \(unread.count)명" }
    var readHeaderText: String { "확인 \(read.count)명" }
    /// 미확인이 없으면 버튼을 숨긴다(디자인에 없는 문구를 만들지 않는다). 버튼 문구의 N = 미확인 목록 길이.
    var remindTitle: String? { unread.isEmpty ? nil : "미확인 \(unread.count)명에게 다시 알림" }

    static let sample = NoticeReadStatusState(
        title: "추석 연휴 영업 안내",
        postedAtText: "10월 3일 14:20",
        totalCount: 5, readCount: 3,
        unread: [
            .init(id: "u1", name: "이종민", colorIndex: 0, remindCount: 1, nextShiftText: "10/5", canCall: true),
            .init(id: "u2", name: "박서준", colorIndex: 3, remindCount: 1, nextShiftText: "10/4", canCall: true),
        ],
        read: [
            .init(id: "r1", name: "김하늘", colorIndex: 1, readAtText: "10/3 14:31"),
            .init(id: "r2", name: "최유나", colorIndex: 2, readAtText: "10/3 15:02"),
            .init(id: "r3", name: "정우진", colorIndex: 4, readAtText: "10/3 18:44"),
        ],
        recruitment: NoticeLinkedRecruitment(dateTimeText: "10/5 12–20", recruitCount: 2, confirmedCount: 1, waitingCount: 1))
}
