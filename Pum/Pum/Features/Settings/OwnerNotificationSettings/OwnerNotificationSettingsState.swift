// UI-IOS-6g · REQ-092 — 사장님 「알림 설정」: 카테고리별, 사업장마다 따로. 문구 · 기준(15분 · +30분 · 30일)은 서버 글자.

nonisolated struct OwnerNotificationRow: Equatable, Identifiable {
    let id: String
    let title: String
    let subtitle: String?
    let isOn: Bool

    /// VoiceOver 라벨 — 「출퇴근 이상, 지각 · 조퇴 · 미출근 15분」
    var accessibilityText: String { subtitle.map { "\(title), \($0)" } ?? title }
}

nonisolated struct OwnerNotificationSection: Equatable, Identifiable {
    let id: String
    let title: String
    let rows: [OwnerNotificationRow]
}

nonisolated struct OwnerNotificationSettingsState: Equatable {
    /// 서버가 준 짧은 사업장 이름
    let workplaceName: String
    let sections: [OwnerNotificationSection]

    static let screenTitle = "알림 설정"
    var workplaceAccessibilityLabel: String { "사업장 선택, \(workplaceName)" }

    /// 원문 6g
    static let sample = OwnerNotificationSettingsState(
        workplaceName: "본점",
        sections: [
            OwnerNotificationSection(id: "work", title: "근무", rows: [
                OwnerNotificationRow(id: "attendance", title: "직원 출퇴근", subtitle: "출근 · 퇴근할 때마다", isOn: true),
                OwnerNotificationRow(id: "anomaly", title: "출퇴근 이상", subtitle: "지각 · 조퇴 · 미출근 15분", isOn: true),
                OwnerNotificationRow(id: "missingOut", title: "퇴근 미기록", subtitle: "예정 퇴근 +30분", isOn: true),
                OwnerNotificationRow(id: "requests", title: "수정 · 휴무 · 대타 요청", subtitle: nil, isOn: true),
            ]),
            OwnerNotificationSection(id: "pay", title: "급여", rows: [
                OwnerNotificationRow(id: "settleStart", title: "정산 시작 · 직원 확인 회신", subtitle: nil, isOn: true),
                OwnerNotificationRow(id: "payday", title: "지급일 하루 전", subtitle: nil, isOn: true),
            ]),
            OwnerNotificationSection(id: "workplace", title: "사업장", rows: [
                OwnerNotificationRow(id: "noticeRead", title: "공지 확인 현황", subtitle: "미확인 직원이 남았을 때", isOn: true),
                OwnerNotificationRow(id: "docExpiry", title: "서류 만료", subtitle: "보건증 만료 30일 전", isOn: true),
            ]),
            OwnerNotificationSection(id: "service", title: "서비스", rows: [
                OwnerNotificationRow(id: "serviceNotice", title: "서비스 공지", subtitle: "점검 · 정책 변경", isOn: true),
                OwnerNotificationRow(id: "marketing", title: "마케팅", subtitle: "이벤트 · 혜택", isOn: false),
            ]),
        ]
    )
}
