// UI-IOS-5b · REQ-010 — 직원 초대 전 사업장 인증 시트(왜 필요한지 + 3단계) 데이터
// 이름 · 단계 상태 · 부제는 서버가 준 값 그대로. 화면에서 판단하지 않는다.
import Foundation

/// 인증 한 단계. 번호는 목록 순서(1부터).
nonisolated struct VerifyIntroStep: Equatable, Sendable, Identifiable {
    enum Status: Equatable, Sendable {
        case done       // 완료 — 초록 채움 원 + 흰 체크(원문, 충돌 #35)
        case current    // 지금 단계 — 먹색 채움 원 + 흰 번호
        case upcoming   // 다음 단계 — 회색 채움 원 + 회색 번호
    }
    let title: String
    let subtitle: String
    let status: Status
    var id: String { title }

    /// VoiceOver 상태 말 — 다음 단계는 상태를 따로 말하지 않는다
    var statusText: String? {
        switch status {
        case .done: "완료"
        case .current: "지금 단계"
        case .upcoming: nil
        }
    }

    /// 「1단계 본인 확인, 완료」 · 「2단계 사업자 확인, 지금 단계」 · 「3단계 관리 권한 확인」
    func accessibilityLabel(number: Int) -> String {
        var s = "\(number)단계 \(title)"
        if let statusText { s += ", \(statusText)" }
        return s
    }
}

nonisolated struct VerifyIntroState: Equatable, Sendable {
    var workplaceName: String       // 뒤 화면 QR 이름 — 서버 값
    var steps: [VerifyIntroStep]    // 서버가 준 단계(원문 3개)

    static let screenTitle = "직원 초대"
    static let sheetTitle = "직원을 초대하려면\n사업장 인증이 필요해요"
    static let sheetBody = "직원의 개인정보·근로계약·급여를 다루게 되니, 이 사업장을 관리할 권한이 있는지 한 번 확인해요. 약 2분 걸려요."
    static let startTitle = "인증 시작"
    static let laterTitle = "나중에 할게요"

    var qrCaption: String { "\(workplaceName) 초대 QR" }

    /// 원문 캡처 — 가짜 예시 값
    static let sample = VerifyIntroState(
        workplaceName: "종민김밥 본점",
        steps: [
            VerifyIntroStep(title: "본인 확인", subtitle: "가입 시 휴대폰 인증 완료 \u{00B7} 박민수", status: .done),
            VerifyIntroStep(title: "사업자 확인", subtitle: "사업자등록번호 \u{00B7} 대표자명 \u{00B7} 개업일", status: .current),
            VerifyIntroStep(title: "관리 권한 확인", subtitle: "대표자 본인이거나, 대표자에게 위임받은 관리자", status: .upcoming)
        ])
}
