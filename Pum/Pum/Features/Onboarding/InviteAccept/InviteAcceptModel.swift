// UI-IOS-1o · REQ-002 · REQ-060 — 초대 수락 화면 데이터
// 근로조건 값은 서버가 준 문구 그대로 보여 준다(화면에서 만들거나 계산하지 않는다).
import SwiftUI

nonisolated struct InviteTerm: Equatable, Sendable, Identifiable {
    /// 서버 순서 번호 — 같은 라벨이 두 번 와도 겹치지 않게
    let order: Int
    let label: String   // 「급여 형태」
    let value: String   // 「시급 12,000원」
    var id: Int { order }
    var accessibilityText: String { "\(label), \(value)" }
}

nonisolated struct InviteAcceptRecord: Equatable, Sendable {
    var ownerName: String          // 「박민수」 — 사장님 호칭은 화면이 붙임
    var workplaceName: String
    /// 사업장 색은 팔레트 번호(PumAvatarPalette.stores, 충돌 #20)
    var colorIndex: Int
    var address: String
    var category: String
    var employeeCount: Int
    /// 서버가 준 제안 근로조건(순서 · 문구 그대로). 값이 빈 항목은 화면에서 생략한다.
    var terms: [InviteTerm]

    var tileColor: Color {
        let n = PumAvatarPalette.stores.count
        return PumAvatarPalette.stores[((colorIndex % n) + n) % n] // 음수 · 범위 밖 번호 방어(서버 값)
    }
    /// 사업장 색 네모의 글자 = 이름 첫 글자(「종」) — 사람 이름 규칙(PumAvatar.initial)은 쓰지 않는다
    var initial: String { workplaceName.first.map(String.init) ?? "" }

    /// 큰 제목 조각: 「박민수 사장님이⏎」 + 사업장 이름(파랑) + 「에⏎초대했어요」 — 원문은 세 줄로 끊는다
    var titleLead: String { "\(ownerName) 사장님이\n" }
    var titleTail: String { "에\n초대했어요" }
    /// 한 문장(VoiceOver · 테스트) — 줄바꿈은 공백으로
    var titleText: String { (titleLead + workplaceName + titleTail).replacingOccurrences(of: "\n", with: " ") }

    /// 「부산 김해시 장유로 12 · 음식점 · 직원 4명」
    var subtitleText: String { "\(address) · \(category) · 직원 \(employeeCount)명" }

    /// 값이 빈 행은 생략(디자인에 빈 값 규칙 없음 — 보고)
    var visibleTerms: [InviteTerm] {
        terms.filter { !$0.value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }

    static let sample = InviteAcceptRecord(
        ownerName: "박민수", workplaceName: "종민김밥 본점", colorIndex: 0,
        address: "부산 김해시 장유로 12", category: "음식점", employeeCount: 4,
        terms: [
            .init(order: 1, label: "급여 형태", value: "시급 12,000원"),
            .init(order: 2, label: "기본 근무일", value: "월 · 수 · 금"),
            .init(order: 3, label: "기본 근무시간", value: "17:00 – 22:00"),
            .init(order: 4, label: "휴게시간", value: "30분"),
            .init(order: 5, label: "급여일", value: "매월 10일"),
            .init(order: 6, label: "출퇴근 방식", value: "매장 QR + 위치 확인"),
        ])
}
