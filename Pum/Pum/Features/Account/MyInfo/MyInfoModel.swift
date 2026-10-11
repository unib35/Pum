// UI-IOS-4a · REQ-001 — 「내 정보」 상태. 서버가 준 값을 그대로 담는다(화면에서 계산 · 가림 처리 없음).
// 금액은 정수(원). 계좌는 서버가 이미 가린 문구.
import Foundation

/// 소속 사업장 한 줄. 서명 대기 같은 처리 필요 문구가 있으면 둘째 줄이 그 문구(주황)로 바뀐다.
struct MyInfoWorkplace: Identifiable, Hashable {
    let id: String
    let name: String
    /// 사업장 색 네모 안 글자(원문: 종 · B · C)
    let initial: String
    /// `PumAvatarPalette.stores` 순서(블루 · 갈색 · 남색)
    let colorIndex: Int
    /// 「직원」
    let roleLabel: String
    /// 시급(원, 서버 값)
    let hourlyWage: Int
    /// 「계약 체결」
    let contractLabel: String
    /// 「변경 계약서 서명 대기」 — 있으면 둘째 줄을 대신한다(서버 값)
    let attentionNote: String?

    var subtitle: String {
        attentionNote ?? "\(roleLabel) · 시급 \(PumFormat.amount(hourlyWage))원 · \(contractLabel)"
    }

    var hasAttention: Bool { attentionNote != nil }

    var accessibilityText: String { "\(name), \(subtitle)" }
}

struct MyInfoState: Equatable {
    var name: String
    /// 「010-4821-7733 · 카카오 로그인」 — 서버 값 문구
    var accountLine: String
    var workplaces: [MyInfoWorkplace]
    /// 개인 근무 조건의 시급(원)
    var personalHourlyWage: Int
    var contractCount: Int
    /// 보건증 남은 일(서버 계산값). nil이면 표시 없음
    var healthCertDaysLeft: Int?
    /// 「카카오뱅크」
    var bankName: String
    /// 「****821」 — 서버가 가린 값 그대로
    var maskedAccount: String

    var workplaceHeader: String { "소속 사업장 \(workplaces.count)" }
    var contractCountText: String { "\(contractCount)건" }
    var healthCertText: String? { healthCertDaysLeft.map { "보건증 \($0)일" } }
    var bankText: String { "\(bankName) \(maskedAccount)" }
    var personalWageText: String { "시급 \(PumFormat.amount(personalHourlyWage))원" }
    /// 큰 아바타 글자 — 공통 규칙(PumAvatar.initial)
    var avatarInitial: String { PumAvatar.initial(for: name) }

    /// 원문 4a 값
    static let sample = MyInfoState(
        name: "이종민",
        accountLine: "010-4821-7733 · 카카오 로그인",
        workplaces: [
            MyInfoWorkplace(id: "w1", name: "종민김밥 본점", initial: "종", colorIndex: 0, roleLabel: "직원", hourlyWage: 12_000, contractLabel: "계약 체결", attentionNote: nil),
            MyInfoWorkplace(id: "w2", name: "B카페 서면점", initial: "B", colorIndex: 1, roleLabel: "직원", hourlyWage: 12_000, contractLabel: "계약 체결", attentionNote: "변경 계약서 서명 대기"),
            MyInfoWorkplace(id: "w3", name: "C학원", initial: "C", colorIndex: 2, roleLabel: "직원", hourlyWage: 15_000, contractLabel: "계약 체결", attentionNote: nil),
        ],
        personalHourlyWage: 12_000,
        contractCount: 3,
        healthCertDaysLeft: 42,
        bankName: "카카오뱅크",
        maskedAccount: "****821"
    )
}
