// UI-IOS-1ac · REQ-060 — 사장님 직원 관리 목록 데이터
// 시급 · 근무 조건 · 보건증 남은 일수 · 계약 상태 · 건수는 서버가 준 값을 그대로 보여 준다. 화면에서 세거나 계산하지 않는다.
import SwiftUI

/// 계약 상태(REQ-060). 색 의미: 초록 = 완료, 주황 = 확인 필요(서명 대기), 회색 = 아직 시작 전(초대 중)
nonisolated enum StaffContractStatus: Equatable, Sendable {
    case contracted, awaitingSignature, invited

    enum Tone: Equatable, Sendable { case done, attention, neutral }

    var title: String {
        switch self {
        case .contracted: "계약 완료"
        case .awaitingSignature: "서명 대기"
        case .invited: "초대 중"
        }
    }

    var tone: Tone {
        switch self {
        case .contracted: .done
        case .awaitingSignature: .attention
        case .invited: .neutral
        }
    }
}

nonisolated struct StaffMember: Equatable, Sendable, Identifiable {
    let id: String
    let name: String
    let colorIndex: Int
    let status: StaffContractStatus
    /// 근무 요일 — 「월·수·금」(원문 가운뎃점, 공백 없음). 초대 중은 nil(조건 미설정)
    let daysText: String?
    let startHour: Int
    let endHour: Int
    /// 「홀 서빙」 · 「주방 보조 · 3년차」 등 서버 문구
    let note: String?
    /// 보건증 남은 일수(없으면 nil) — 서버 값
    let healthCertDaysLeft: Int?
    /// 임박 경고 여부 — 서버가 정한다(기준을 앱이 계산하지 않음)
    let healthCertWarning: Bool
    /// 시급(원) — 초대 중은 nil
    let hourlyWage: Int?
    /// 전화 버튼 표시 — 원문은 이종민 행만. 기준(오늘 근무자 등)은 디자인 없음 → 서버 지정
    let showsCallButton: Bool
    /// MVP: 분까지 있는 시간(「09:30–18」)과 월급 단위(「원/월」), 계약 상태 숨김
    var hoursTextOverride: String? = nil
    var wageUnit = "원/h"
    var showsStatus = true

    var isInvited: Bool { status == .invited }

    /// 「17–22」(en dash)
    var hoursText: String { hoursTextOverride ?? String(format: "%02d\u{2013}%02d", startHour, endHour) }
    /// 「월·수·금 17–22」 / 초대 중은 「초대 중 · 조건 미설정」
    var scheduleText: String {
        guard let daysText else { return "\(status.title) \u{00B7} 조건 미설정" }
        return "\(daysText) \(hoursText)"
    }
    /// 보건증 앞까지 줄: 「화·목·토 17–22 · 홀 서빙」
    var conditionText: String {
        guard daysText != nil else { return scheduleText }
        return [scheduleText, note].compactMap { $0 }.joined(separator: " \u{00B7} ")
    }
    var healthCertText: String? { healthCertDaysLeft.map { "보건증 \($0)일 남음" } }

    var wageText: String? { hourlyWage.map { PumFormat.amount($0) } }

    /// 「이종민, 월·수·금 17시부터 22시, 보건증 42일 남음, 시급 12,000원, 계약 완료」
    var accessibilityText: String {
        if isInvited { return "\(name), \(status.title), 조건 미설정" }
        var parts = [name]
        if let daysText { parts.append("\(daysText) \(startHour)시부터 \(endHour)시") }
        if let note { parts.append(note) }
        if let healthCertText { parts.append(healthCertWarning ? "\(healthCertText), 확인 필요" : healthCertText) } // 주황 경고를 말로도
        if let wageText { parts.append(wageUnit == "원/월" ? "월급 \(wageText)원" : "시급 \(wageText)원") }
        if showsStatus { parts.append(status.title) }
        return parts.joined(separator: ", ")
    }

    var callAccessibilityLabel: String { "\(name)에게 전화" }
    var setConditionAccessibilityLabel: String { "\(name) 조건 설정" }
}

nonisolated struct StaffRoster: Equatable, Sendable {
    var workplaceName: String
    var workplaceInitial: String
    /// 서버 값 — 행 수로 세지 않는다
    var headcount: Int
    var contractedCount: Int
    var awaitingCount: Int
    var invitedCount: Int
    var members: [StaffMember]
    /// MVP(DEC-033): 계약 · 초대 상태 줄을 숨긴다
    var isSolo = false

    var headcountText: String { "\(headcount)명" }
    var headcountSuffix: String { " 재직" }
    var breakdownText: String {
        "계약 완료 \(contractedCount) \u{00B7} 서명 대기 \(awaitingCount) \u{00B7} 초대 중 \(invitedCount)"
    }
    var summaryAccessibilityText: String { isSolo ? "\(headcountText) 재직" : "\(headcountText) 재직, \(breakdownText)" }

    static let sample = StaffRoster(
        workplaceName: "종민김밥 본점", workplaceInitial: "종",
        headcount: 5, contractedCount: 3, awaitingCount: 1, invitedCount: 1,
        members: [
            .init(id: "s1", name: "이종민", colorIndex: 0, status: .contracted, daysText: "월·수·금", startHour: 17, endHour: 22,
                  note: nil, healthCertDaysLeft: 42, healthCertWarning: true, hourlyWage: 12_000, showsCallButton: true),
            .init(id: "s2", name: "김하늘", colorIndex: 1, status: .contracted, daysText: "화·목·토", startHour: 17, endHour: 22,
                  note: "홀 서빙", healthCertDaysLeft: nil, healthCertWarning: false, hourlyWage: 11_500, showsCallButton: false),
            .init(id: "s3", name: "최유나", colorIndex: 2, status: .contracted, daysText: "월–금", startHour: 9, endHour: 15,
                  note: "주방 보조 \u{00B7} 3년차", healthCertDaysLeft: nil, healthCertWarning: false, hourlyWage: 13_000, showsCallButton: false),
            .init(id: "s4", name: "박서준", colorIndex: 3, status: .awaitingSignature, daysText: "토·일", startHour: 9, endHour: 15,
                  note: "홀 서빙", healthCertDaysLeft: nil, healthCertWarning: false, hourlyWage: 11_000, showsCallButton: false),
            .init(id: "s5", name: "정우진", colorIndex: 4, status: .invited, daysText: nil, startHour: 0, endHour: 0,
                  note: nil, healthCertDaysLeft: nil, healthCertWarning: false, hourlyWage: nil, showsCallButton: false),
        ])
}
