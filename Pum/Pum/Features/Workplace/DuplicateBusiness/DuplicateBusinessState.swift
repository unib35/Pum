// UI-IOS-5d · REQ-012 — 사업자번호 중복 감지 화면 데이터
// 번호 · 이름 · 날짜 · 인원은 서버 값 그대로(화면에서 만들거나 계산하지 않는다).
import SwiftUI

nonisolated struct DuplicateBusinessState: Equatable, Sendable {
    /// 「123-45-67890」 — 서버가 준 표기 그대로
    var registrationNumber: String
    var existingName: String        // 기존 인증 사업장
    var existingOwner: String       // 「박민수」 — 님 · 대표 호칭은 화면이 붙임
    var existingStaffCount: Int
    var existingRegisteredAt: String // 「2024.03」 서버 문구
    var colorIndex: Int             // 사업장 색은 팔레트 번호(PumAvatarPalette.stores)
    /// 내가 만든 미인증 사업장
    var myName: String              // 「종민김밥 본점 (미인증)」
    var myStaffCount: Int
    var myRecordCount: Int

    var tileColor: Color {
        let n = PumAvatarPalette.stores.count
        return PumAvatarPalette.stores[((colorIndex % n) + n) % n]
    }
    var initial: String { existingName.first.map(String.init) ?? "" }

    var introText: String { "\(registrationNumber) · 사업자 확인은 됐어요. 같은 곳이라면 새로 만들지 말고 기존 사업장에 참여하는 게 좋아요." }
    var existingSubtitle: String { "대표 \(existingOwner) · 직원 \(existingStaffCount)명 · \(existingRegisteredAt) 등록" }
    var joinSubtitle: String { "대표 \(existingOwner)님이 승인하면 관리자 권한을 받아요" }

    /// 직원도 기록도 없을 때만 「삭제돼요」 문장을 쓴다. 있을 때의 문구는 디자인에 없어 문장을 숨긴다.
    var showsDeleteNote: Bool { myStaffCount == 0 && myRecordCount == 0 }

    static let sample = DuplicateBusinessState(
        registrationNumber: "123-45-67890", existingName: "종민김밥 본점", existingOwner: "박민수",
        existingStaffCount: 5, existingRegisteredAt: "2024.03", colorIndex: 0,
        myName: "종민김밥 본점 (미인증)", myStaffCount: 0, myRecordCount: 0)
}

nonisolated enum DuplicateBusinessChoice: Equatable, Sendable { case requestJoin, newBranch, dispute }

/// 선택 한 번만 — 처리 중이면 모든 행 잠금, 실패하면 풀림
nonisolated struct DuplicateChoiceLock: Equatable, Sendable {
    private(set) var pending: DuplicateBusinessChoice?
    var isLocked: Bool { pending != nil }
    mutating func begin(_ c: DuplicateBusinessChoice) -> Bool {
        guard pending == nil else { return false }
        pending = c
        return true
    }
    mutating func finish(success: Bool) { if !success { pending = nil } }
}
