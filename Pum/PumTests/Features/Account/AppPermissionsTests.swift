// UI-IOS-6f · REQ-023 — 앱 권한: 원문 값 · 상태별 글자 · 읽기 문구
import Testing
@testable import Pum

struct AppPermissionsTests {
    let s = AppPermissionsState.sample

    @Test func 원문_값() {
        #expect(AppPermissionsState.headerTitle == "앱 권한")
        #expect(AppPermissionsState.intro == "필요한 기능을 처음 쓸 때 한 번만 물어봐요. 허용 여부는 iPhone 설정에서 바꿀 수 있어요.")
        #expect(s.rows.map(\.kind.title) == ["위치", "카메라", "알림", "Face ID", "사진"])
        #expect(s.rows.map(\.kind.reason) == ["출퇴근 장소 확인 · 출퇴근 버튼을 누를 때만", "매장 QR 스캔 · 사업자등록증 · 보건증 촬영",
                                              "출퇴근 · 근무 요청 · 급여 확정", "급여 · 명세서 · 계좌 정보 보호", "서류 제출 시 앨범에서 선택"])
        #expect(s.rows.map(\.status.text) == ["앱 사용 중", "허용", "허용", "켜짐", "묻지 않음"])
        #expect(AppPermissionsState.unrequestedHeader == "요청하지 않는 권한")
        #expect(AppPermissionsState.unrequestedBody == "연락처 · 마이크 · 백그라운드 위치(항상 허용) · 추적(ATT)은 쓰지 않아요.")
        #expect(AppPermissionsState.openSettingsTitle == "iPhone 설정 열기")
    }

    @Test func 상태별_글자와_색() {
        #expect(AppPermissionStatus.denied.text == "거부됨")
        #expect(AppPermissionStatus.off.text == "꺼짐")
        #expect(s.rows.map(\.status.isActive) == [true, true, true, true, false])
        #expect(!AppPermissionStatus.denied.isActive)
    }

    @Test func 읽기_문구() {
        #expect(s.rowAccessibility(s.rows[0]) == "위치, 출퇴근 장소 확인 · 출퇴근 버튼을 누를 때만, 앱 사용 중")
        #expect(s.rowAccessibility(s.rows[4]) == "사진, 서류 제출 시 앨범에서 선택, 묻지 않음")
    }
}
