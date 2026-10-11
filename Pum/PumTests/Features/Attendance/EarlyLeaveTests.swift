// UI-IOS-1ao — 조기 퇴근: 일찍 분 수 · 45분 경계 · 버튼 문구 · 사유 없이도 기록
import Testing
@testable import Pum

struct EarlyLeaveTests {
    let s = EarlyLeaveState.sample

    @Test func 일찍_퇴근은_1시간_20분() {
        #expect(s.earlyMinutes == 80)
        #expect(s.earlyText == "1시간 20분 일찍")
        #expect(s.subtitlePrefix == "지금 20:40 · 예정 퇴근 22:00 · ")
    }

    @Test func 서버_값은_그대로_보여_준다() {
        #expect(s.plannedRange == "17:00 \u{2013} 22:00")
        #expect(s.actualRange == "16:58 \u{2013} 20:40")
        #expect(s.plannedRecognizedLine == "인정 4시간 30분")
        #expect(s.actualRecognizedLine == "인정 3시간 12분 \u{00B7} 38,400원")
    }

    @Test func 기준_45분_경계() {
        var x = s
        x.nowMinute = x.plannedEndMinute - 45
        #expect(!x.needsOwnerCheck) // 45분 = 기준 안
        x.nowMinute = x.plannedEndMinute - 46
        #expect(x.needsOwnerCheck) // 46분 = 확인 대상
        #expect(s.needsOwnerCheck)
    }

    @Test func 버튼_문구와_안내_문구() {
        #expect(s.recordTitle == "20:40 퇴근 기록")
        #expect(s.noticeLead == "실제 퇴근 20:40으로 기록돼요. 예정과 45분 넘게 차이 나서 ")
    }

    @Test func 사유_선택_미선택_모두_기록_가능() {
        #expect(s.recordedReason == .ownerSentHome)
        var x = s
        x.selected = nil
        #expect(x.recordedReason == nil)
    }

    @Test func 사유_네_가지_문구() {
        #expect(EarlyLeaveReason.allCases.map(\.title) == ["사장님이 일찍 보내주셨어요", "개인 사정", "몸이 안 좋아요", "기타"])
    }

    @Test func 자정을_넘기는_예정_퇴근() {
        var x = EarlyLeaveState.sample
        x.plannedEndMinute = 60       // 01:00
        x.nowMinute = 23 * 60 + 30    // 23:30
        #expect(x.earlyMinutes == 90)
        #expect(x.needsOwnerCheck)
    }

    @Test func 예정_퇴근을_지났으면_일찍_0() {
        var x = EarlyLeaveState.sample
        x.nowMinute = 22 * 60 + 5
        #expect(x.earlyMinutes == 0)
        #expect(!x.needsOwnerCheck)
    }

    @Test func 기준이_바뀌면_안내_조건도_바뀐다() {
        var x = EarlyLeaveState.sample   // 80분 일찍
        x.autoApproveMinutes = 90
        #expect(!x.needsOwnerCheck)
        x.autoApproveMinutes = 60
        #expect(x.needsOwnerCheck)
    }
}
