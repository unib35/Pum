// UI-IOS-6r · REQ-022 · REQ-095
import Testing
@testable import Pum

struct LocationDeniedTests {
    @Test func 원문_값() {
        #expect(LocationDeniedState.heading == "위치 권한이 꺼져 있어요")
        #expect(LocationDeniedState.screenTitle == "출근 기록")
        #expect(LocationDeniedState.openSettingsTitle == "iPhone 설정으로 이동")
        #expect(LocationDeniedState.useQRTitle == "매장 QR로 출근")
        #expect(LocationDeniedState.requestManualTitle == "관리자에게 수동 기록 요청")
        #expect(LocationDeniedState.steps.map(\.title) == ["iPhone 설정 열기", "품 \u{2192} 위치", "\"앱을 사용하는 동안\" 선택"])
        #expect(LocationDeniedState.sample.message == "종민김밥 본점은 매장 반경 100m 안에서 출근하도록 설정돼 있어요. 위치를 켜거나 매장 QR로 출근할 수 있어요.")
    }

    @Test func 읽기_문구() {
        #expect(LocationDeniedState.steps[0].spoken == "1단계, iPhone 설정 열기")
        #expect(LocationDeniedState.steps[2].spoken == "3단계, \"앱을 사용하는 동안\" 선택")
    }

    @Test func 사업장_반경은_서버_값() {
        let state = LocationDeniedState(workplaceName: "한강식당", radiusMeters: 250)
        #expect(state.message.hasPrefix("한강식당은 매장 반경 250m 안에서"))
    }
}
