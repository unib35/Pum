// UI-IOS-2l · REQ-061 — 사장님 「직원 상세」 값. 모든 값(날짜 · 남은 일수 · 상태 · 가린 계좌)은 서버 값 그대로 쓴다.
// 개인정보(전화번호 · 계좌)는 로그 · 프린트 금지. 계좌는 서버가 이미 가린 문자열이며 앱은 가리지도 풀지도 않는다.
import Foundation

/// 서류 한 줄의 상태 종류 — 배지 색을 정한다(서버가 정한 상태를 앱이 다시 계산하지 않는다)
enum StaffDocumentTone: Equatable, Sendable {
    case attention  // 갱신 예정 등 확인 필요(주황)
    case done       // 완료(초록)
    case missing    // 미제출(회색)
}

struct StaffDocument: Identifiable, Equatable, Sendable {
    let id: String
    let title: String
    /// 제목 옆 작은 회색 보충(예: 「(건강진단결과서)」). 괄호까지 서버 문구 그대로.
    var qualifier: String?
    /// 「2026.11.14 만료 · 42일 남음」 같은 둘째 줄
    let detail: String
    let statusText: String
    let tone: StaffDocumentTone

    /// 음성 안내: 「2026.11.14」 → 「2026년 11월 14일」, 가운뎃점 → 쉼표
    var spokenDetail: String {
        var s = detail.replacingOccurrences(of: " \u{00B7} ", with: ", ")
        if let r = s.range(of: #"\d{4}\.\d{1,2}\.\d{1,2}"#, options: .regularExpression) {
            let p = s[r].split(separator: ".").compactMap { Int($0) }
            if p.count == 3 { s.replaceSubrange(r, with: "\(p[0])년 \(p[1])월 \(p[2])일") }
        }
        return s
    }

    /// 「보건증, 2026년 11월 14일 만료, 42일 남음, 갱신 예정」
    var accessibilityText: String { "\(title), \(spokenDetail), \(statusText)" }
}

struct StaffDetailState: Equatable, Sendable {
    let name: String
    var colorIndex = 0
    /// 「홀 서빙·마감」 서버 값
    let roleText: String
    /// 「2026.10.05」 서버 값
    let joinedDate: String
    let hourlyWage: Int
    let phone: String
    /// 없으면 행을 숨긴다
    var emergencyPhone: String?
    var emergencyRelation: String?
    /// 서버가 가린 값 그대로(예: 「카카오뱅크 3333-**-****821」). 없으면 행을 숨긴다.
    var maskedAccount: String?
    let documents: [StaffDocument]
    let notice: String

    /// 「홀 서빙·마감 · 2026.10.05 입사 · 시급 12,000원」
    var summaryText: String {
        "\(roleText) \u{00B7} \(joinedDate) 입사 \u{00B7} 시급 \(PumFormat.amount(hourlyWage))원"
    }

    var hasEmergency: Bool { !(emergencyPhone ?? "").isEmpty }
    var hasAccount: Bool { !(maskedAccount ?? "").isEmpty }

    var headerAccessibilityText: String { "\(name), \(summaryText)" }
    var callAccessibilityLabel: String { "\(name)에게 전화" }
    var messageAccessibilityLabel: String { "\(name)에게 문자" }
    var kakaoAccessibilityLabel: String { "\(name)에게 카카오톡" }
    var emergencyAccessibilityText: String {
        "비상 연락처, \(emergencyPhone ?? "")\(emergencyRelation.map { ", \($0)" } ?? "")"
    }

    static let sample = StaffDetailState(
        name: "이종민", colorIndex: 0, roleText: "홀 서빙\u{00B7}마감", joinedDate: "2026.10.05", hourlyWage: 12_000,
        phone: "010-4821-7733", emergencyPhone: "010-2210-9981", emergencyRelation: "어머니",
        maskedAccount: "카카오뱅크 3333-**-****821",
        documents: [
            .init(id: "health", title: "보건증", qualifier: "(건강진단결과서)", detail: "2026.11.14 만료 \u{00B7} 42일 남음",
                  statusText: "갱신 예정", tone: .attention),
            .init(id: "contract", title: "근로계약서", detail: "2026.10.03 양측 서명 \u{00B7} PDF", statusText: "완료", tone: .done),
            .init(id: "idcard", title: "신분증 사본", detail: "2026.10.03 제출", statusText: "완료", tone: .done),
            .init(id: "bankbook", title: "통장 사본", detail: "아직 안 받음", statusText: "미제출", tone: .missing),
        ],
        notice: "보건증은 만료 30일 전 직원과 사장님 모두에게 알려드려요. 서류 사진은 직원이 앱에서 직접 올려요.")
}
