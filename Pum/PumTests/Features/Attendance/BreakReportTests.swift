// UI-IOS-19h · REQ-030 — 휴게를 못 썼을 때: 원문 값 · 선택별 미리보기 · 보낼 수 있는 조건 · 읽기 문구
import Testing
@testable import Pum

struct BreakReportTests {
    @Test func 원문_값_뒤_화면() {
        let s = BreakReportState.sample
        #expect(BreakReportState.backTitle == "근무")
        #expect(BreakReportState.badgeText == "✓ 사업장 확인")
        #expect(BreakReportState.subtitle == "출퇴근 기록")
        #expect(s.dateTitle == "10월 6일 화")
        #expect(s.rows.map(\.title) == ["출근", "퇴근", "휴게", "인정 근무"])
        #expect(s.rows.map(\.value) == ["16:58", "22:04", "30분 · 예정", "4시간 30분"])
        #expect(BreakReportState.reportTitle == "휴게 시간이 달랐어요")
        #expect(BreakReportState.reportDetail == "실제로 쉰 시간을 알려주세요")
    }

    @Test func 원문_값_시트() {
        let s = BreakReportSheetState.sample
        #expect(s.title == "휴게 시간 · 10월 6일 화")
        #expect(s.plannedText == "예정 30분")
        #expect(s.choices.map(\.title) == ["30분", "15분", "못 쉼"])
        #expect(s.initialChoiceID == "none")
        #expect(s.initialReason == "주문이 몰려서")
        #expect(BreakReportSheetState.choiceHeader == "실제로 쉰 시간")
        #expect(BreakReportSheetState.reasonHeader == "사유 · 사장님에게 보여요")
        #expect(BreakReportSheetState.changeHeader == "바뀌면")
        #expect(BreakReportSheetState.sendTitle == "사장님께 보내기")
        #expect(BreakReportSheetState.footerNotice == "사장님이 확인하면 반영돼요 · 그 전까지는 예정 휴게로 계산")
    }

    @Test func 선택별_미리보기는_서버_값() {
        let s = BreakReportSheetState.sample
        let none = s.preview("none")
        #expect(none?.recognizedChange == "4h 30m → 5h 00m")
        #expect(none?.payDetail == "기본 6,000 · 소정근로 초과 가산 3,000")
        #expect(none?.payDelta == 9_000)
        #expect(none?.payText == "+9,000원")
        #expect(s.preview("15")?.payText == "+4,500원")
        #expect(s.preview("30") == nil) // 예정과 같으면 바뀌는 것이 없다
    }

    @Test func 보낼_수_있는_조건() {
        let s = BreakReportSheetState.sample
        #expect(s.canSend(choiceID: "none"))
        #expect(s.canSend(choiceID: "15"))
        #expect(!s.canSend(choiceID: "30")) // 예정과 같은 시간
        #expect(!s.canSend(choiceID: "없는 값"))
        #expect(s.input(choiceID: "30", reason: "x") == nil)
        let i = s.input(choiceID: "none", reason: "")
        #expect(i?.choice.minutes == 0) // 사유 빈칸은 막지 않는다
        #expect(i?.reason == "")
        #expect(s.input(choiceID: "15", reason: "주문이 몰려서")?.choice.title == "15분")
    }

    @Test func 읽기_문구() {
        let st = BreakReportState.sample
        #expect(st.rows.first?.readout == "출근, 16:58")
        #expect(st.reportReadout == "휴게 시간이 달랐어요, 실제로 쉰 시간을 알려주세요")
        let s = BreakReportSheetState.sample
        let p = s.preview("none")!
        #expect(s.changeReadout(p) == "인정 근무, 4시간 30분에서 5시간으로")
        #expect(s.payReadout(p) == "예상 급여, 기본 6,000 · 소정근로 초과 가산 3,000, +9,000원")
        #expect(s.choice("none")?.title == "못 쉼")
    }
}
