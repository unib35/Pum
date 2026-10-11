// UI-IOS-3b · REQ-040 — 직원 공지 상세 데이터. 공지는 읽으면 끝, 근무 모집은 별도 요청 카드.
// 금액 · 인정 시간 · 배율 · 확인 수는 서버 값 그대로(화면 계산 없음). 금액은 정수 원.
import Foundation

nonisolated struct NoticeBodyLine: Equatable, Sendable, Identifiable {
    /// 앞부분 강조(700) — 예 「10월 5일(월)」. 없으면 nil
    var strong: String? = nil
    var text: String
    var id: String { (strong ?? "") + text }
    /// 읽을 때는 강조 구분 없이 이어서
    var plain: String { (strong ?? "") + text }
}

nonisolated struct NoticeBodyParagraph: Equatable, Sendable, Identifiable {
    var lines: [NoticeBodyLine]
    var id: String { lines.map(\.id).joined() }
}

nonisolated struct NoticeRecruitment: Equatable, Sendable {
    var recruitCount: Int          // 모집 인원
    var applicantCount: Int        // 신청 인원
    var dateTimeText: String       // 「10월 5일 월 · 12:00 – 20:00」(서버 포맷)
    var breakText: String          // 「1시간」
    var recognizedText: String     // 「7시간」(인정 시간, 서버 값)
    var holidayRateText: String    // 「1.5배」(서버 값)
    var expectedPay: Int           // 예상 급여(원, 서버 값)

    var countText: String { "\(recruitCount)명 모집 · \(applicantCount)명 신청" }
    var detailText: String {
        "휴게 \(breakText) · 인정 \(recognizedText) · 휴일 \(holidayRateText) · 예상 \(PumFormat.amount(expectedPay))원"
    }
}

nonisolated struct NoticeDetailState: Equatable, Sendable {
    var audienceLabel: String      // 「전체 직원」
    var title: String
    var authorName: String
    var postedAtText: String       // 「2026.10.03 14:20」
    var paragraphs: [NoticeBodyParagraph]
    var totalStaff: Int
    var readCount: Int
    var myReadText: String         // 「읽음 · 오늘 15:02」
    /// 연결된 근무 모집. nil이면 요청 섹션(머리 · 카드 · 안내)을 숨긴다.
    var recruitment: NoticeRecruitment?

    var readStatusText: String { "직원 \(totalStaff)명 중 \(readCount)명 확인" }
    var bodyAccessibilityText: String {
        paragraphs.map { $0.lines.map(\.plain).joined(separator: "\n") }.joined(separator: "\n")
    }

    static let sample = NoticeDetailState(
        audienceLabel: "전체 직원",
        title: "추석 연휴 영업 안내",
        authorName: "박민수 사장님", postedAtText: "2026.10.03 14:20",
        paragraphs: [
            .init(lines: [.init(text: "추석 연휴 영업시간 안내드립니다.")]),
            .init(lines: [
                .init(strong: "10월 5일(월)", text: " 12:00 – 20:00 단축 영업"),
                .init(strong: "10월 6일(화)", text: " 휴무"),
                .init(strong: "10월 7일(수)", text: " 정상 영업"),
            ]),
            .init(lines: [.init(text: "5일은 예약이 많아 추가 인력이 필요합니다. 가능하신 분은 아래 근무 모집에서 신청해 주세요. 모두 확인 부탁드립니다.")]),
        ],
        totalStaff: 5, readCount: 3, myReadText: "읽음 · 오늘 15:02",
        recruitment: NoticeRecruitment(
            recruitCount: 2, applicantCount: 1,
            dateTimeText: "10월 5일 월 · 12:00 – 20:00",
            breakText: "1시간", recognizedText: "7시간", holidayRateText: "1.5배", expectedPay: 126_000))
}
