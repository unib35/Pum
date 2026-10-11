// UI-IOS-1f — 퇴근 완료: 실제 체류 · 조기/연장 · 안내 문구 · 자동 인정 기준
import Testing
@testable import Pum

struct ClockOutDoneTests {
    let r = ClockOutDoneRecord.sample

    @Test func 실제_체류는_333분_5시간_33분() {
        #expect(r.stayMinutes == 333)
        #expect(r.stayText == "5시간 33분")
    }

    @Test func 조기_출근_2분_연장_31분() {
        #expect(r.earlyMinutes == 2)
        #expect(r.overtimeMinutes == 31)
    }

    @Test func 안내_문단은_모델_값으로_만든다() {
        #expect(r.confirmNotice! == "조기 출근 2분과 연장 31분은 사업장 정책(\u{00B1}45분 자동 인정)에 따라 바로 확정됐어요. 기록이 다르다면 상세에서 수정 요청할 수 있어요.")
    }

    @Test func 자동_인정_기준_안_판정() {
        #expect(r.isWithinAutoApprove)
        var x = r
        x.actualEnd = x.plannedEnd + 45
        #expect(x.isWithinAutoApprove) // 경계 45분은 안
        x.actualEnd = x.plannedEnd + 46
        #expect(!x.isWithinAutoApprove)
    }

    @Test func 인정_근무와_기본급은_저장_값을_표시() {
        var x = r
        x.recognizedMinutes = 300
        x.basePay = 1_234
        #expect(x.recognizedText == "5시간")
        #expect(x.basePayText == "1,234원")
        #expect(r.recognizedText == "5시간 03분")
        #expect(r.basePayText == "60,600원")
    }

    @Test func 문구() {
        #expect(r.headline == "22:31 퇴근했어요")
        #expect(r.subtitle == "10월 3일 토요일 \u{00B7} 종민김밥 본점")
        #expect(r.plannedRange == "17:00 \u{2013} 22:00")
        #expect(r.actualRange == "16:58 \u{2013} 22:31")
        #expect(r.breakText == "30분")
        #expect(r.wageText == " \u{00B7} 시급 12,000원")
    }

    @Test func 기준_밖이면_확정_안내_없음() {
        var x = ClockOutDoneRecord.sample
        x.actualEnd = x.plannedEnd + 46
        #expect(x.isWithinAutoApprove == false)
        #expect(x.confirmNotice == nil)
    }

    @Test func 영분_항목은_문구에서_뺀다() {
        var x = ClockOutDoneRecord.sample
        x.actualStart = x.plannedStart // 조기 출근 0분
        #expect(x.confirmNotice?.hasPrefix("연장 31분은 사업장 정책") == true)
        x.actualEnd = x.plannedEnd     // 연장도 0분
        #expect(x.confirmNotice?.hasPrefix("오늘 기록은 사업장 정책") == true)
    }
}
