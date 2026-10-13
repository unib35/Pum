// UI-IOS-6o · REQ-090 — 개인정보 · 앱 정보 상태. 행 목록 · 개수 · 버전 · 최신 여부는 서버 · 앱 값(let). 화면이 Bundle 버전을 읽지 않는다.
import Foundation

/// 행 한 줄. id는 서버 항목 id.
nonisolated struct PrivacyAppInfoRow: Equatable, Sendable, Identifiable {
    let id: String
    let title: String
    /// 제목 아래 회색 설명(없으면 nil)
    let detail: String?
    /// 오른쪽 회색 값(「3곳」 · 「1.0.0 · 최신」). 없으면 nil
    let value: String?
    /// 위험 의미(빨강) — 계정 삭제
    let isDanger: Bool
    /// 법정 강조(굵게) — 개인정보처리방침
    let isEmphasized: Bool
    /// 누르면 열리는 행인가(›). 앱 버전 행은 false
    let isTappable: Bool
}

nonisolated struct PrivacyAppInfoSection: Equatable, Sendable, Identifiable {
    let id: String
    let title: String
    let rows: [PrivacyAppInfoRow]
}

nonisolated struct PrivacyAppInfoState: Equatable, Sendable {
    static let headerTitle = "개인정보 · 앱 정보"

    let sections: [PrivacyAppInfoSection]

    /// 「연결된 사업장, 3곳」 · 「앱 버전, 1.0.0 · 최신」
    func rowAccessibility(_ row: PrivacyAppInfoRow) -> String {
        [row.title, row.detail, row.value].compactMap { $0 }.joined(separator: ", ")
    }

    static let sample = PrivacyAppInfoState(sections: [
        PrivacyAppInfoSection(id: "privacy", title: "개인정보 관리", rows: [
            row("my-info", "내 정보 확인"),
            row("download", "내 데이터 다운로드", detail: "근무기록 · 명세서 · 계약서 ZIP · 메일로 받기"),
            row("consents", "동의 내역"),
            row("workplaces", "연결된 사업장", value: "3곳"),
            row("documents", "제출한 서류", value: "4건"),
            row("delete-account", "계정 삭제", danger: true),
        ]),
        PrivacyAppInfoSection(id: "app", title: "앱 정보", rows: [
            row("version", "앱 버전", value: "1.0.0 · 최신", tappable: false),
            row("notices", "공지사항"),
            row("terms", "서비스 이용약관"),
            row("privacy-policy", "개인정보처리방침", emphasized: true),
            row("oss", "오픈소스 라이선스"),
            row("company", "운영사 정보"),
        ]),
    ])

    private static func row(_ id: String, _ title: String, detail: String? = nil, value: String? = nil,
                            danger: Bool = false, emphasized: Bool = false, tappable: Bool = true) -> PrivacyAppInfoRow {
        PrivacyAppInfoRow(id: id, title: title, detail: detail, value: value,
                          isDanger: danger, isEmphasized: emphasized, isTappable: tappable)
    }
}
