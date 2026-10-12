// UI-IOS-6e · REQ-023 — 위치 권한: 처음 출근할 때 이유를 먼저, 그다음 iOS 팝업.
// 문구 · 사업장 · 시간은 서버/상수 값 그대로. 시스템 위치 권한 요청은 호출자 몫(여기서 CoreLocation을 쓰지 않는다).
import Foundation

nonisolated struct LocationPermissionReason: Equatable, Sendable, Identifiable {
    /// 번호 원 글자 「1」
    var number: Int
    var title: String
    var detail: String

    var id: Int { number }
    /// 「1, 출퇴근 버튼을 누를 때만 확인해요, 근무 중이 아닐 때는 위치를 모으지 않아요」
    var spoken: String { "\(number), \(title), \(detail)" }
}

nonisolated struct LocationPermissionIntroState: Equatable, Sendable {
    static let headingFirstLine = "매장에서 출근했는지"
    static let headingSecondLine = "위치로 확인해요"
    static let continueTitle = "계속"
    static let qrOnlyTitle = "위치 없이 QR로만 출근할게요"
    /// 안내 문장 앞 · 굵은 부분 · 뒤
    static let hintBefore = "다음 화면에서 iPhone이 물어보면 "
    static let hintStrong = "\"앱을 사용하는 동안 허용\""
    static let hintAfter = "을 선택해주세요."

    /// 뒤 화면(첫 근무 홈)
    var workplaceName: String
    var workplaceInitial: String
    /// 「10월 5일 월 · 첫 근무」
    var shiftDateText: String
    /// 「17:00 – 22:00」
    var shiftTimeText: String
    var clockInTitle: String
    var reasons: [LocationPermissionReason]

    var hintPlain: String { Self.hintBefore + Self.hintStrong + Self.hintAfter }
    var headingPlain: String { "\(Self.headingFirstLine) \(Self.headingSecondLine)" }

    static let sample = LocationPermissionIntroState(
        workplaceName: "종민김밥 본점",
        workplaceInitial: "종",
        shiftDateText: "10월 5일 월 \u{00B7} 첫 근무",
        shiftTimeText: "17:00 \u{2013} 22:00",
        clockInTitle: "출근하기",
        reasons: [
            .init(number: 1, title: "출퇴근 버튼을 누를 때만 확인해요", detail: "근무 중이 아닐 때는 위치를 모으지 않아요"),
            .init(number: 2, title: "사장님께는 \"매장 반경 안/밖\"만 전달돼요", detail: "정확한 좌표나 이동 경로는 공유하지 않아요"),
            .init(number: 3, title: "언제든 끌 수 있어요", detail: "꺼도 매장 QR로 출근할 수 있어요"),
        ]
    )
}
