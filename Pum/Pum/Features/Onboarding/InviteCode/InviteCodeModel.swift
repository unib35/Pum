// UI-IOS-2d · REQ-002 — 초대 코드 입력 상태. 사업장 미리보기는 서버가 준 값을 그대로 보여 준다.
import SwiftUI

/// 코드가 맞을 때 서버가 준 사업장 미리보기(화면에서 만들거나 계산하지 않는다)
nonisolated struct InviteMatch: Equatable, Sendable {
    var workplaceName: String
    var ownerName: String          // 「박민수」 — 사장님 호칭은 화면이 붙임
    var employeeCount: Int
    var daysLeft: Int              // 초대 유효 남은 일수
    /// 사업장 색은 팔레트 번호(PumAvatarPalette.stores, 충돌 #20)
    var colorIndex: Int

    var tileColor: Color {
        let n = PumAvatarPalette.stores.count
        return PumAvatarPalette.stores[((colorIndex % n) + n) % n]
    }
    /// 사업장 색 네모의 글자 = 이름 첫 글자(「종」)
    var initial: String { workplaceName.first.map(String.init) ?? "" }
    /// 「박민수 사장님 · 직원 4명 · 초대 유효 6일 남음」
    var subtitleText: String { "\(ownerName) 사장님 · 직원 \(employeeCount)명 · 초대 유효 \(daysLeft)일 남음" }
    /// VoiceOver 한 요소
    var accessibilityText: String {
        "\(workplaceName), \(ownerName) 사장님, 직원 \(employeeCount)명, 초대 유효 \(daysLeft)일 남음, 확인됨"
    }
}

nonisolated struct InviteCodeState: Equatable, Sendable {
    static let codeLength = 6

    /// 영문 대문자 · 숫자, 최대 6자리
    var code: String
    /// 서버가 준 사업장 미리보기(없으면 카드 숨김)
    var matched: InviteMatch?

    init(code: String = "", matched: InviteMatch? = nil) {
        self.code = Self.sanitized(code)
        self.matched = matched
    }

    /// 디자인 원문: 8F3K2Q 입력 완료 · 종민김밥 본점 매칭
    static let sample = InviteCodeState(
        code: "8F3K2Q",
        matched: InviteMatch(workplaceName: "종민김밥 본점", ownerName: "박민수", employeeCount: 4, daysLeft: 6, colorIndex: 0))

    /// 실제 진입: 빈 코드 · 매칭 없음
    static let entry = InviteCodeState()

    /// 딥링크(카카오톡 링크)로 들어오면 코드가 채워진 채 시작
    static func deepLink(code: String) -> InviteCodeState { InviteCodeState(code: code) }

    /// 대문자 영문 + 숫자만, 6자리까지(붙여넣기 · 자동 채움 포함)
    static func sanitized(_ raw: String) -> String {
        PumCodeField.sanitized(raw, length: codeLength, characters: .alphanumeric)
    }

    var isComplete: Bool { code.count == Self.codeLength }
    /// 코드가 6자리이고 매칭된 사업장이 있을 때만 카드를 보인다
    var visibleMatch: InviteMatch? { isComplete ? matched : nil }
    /// 매칭된 사업장이 없으면 확인 불가(이유 문구 없음, 충돌 #30)
    var canConfirm: Bool { visibleMatch != nil }
}
