// UI-IOS-6c · REQ-090 — 약관 및 정책 상태. 행 목록 · 버전 · 날짜 · 값 글자는 모두 서버 값(let). 화면이 버전을 정하지 않는다.
import Foundation

/// 약관 한 줄. id는 서버 문서 id.
nonisolated struct PolicyRow: Equatable, Sendable, Identifiable {
    let id: String
    let title: String
    /// 회색 설명(없으면 nil)
    let detail: String?
    /// 오른쪽 회색 값(「v1.4」 · 「사업장 3곳」 · 「동의 안 함」). 없으면 nil
    let value: String?
    /// 법정 강조(제목 굵게) — 개인정보처리방침
    let isEmphasized: Bool
    /// 값이 「v1.4」 꼴 버전이면 true (읽을 때 「버전 1.4」)
    let valueIsVersion: Bool
}

/// 서버가 주는 약관 변경 예고. 이 값이 있을 때만 띠를 그린다.
nonisolated struct PolicyChangeNotice: Equatable, Sendable {
    /// 「서비스 이용약관」
    let documentName: String
    /// 「2027.01.01」 — 서버 값
    let effectiveDate: String
}

nonisolated struct PoliciesState: Equatable, Sendable {
    static let headerTitle = "약관 및 정책"
    static let noticeTail = "부터 바뀌어요"
    static let noticeAction = "변경 내용"
    static let footerLead = "내가 무엇에 언제 동의했는지는 "
    static let footerLink = "내 동의 내역"
    static let footerTail = "에서 확인하고, 선택 동의는 언제든 철회할 수 있어요."

    let notice: PolicyChangeNotice?
    let rows: [PolicyRow]

    /// 「서비스 이용약관이 2027.01.01부터 바뀌어요」
    func noticeText(_ n: PolicyChangeNotice) -> String {
        n.documentName + Self.noticeMiddle(n.documentName) + n.effectiveDate + Self.noticeTail
    }

    /// 문서 이름 끝 글자에 받침이 있으면 「이 」, 없으면 「가 」(「…동의가」). 한글이 아니면 「이 」
    static func noticeMiddle(_ name: String) -> String {
        guard let last = name.unicodeScalars.last, (0xAC00...0xD7A3).contains(last.value) else { return "이 " }
        return (last.value - 0xAC00) % 28 == 0 ? "가 " : "이 "
    }
    /// 띠를 한 번에 읽는 문구
    func noticeAccessibility(_ n: PolicyChangeNotice) -> String { "\(noticeText(n)), \(Self.noticeAction)" }

    static let footerText = footerLead + footerLink + footerTail

    /// 「v1.4」 → 「버전 1.4」 (스크린 리더용)
    static func spokenVersion(_ v: String) -> String {
        v.hasPrefix("v") ? "버전 " + v.dropFirst() : v
    }

    func spokenValue(_ row: PolicyRow) -> String? {
        guard let v = row.value else { return nil }
        return row.valueIsVersion ? Self.spokenVersion(v) : v
    }

    /// 「개인정보처리방침, 수집 항목 · …, 버전 1.4」
    func rowAccessibility(_ row: PolicyRow) -> String {
        [row.title, row.detail, spokenValue(row)].compactMap { $0 }.joined(separator: ", ")
    }

    static let sample = PoliciesState(
        notice: PolicyChangeNotice(documentName: "서비스 이용약관", effectiveDate: "2027.01.01"),
        rows: sampleRows)

    /// 예고 없는 상태
    static let sampleNoNotice = PoliciesState(notice: nil, rows: sampleRows)

    private static let sampleRows: [PolicyRow] = [
        PolicyRow(id: "terms", title: "서비스 이용약관", detail: nil, value: "v1.2", isEmphasized: false, valueIsVersion: true),
        PolicyRow(id: "privacy", title: "개인정보처리방침", detail: "수집 항목 · 이용 목적 · 보관 기간 · 삭제 요청 방법",
                  value: "v1.4", isEmphasized: true, valueIsVersion: true),
        PolicyRow(id: "location", title: "위치기반서비스 이용약관", detail: nil, value: "v1.1", isEmphasized: false, valueIsVersion: true),
        PolicyRow(id: "collect", title: "개인정보 수집 · 이용 동의", detail: nil, value: "v1.4", isEmphasized: false, valueIsVersion: true),
        PolicyRow(id: "third-party", title: "개인정보 제3자 제공", detail: "소속 사업장에 근무기록 · 계좌 · 서류가 공유되는 범위",
                  value: "사업장 3곳", isEmphasized: false, valueIsVersion: false),
        PolicyRow(id: "e-sign", title: "전자문서 · 전자서명 이용", detail: "근로계약서 · 급여명세서 전자 교부",
                  value: "v1.0", isEmphasized: false, valueIsVersion: true),
        PolicyRow(id: "marketing", title: "마케팅 정보 수신", detail: nil, value: "동의 안 함", isEmphasized: false, valueIsVersion: false),
        PolicyRow(id: "oss", title: "오픈소스 라이선스", detail: nil, value: nil, isEmphasized: false, valueIsVersion: false),
    ]
}
