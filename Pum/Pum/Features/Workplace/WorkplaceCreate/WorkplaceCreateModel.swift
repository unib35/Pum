// UI-IOS-2i · REQ-010 — 사업장 만들기(사장님 첫 설정) 상태
// 반경 · 주소 · 업종은 서버/선택 값 그대로 받는다(화면에서 정하지 않음). 생성은 인증 없이 가능(REQ-010).
import Foundation

struct WorkplaceCreateState: Equatable {
    enum CheckMethod: String, CaseIterable, Equatable {
        case qrAndLocation = "QR + 위치", locationOnly = "위치만"
        var title: String { rawValue }
    }

    var name: String = ""
    var category: String = ""
    var address: String = ""
    /// 출근 반경(m) — 주소를 고른 뒤 서버가 넘긴 값. 없으면 안내 줄을 숨긴다
    var radiusMeters: Int?
    /// 사업자등록번호(선택) — 비어 있으면 「나중에」
    var businessNumber: String = ""
    /// 매월 N일
    var payday: Int = 10
    var method: CheckMethod = .qrAndLocation
    /// `PumAvatarPalette.stores` 순서의 색 번호(원문은 첫 번째 파랑)
    var markColorIndex: Int = 0
    /// 「다음」을 보낸 뒤 결과를 기다리는 중 — 두 번 보내지 않는다
    var isSubmitting = false

    /// 디자인 원문: 종민김밥 본점 · 음식점 · 부산 김해시 장유로 12 · 반경 100m · 사업자번호 나중에 · 매월 10일 · QR + 위치
    static let sample = WorkplaceCreateState(
        name: "종민김밥 본점", category: "음식점", address: "부산 김해시 장유로 12",
        radiusMeters: 100, payday: 10, method: .qrAndLocation)

    /// 실제 진입: 이름 · 업종 · 주소는 비어 있음
    static let entry = WorkplaceCreateState()

    private static func trimmed(_ s: String) -> String { s.trimmingCharacters(in: .whitespacesAndNewlines) }

    /// 「다음」 활성 조건: 이름 · 업종 · 주소. 사업자등록번호는 선택이라 넣지 않는다(비활성 이유 문구 없음 — 충돌 #30)
    var canProceed: Bool {
        !Self.trimmed(name).isEmpty && !Self.trimmed(category).isEmpty && !Self.trimmed(address).isEmpty && !isSubmitting
    }

    /// 대표 글자 = 이름 첫 글자(비면 빈 네모)
    var markText: String { Self.trimmed(name).first.map(String.init) ?? "" }
    var paydayText: String { "매월 \(payday)일" }
    var radiusText: String? { radiusMeters.map { "위치 출근 반경 \($0)m" } }
    var hasBusinessNumber: Bool { !Self.trimmed(businessNumber).isEmpty }

    /// 보내기 시작 — 이미 보냈거나 조건이 안 되면 false
    mutating func beginSubmit() -> Bool {
        guard canProceed else { return false }
        isSubmitting = true
        return true
    }

    /// 실패하면 다시 누를 수 있게
    mutating func failSubmit() { isSubmitting = false }
}
