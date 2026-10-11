// 공통 PumCodeField — 허용 글자 · 길이 · 대문자 · VoiceOver 문구 (2b · 2d)
import Testing
@testable import Pum

struct PumCodeFieldTests {
    @Test func 숫자만_길이까지() {
        #expect(PumCodeField.sanitized("12a3-4567", length: 6, characters: .digits) == "123456")
    }

    @Test func 영문은_대문자로_기호는_버림() {
        #expect(PumCodeField.sanitized("8f3-k2q9", length: 6, characters: .alphanumeric) == "8F3K2Q")
    }

    @Test func 한글은_입력되지_않음() {
        #expect(PumCodeField.sanitized("가8F", length: 6, characters: .alphanumeric) == "8F")
    }

    @Test func 음성_문구() {
        #expect(PumCodeField.accessibilityText(label: "초대 코드", count: 3, length: 6) == "초대 코드, 6자리 중 3자리 입력됨")
    }
}
