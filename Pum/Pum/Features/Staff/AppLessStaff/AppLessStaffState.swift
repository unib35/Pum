// UI-IOS-20e · REQ-007 · DEC-001 — 앱 없는 직원 상세. 근로조건대로 미리 채운 근무기록을 사장님이 다른 날만 고친다.
// 시간 · 가산 문구는 서버(엔진) 값 — 화면에서 계산하지 않는다. 모든 기록은 「사업주 입력」으로 남는다.
import Foundation

/// 근무 행의 상태 — 배지 모양을 정한다
nonisolated enum AppLessDayStatus: Equatable, Sendable {
    /// 근로조건대로(「예정대로」 배지)
    case asPlanned
    /// 사장님이 고침(「고침」 외곽선 배지)
    case edited
    /// 아직 오지 않은 날(배지 없음, 글자 연하게)
    case upcoming

    var badgeText: String? {
        switch self {
        case .asPlanned: "예정대로"
        case .edited: "고침"
        case .upcoming: nil
        }
    }
}

/// 근무 한 행 — 서버 값
nonisolated struct AppLessWorkDay: Identifiable, Equatable, Sendable {
    /// 날짜 id(예: "2026-10-07") — onEditDay로 넘긴다
    let id: String
    /// 「10월 7일 수」
    let dateText: String
    /// 「16:00 – 22:00」
    let timeText: String
    /// 「5시간 30분」 — 오지 않은 날은 nil
    let durationText: String?
    /// 「+1시간」 — 예정과 다를 때만
    let extraText: String?
    /// 읽기용 「1시간 더」
    let extraReadout: String?
    /// 「한글날 · 예정」 — 오지 않은 날
    let noteText: String?
    let status: AppLessDayStatus

    /// 「5시간 30분 · +1시간」 · 「한글날 · 예정」
    var detailText: String { [durationText, extraText, noteText].compactMap { $0 }.joined(separator: " · ") }

    /// 「10월 7일 수, 16:00 – 22:00, 5시간 30분, 1시간 더, 고침」
    var readout: String {
        [dateText, timeText, durationText, extraReadout, noteText, status.badgeText]
            .compactMap { $0 }.joined(separator: ", ")
    }
}

nonisolated struct AppLessStaffState: Equatable, Sendable {
    static let backTitle = "직원"
    static let badgeText = "앱 없음"
    static let ownerInputText = "사업주 입력"
    static let fixOtherTitle = "다른 날 고치기"
    static let fixOtherDetail = "늦게 · 일찍 · 결근 · 추가 근무"
    static let contractTitle = "계약서"
    static let inviteTitle = "앱으로 초대"
    static let inviteDetail = "직원이 직접 출퇴근하고 지난 기록도 이어져요"

    let name: String
    /// 「월 · 수 · 금 17–22 · 10,320원」 — 서버 값
    let summaryText: String
    /// 「10월 근무」
    let sectionTitle: String
    let days: [AppLessWorkDay]
    /// 「종이 계약서 · 사진 2장」
    let contractText: String

    func day(_ id: String) -> AppLessWorkDay? { days.first { $0.id == id } }

    var headerReadout: String { "\(name), \(Self.badgeText), \(summaryText)" }
    var sectionReadout: String { "\(sectionTitle), \(Self.ownerInputText)" }
    var fixOtherReadout: String { "\(Self.fixOtherTitle), \(Self.fixOtherDetail)" }
    var contractReadout: String { "\(Self.contractTitle), \(contractText)" }
    var inviteReadout: String { "\(Self.inviteTitle), \(Self.inviteDetail)" }

    static let sample = AppLessStaffState(
        name: "김민지",
        summaryText: "월 · 수 · 금 17–22 · 10,320원",
        sectionTitle: "10월 근무",
        days: [
            AppLessWorkDay(id: "2026-10-02", dateText: "10월 2일 금", timeText: PumFormat.timeRange("17:00", "22:00"),
                           durationText: "4시간 30분", extraText: nil, extraReadout: nil, noteText: nil, status: .asPlanned),
            AppLessWorkDay(id: "2026-10-05", dateText: "10월 5일 월", timeText: PumFormat.timeRange("17:00", "22:00"),
                           durationText: "4시간 30분", extraText: nil, extraReadout: nil, noteText: nil, status: .asPlanned),
            AppLessWorkDay(id: "2026-10-07", dateText: "10월 7일 수", timeText: PumFormat.timeRange("16:00", "22:00"),
                           durationText: "5시간 30분", extraText: "+1시간", extraReadout: "1시간 더", noteText: nil, status: .edited),
            AppLessWorkDay(id: "2026-10-09", dateText: "10월 9일 금", timeText: PumFormat.timeRange("17:00", "22:00"),
                           durationText: nil, extraText: nil, extraReadout: nil, noteText: "한글날 · 예정", status: .upcoming),
        ],
        contractText: "종이 계약서 · 사진 2장")
}
