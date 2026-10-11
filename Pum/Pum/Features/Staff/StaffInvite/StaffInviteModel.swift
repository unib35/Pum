// UI-IOS-1x · REQ-002 — 직원 초대: 입력 상태 · 문구 · 형식
// 초대 코드(6자리, 0·O·1·I 제외) · 7일 유효 · 남은 일수 · 사업장 이름은 서버 값 — 화면에서 만들거나 계산하지 않는다.
import Foundation

/// 보내는 방법 (REQ-002: 알림톡 기본, 안 가면 문자)
nonisolated enum InviteMethod: CaseIterable, Sendable, Hashable {
    case alimtalk, sms, app

    var title: String {
        switch self {
        case .alimtalk: "알림톡"
        case .sms: "문자"
        case .app: "앱으로 초대"
        }
    }

    /// 하단 버튼 문구
    var sendTitle: String {
        switch self {
        case .alimtalk: "알림톡으로 초대 보내기"
        case .sms: "문자로 초대 보내기"
        case .app: "앱으로 초대 보내기"
        }
    }

    /// 안내 문구 — 알림톡만 디자인 원문. 문자 · 앱은 디자인 없음: 알림톡 문구에서 첫 문장을 뺀 것(오케스트레이터 지정, 확인 필요)
    var guide: String {
        switch self {
        case .alimtalk: "알림톡이 안 가면 같은 내용을 문자로 보내요 \u{00B7} 7일 동안 \u{00B7} 이 번호로만 수락"
        case .sms, .app: "7일 동안 \u{00B7} 이 번호로만 수락"
        }
    }
}

/// 수락 대기 중인 직원 한 명 (서버 값)
nonisolated struct PendingInvite: Equatable, Sendable, Identifiable {
    var id: String
    var name: String
    /// 예: 「어제 알림톡」 — 서버가 준 문구
    var sentText: String
    /// 서버가 준 남은 일수
    var daysLeft: Int

    var statusText: String { "\(name) \u{00B7} 수락 대기" }
    var detailText: String { "\(sentText) \u{00B7} \(daysLeft)일 남음" }
    var accessibilityLabel: String { "\(name), 수락 대기, \(sentText), \(daysLeft)일 남음" }
    /// 아바타 글자 — 원문(한지우 → 한)은 성의 첫 글자
    var avatarInitial: String { name.trimmingCharacters(in: .whitespaces).first.map(String.init) ?? "" }
}

nonisolated struct StaffInviteDraft: Equatable, Sendable {
    /// 번호 숫자 자릿수 (010-XXXX-XXXX)
    static let phoneDigitCount = 11
    /// 초대 코드 길이 (REQ-002)
    static let codeLength = 6

    // 서버 값
    var workplaceName: String
    var ownerName: String
    var inviteCode: String
    var pending: [PendingInvite]

    // 입력
    var name = ""
    var phone = ""
    var method: InviteMethod = .alimtalk

    var ownerLine: String { "\(workplaceName) \u{00B7} 대표 \(ownerName)" }

    /// 이름 · 번호(11자리)가 다 채워져야 보낼 수 있다
    var canSend: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && Self.digits(phone).count == Self.phoneDigitCount
    }
    var sendTitle: String { method.sendTitle }
    var guideText: String { method.guide }

    var codeDisplay: String { Self.codeDisplay(inviteCode) }
    var codeAccessibility: String {
        "초대 코드, " + inviteCode.map(String.init).joined(separator: " ")
    }

    // MARK: 형식

    static func digits(_ s: String) -> String { s.filter { $0.isASCII && $0.isNumber } }

    /// 숫자만 남기고 11자리까지 — 010-XXXX-XXXX. 3자리까지는 하이픈 없음, 7자리까지는 앞 3 + 나머지.
    static func formatPhone(_ s: String) -> String {
        let d = String(digits(s).prefix(phoneDigitCount))
        switch d.count {
        case 0...3: return d
        case 4...7: return d.prefix(3) + "-" + d.dropFirst(3)
        default: return d.prefix(3) + "-" + d.dropFirst(3).prefix(4) + "-" + d.dropFirst(7)
        }
    }

    /// K7X4MP → 「K7X 4MP」. 6자리가 아니면 그대로(서버 값 방어)
    static func codeDisplay(_ code: String) -> String {
        guard code.count == codeLength else { return code }
        return code.prefix(3) + " " + code.suffix(3)
    }
}

extension StaffInviteDraft {
    /// 실제 진입 기본값 — 빈 입력 (초대 코드 · 대기 목록 · 사업장은 서버 값 자리)
    static let empty = StaffInviteDraft(
        workplaceName: "종민김밥 본점", ownerName: "박민수", inviteCode: "K7X4MP",
        pending: [PendingInvite(id: "p1", name: "한지우", sentText: "어제 알림톡", daysLeft: 6)]
    )

    /// 디자인 1x 캡처(가짜 값) — 이름 · 번호 입력됨
    static let sample: StaffInviteDraft = {
        var d = empty
        d.name = "정우진"
        d.phone = "010-4182-7750"
        return d
    }()
}
