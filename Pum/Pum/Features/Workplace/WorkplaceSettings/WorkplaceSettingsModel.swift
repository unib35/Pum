// UI-IOS-4c · REQ-026 · REQ-093 — 사업장 설정 상태. 값 문구(정책 · 반경 · 급여일 · 가산 규칙 · 양식 · 역할)는 서버 값 그대로 담는다.
import Foundation

/// 관리자 한 줄.
struct WorkplaceAdmin: Identifiable, Hashable {
    let id: String
    let name: String
    /// 아바타 글자 — 서버 값(원문: 박 · 유). 공통 규칙(PumAvatar.initial)은 박민수 → 민이라 원문과 달라 값으로 받는다(README 충돌 #21).
    let initial: String
    /// `PumAvatarPalette.people` 순서(원문: 박 = 먹색 5, 유 = 연주황 2)
    let colorIndex: Int
    /// 로그인한 본인이면 이름 옆 「· 나」
    let isMe: Bool
    /// 「대표」 · 「매니저 · 근태만」 — 서버 값
    let roleLabel: String

    var accessibilityText: String { "\(name)\(isMe ? ", 나" : ""), \(roleLabel)" }
}

struct WorkplaceSettingsState: Equatable {
    static let screenTitle = "사업장 설정"
    static let attendanceSection = "근태"
    static let paySection = "급여"
    static let adminSection = "관리자"
    static let addAdminTitle = "관리자 추가"
    static let closeTitle = "사업장 폐업 · 데이터 내보내기"
    static let meMark = "· 나"

    var workplaceName: String
    /// 큰 네모 안 글자(원문: 종)
    var workplaceInitial: String
    /// `PumAvatarPalette.stores` 순서
    var workplaceColorIndex: Int
    /// 업종 · 직원 수 · 주소 — 서버 값 조합
    var category: String
    var staffCount: Int
    var address: String

    var checkInMethod: String
    var overtimePolicy: String
    /// DEC-004 고정값
    var reminderValue: String
    var storeQRAction: String
    var payday: String
    var premiumRules: String
    var reviewRequestSubtitle: String
    var reviewRequestOn: Bool
    var contractTemplate: String
    var admins: [WorkplaceAdmin]

    /// 폐업 · 데이터 내보내기는 대표만(REQ-093) — 본인 역할은 「나」 표시된 관리자의 대표 여부(서버 값)
    var isMeRepresentative: Bool { admins.contains { $0.isMe && $0.roleLabel == "대표" } }

    var infoLine: String { "\(category) · 직원 \(staffCount)명 · \(address)" }
    var infoAccessibilityText: String { "\(workplaceName), \(infoLine)" }

    /// 원문 4c 값
    static let sample = WorkplaceSettingsState(
        workplaceName: "종민김밥 본점", workplaceInitial: "종", workplaceColorIndex: 0,
        category: "음식점", staffCount: 5, address: "부산 김해시 장유로 12",
        checkInMethod: "QR + 위치 100m",
        overtimePolicy: "B · 45분 초과 시 확인",
        reminderValue: "+6시간 종료",
        storeQRAction: "인쇄 · 재발급",
        payday: "매월 10일 · 전월 1–말일",
        premiumRules: "법정 기준 · 휴일 1.5배",
        reviewRequestSubtitle: "매월 말일 자동 발송", reviewRequestOn: true,
        contractTemplate: "표준 · 단시간",
        admins: [
            WorkplaceAdmin(id: "a1", name: "박민수", initial: "박", colorIndex: 5, isMe: true, roleLabel: "대표"),
            WorkplaceAdmin(id: "a2", name: "최유나", initial: "유", colorIndex: 2, isMe: false, roleLabel: "매니저 · 근태만"),
        ])
}
