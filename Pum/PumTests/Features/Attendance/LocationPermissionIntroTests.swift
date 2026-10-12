// UI-IOS-6e · REQ-023 — 위치 권한 안내: 원문 값 · 읽기 문구
import Testing
import Foundation
@testable import Pum

struct LocationPermissionIntroTests {
    let s = LocationPermissionIntroState.sample

    @Test func 원문_문구() {
        #expect(s.workplaceName == "종민김밥 본점")
        #expect(s.shiftDateText == "10월 5일 월 \u{00B7} 첫 근무")
        #expect(s.shiftTimeText == "17:00 \u{2013} 22:00")
        #expect(s.clockInTitle == "출근하기")
        #expect(LocationPermissionIntroState.headingFirstLine == "매장에서 출근했는지")
        #expect(LocationPermissionIntroState.headingSecondLine == "위치로 확인해요")
        #expect(LocationPermissionIntroState.continueTitle == "계속")
        #expect(LocationPermissionIntroState.qrOnlyTitle == "위치 없이 QR로만 출근할게요")
        #expect(s.reasons.map(\.title) == [
            "출퇴근 버튼을 누를 때만 확인해요",
            "사장님께는 \"매장 반경 안/밖\"만 전달돼요",
            "언제든 끌 수 있어요",
        ])
        #expect(s.reasons.map(\.detail) == [
            "근무 중이 아닐 때는 위치를 모으지 않아요",
            "정확한 좌표나 이동 경로는 공유하지 않아요",
            "꺼도 매장 QR로 출근할 수 있어요",
        ])
    }

    @Test func 읽기_문구() {
        #expect(s.reasons[0].spoken == "1, 출퇴근 버튼을 누를 때만 확인해요, 근무 중이 아닐 때는 위치를 모으지 않아요")
        #expect(s.reasons[2].spoken == "3, 언제든 끌 수 있어요, 꺼도 매장 QR로 출근할 수 있어요")
        #expect(s.hintPlain == "다음 화면에서 iPhone이 물어보면 \"앱을 사용하는 동안 허용\"을 선택해주세요.")
        #expect(s.headingPlain == "매장에서 출근했는지 위치로 확인해요")
    }
}
