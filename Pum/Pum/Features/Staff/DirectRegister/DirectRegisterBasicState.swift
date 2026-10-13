// UI-IOS-20b · REQ-007 · DEC-001 — 직접 등록 1/3 · 기본 정보
// 필수는 이름 · 휴대폰. 생년월일은 직원이 명세서를 열 때 확인용, 입사일은 고르기(표시 문자열은 호출자 값).
// 휴대폰 · 생년월일은 개인정보 — 로그 · print 금지.
import Foundation

nonisolated enum DirectRegisterBasicField: Equatable, Sendable { case name, phone, birthDate, startDate }

/// 이름 · 휴대폰 화면 초안
nonisolated struct DirectRegisterBasicDraft: Equatable, Sendable {
    var name: String
    var phone: String
}

/// 다음 단계로 넘길 값
nonisolated struct DirectRegisterBasicValue: Equatable, Sendable {
    let name: String
    let phone: String
    /// 호출자가 정한 표시 문자열(원문 「2004. 3. 15」). 비어 있을 수 있음
    let birthDate: String
    /// 호출자가 정한 표시 문자열(원문 「2026. 7. 1 수」)
    let startDate: String
}

nonisolated struct DirectRegisterBasicState: Equatable, Sendable {
    static let backTitle = "직원 추가"
    static let title = "기본 정보"
    static let stepCount = 3
    static let currentStep = 1
    static let nameTitle = "이름"
    static let phoneTitle = "휴대폰"
    static let birthDateTitle = "생년월일"
    static let startDateTitle = "입사일"
    static let phoneHint = "명세서를 이 번호로 보내요"
    static let birthDateHint = "직원이 명세서를 열 때 확인해요"
    static let nextTitle = "다음"
    /// 값이 없을 때 날짜 칸 문구 — 원문 없음(임시)
    static let datePlaceholder = "선택"

    var name: String
    var phone: String
    var birthDate: String
    var startDate: String
    /// 파랑 테두리로 표시할 칸(원문 캡처는 생년월일). 시각 표시만.
    var highlighted: DirectRegisterBasicField?

    var initialDraft: DirectRegisterBasicDraft { .init(name: name, phone: phone) }

    /// 숫자 · 하이픈만 남긴다(엄격한 형식 검증은 원문에 없음)
    static func filterPhone(_ s: String) -> String {
        s.filter { $0.isASCII && ($0.isNumber || $0 == "-") }
    }

    static func canProceed(_ draft: DirectRegisterBasicDraft) -> Bool {
        let name = draft.name.trimmingCharacters(in: .whitespacesAndNewlines)
        return !name.isEmpty && filterPhone(draft.phone).contains { $0.isNumber }
    }

    func value(_ draft: DirectRegisterBasicDraft) -> DirectRegisterBasicValue {
        .init(name: draft.name.trimmingCharacters(in: .whitespacesAndNewlines),
              phone: Self.filterPhone(draft.phone),
              birthDate: birthDate, startDate: startDate)
    }

    // MARK: 읽기 문구

    static var stepReadout: String { "\(stepCount)단계 중 \(currentStep)단계" }
    static var phoneLabel: String { "\(phoneTitle), \(phoneHint)" }
    static var birthDateLabel: String { "\(birthDateTitle), \(birthDateHint)" }

    func dateReadout(_ title: String, hint: String?, value: String) -> String {
        let shown = value.isEmpty ? Self.datePlaceholder : value
        return [title, hint, shown].compactMap { $0 }.joined(separator: ", ")
    }

    // MARK: 예시

    static let sample = DirectRegisterBasicState(name: "김민지", phone: "010-7731-2048",
                                                 birthDate: "2004. 3. 15", startDate: "2026. 7. 1 수",
                                                 highlighted: .birthDate)
    static let empty = DirectRegisterBasicState(name: "", phone: "", birthDate: "", startDate: "")
}
