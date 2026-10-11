// UI-IOS-3a · REQ-041 · REQ-040 — 직원 「소식」 상태. 서버가 준 값을 그대로 담는다(화면에서 계산 · 판단 없음).
// 날짜 · 시각 · 배율 · 예상 금액 문구는 서버 값. 금액은 정수(원).
import Foundation

/// 필터 세그먼트 4칸. 누르면 해당 섹션만 보인다.
enum NewsFilter: CaseIterable, Hashable {
    case all, notice, request, alert

    var title: String {
        switch self {
        case .all: "전체"
        case .notice: "공지"
        case .request: "요청"
        case .alert: "알림"
        }
    }
}

/// 결정이 필요한 요청. 종류마다 동작이 다르다(추가 근무 = 수락/거절, 계약 서명 = 열기).
enum NewsRequest: Identifiable, Hashable {
    case extraShift(ExtraShiftRequest)
    case contractSign(ContractSignRequest)

    var id: String {
        switch self {
        case .extraShift(let r): r.id
        case .contractSign(let r): r.id
        }
    }
}

struct ExtraShiftRequest: Identifiable, Hashable {
    let id: String
    /// 「1시간 전」
    let ago: String
    /// 「10월 5일 월 · 12:00 – 20:00 · 추석 영업」
    let summary: String
    /// 「휴일 1.5배」 — 서버가 정한 배율 문구
    let multiplierLabel: String
    /// 예상 급여(원, 서버 계산값)
    let expectedPay: Int
    /// 같이 요청받은 직원 이름(없으면 nil)
    let alsoRequested: String?

    /// 「휴일 1.5배 · 예상 126,000원 · 김하늘님에게도 요청됨」
    var detail: String {
        var parts = [multiplierLabel, "예상 \(PumFormat.amount(expectedPay))원"]
        if let alsoRequested { parts.append("\(alsoRequested)님에게도 요청됨") }
        return parts.joined(separator: " · ")
    }
}

struct ContractSignRequest: Identifiable, Hashable {
    let id: String
    let ago: String
    /// 「B카페 서면점 · 시급 변경 계약서」
    let title: String
    /// 적용 시작일 문구(서버) 「11월 1일」
    let effectiveDate: String
    let oldHourlyWage: Int
    let newHourlyWage: Int

    /// 「11월 1일부터 11,500 → 12,000원」
    var detail: String {
        "\(effectiveDate)부터 \(PumFormat.amount(oldHourlyWage)) → \(PumFormat.amount(newHourlyWage))원"
    }
}

struct NewsNotice: Identifiable, Hashable {
    let id: String
    let title: String
    /// 본문(두 줄까지 표시). 읽은 공지는 본문 없이 제목 + 메타만(원문)
    let body: String?
    let author: String
    let date: String
    let isRead: Bool
    /// 「근무 모집 연결됨」 같은 연결 표시(서버)
    let linkLabel: String?
}

struct NewsAlert: Identifiable, Hashable {
    let id: String
    let message: String
    /// 「오늘 09:40」 · 「9월 10일」 — 서버 문구
    let time: String
    /// 원문: 오래된(이미 본) 알림은 회색 글자
    let isMuted: Bool
}

struct NewsFeedState: Hashable {
    var workplaceName: String
    var workplaceInitial: String
    var requests: [NewsRequest]
    var notices: [NewsNotice]
    var alerts: [NewsAlert]
    /// 탭 바 「소식」 배지(처리할 일 개수, 서버 값)
    var tabBadge: Int

    var unreadNoticeCount: Int { notices.filter { !$0.isRead }.count }
    var requestCount: Int { requests.count }
    var isEmpty: Bool { requests.isEmpty && notices.isEmpty && alerts.isEmpty }

    /// 실제 진입용 빈 값 — 디자인에 빈 상태가 없어 섹션을 모두 숨기기만 한다.
    static func empty(workplaceName: String, workplaceInitial: String) -> NewsFeedState {
        .init(workplaceName: workplaceName, workplaceInitial: workplaceInitial,
              requests: [], notices: [], alerts: [], tabBadge: 0)
    }

    /// 원문 3a 값
    static let sample = NewsFeedState(
        workplaceName: "종민김밥 본점", workplaceInitial: "종",
        requests: [
            .extraShift(.init(id: "r1", ago: "1시간 전", summary: "10월 5일 월 · 12:00 – 20:00 · 추석 영업",
                              multiplierLabel: "휴일 1.5배", expectedPay: 126_000, alsoRequested: "김하늘")),
            .contractSign(.init(id: "r2", ago: "어제", title: "B카페 서면점 · 시급 변경 계약서",
                                effectiveDate: "11월 1일", oldHourlyWage: 11_500, newHourlyWage: 12_000)),
        ],
        notices: [
            .init(id: "n1", title: "추석 연휴 영업 안내",
                  body: "10월 5일은 12:00 – 20:00 단축 영업합니다. 예약이 많아 추가 인력도 모집해요.",
                  author: "박민수 사장님", date: "10월 3일", isRead: false, linkLabel: "근무 모집 연결됨"),
            .init(id: "n2", title: "10월 위생교육 안내", body: nil,
                  author: "박민수 사장님", date: "9월 28일", isRead: true, linkLabel: nil),
        ],
        alerts: [
            .init(id: "a1", message: "9/30 수정 요청이 승인됐어요 · 퇴근 22:30", time: "오늘 09:40", isMuted: false),
            .init(id: "a2", message: "9월 급여가 지급됐어요 · 1,152,000원", time: "9월 10일", isMuted: true),
        ],
        tabBadge: 3)
}

extension NewsFeedState {
    /// 필터에 따라 이 섹션을 보여 줄지
    func shows(_ section: NewsFilter, under filter: NewsFilter) -> Bool {
        filter == .all || filter == section
    }
}
