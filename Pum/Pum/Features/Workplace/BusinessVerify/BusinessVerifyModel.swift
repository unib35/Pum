// UI-IOS-5c · REQ-011 — 사업자 확인 상태(등록번호 10자리 · 대표자명 · 개업일)
// 입력값은 개인정보 — 로그 · 프린트에 남기지 않는다.
import Foundation

struct BusinessVerifyState: Equatable {
    static let numberLength = 10

    /// 숫자만, 최대 10자리(하이픈 없음)
    var registrationNumber: String = ""
    var representative: String = ""
    /// 화면에 보이는 개업일(예: 2024.03.12) — 날짜 선택 결과를 호출한 쪽이 문자열로 넣는다
    var openDate: String = ""
    /// 보낸 뒤 결과를 기다리는 중(한 번만 보낸다)
    var isSubmitting = false

    /// 디자인 원문: 123-45-67890 · 박민수 · 2024.03.12 (가짜 값)
    static let sample = BusinessVerifyState(registrationNumber: "1234567890", representative: "박민수", openDate: "2024.03.12")

    /// 실제 진입: 빈 값
    static let entry = BusinessVerifyState()

    /// 숫자만 · 10자리까지로 다듬는다(붙여넣기 · 하이픈 포함 입력)
    static func sanitized(_ raw: String) -> String {
        String(raw.filter { $0.isASCII && $0.isNumber }.prefix(numberLength))
    }

    /// 3-2-5 하이픈 표시. 자릿수가 모자라면 있는 만큼만(하이픈은 다음 숫자가 올 때 붙는다)
    static func formatted(_ digits: String) -> String {
        let d = sanitized(digits)
        let a = d.prefix(3)
        let b = d.dropFirst(3).prefix(2)
        let c = d.dropFirst(5)
        var out = String(a)
        if !b.isEmpty { out += "-" + b }
        if !c.isEmpty { out += "-" + c }
        return out
    }

    var formattedNumber: String { Self.formatted(registrationNumber) }

    /// VoiceOver: 하이픈 없이 숫자를 하나씩
    var numberAccessibilityValue: String {
        registrationNumber.map(String.init).joined(separator: " ")
    }

    /// 세 칸이 모두 있어야 활성(비활성 이유 문구는 디자인 없음 — 충돌 #30)
    var isReady: Bool {
        registrationNumber.count == Self.numberLength
            && !representative.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !openDate.isEmpty
    }

    var canSubmit: Bool { isReady && !isSubmitting }
}
