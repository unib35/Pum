// UI-IOS-20e · UI-IOS-20f · REQ-007 · DEC-001 — 앱 없는 직원 상세 · 하루 고치기
import Testing
@testable import Pum

struct AppLessStaffTests {
    @Test func 원문_값() {
        let s = AppLessStaffState.sample
        #expect(s.name == "김민지")
        #expect(s.summaryText == "월 · 수 · 금 17–22 · 10,320원")
        #expect(s.sectionTitle == "10월 근무")
        #expect(AppLessStaffState.ownerInputText == "사업주 입력")
        #expect(AppLessStaffState.badgeText == "앱 없음")
        #expect(s.days.map(\.dateText) == ["10월 2일 금", "10월 5일 월", "10월 7일 수", "10월 9일 금"])
        #expect(s.days.map(\.status) == [.asPlanned, .asPlanned, .edited, .upcoming])
        #expect(s.days[0].timeText == "17:00 \u{2013} 22:00")
        #expect(s.days[2].detailText == "5시간 30분 · +1시간")
        #expect(s.days[3].detailText == "한글날 · 예정")
        #expect(s.contractText == "종이 계약서 · 사진 2장")
        #expect(AppLessStaffState.fixOtherDetail == "늦게 · 일찍 · 결근 · 추가 근무")
        #expect(AppLessStaffState.inviteDetail == "직원이 직접 출퇴근하고 지난 기록도 이어져요")
        #expect(s.day("2026-10-07")?.dateText == "10월 7일 수")
    }

    @Test func 읽기_문구() {
        let s = AppLessStaffState.sample
        #expect(s.days[2].readout == "10월 7일 수, 16:00 \u{2013} 22:00, 5시간 30분, 1시간 더, 고침")
        #expect(s.days[0].readout == "10월 2일 금, 17:00 \u{2013} 22:00, 4시간 30분, 예정대로")
        #expect(s.days[3].readout == "10월 9일 금, 17:00 \u{2013} 22:00, 한글날 · 예정")
        #expect(s.sectionReadout == "10월 근무, 사업주 입력")
        #expect(s.headerReadout == "김민지, 앱 없음, 월 · 수 · 금 17–22 · 10,320원")
        let f = DayFixState.sample
        let p = f.preview!
        #expect(f.recognizedReadout(p) == "인정 근무, 5시간 30분")
        #expect(f.deltaReadout(p) == "예정보다, 소정근로 초과 · 50% 가산, 1시간 더")
    }

    @Test func 시트_원문_값() {
        let f = DayFixState.sample
        #expect(f.dateTitle == "10월 7일 수")
        #expect(f.plannedText == "예정 17:00 \u{2013} 22:00 · 휴게 30분")
        #expect(f.initialDraft == DayFixDraft(kind: .worked, startMinutes: 960, endMinutes: 1320, breakMinutes: 30, reason: "단체 예약으로 일찍 나옴"))
        #expect(DayFixKind.allCases.map(\.title) == ["근무함", "결근", "쉬는 날"])
        #expect(DayFixState.footerNotice == "「사업주 입력」으로 남고, 초대하면 직원도 볼 수 있어요")
        #expect(f.preview?.recognizedText == "5시간 30분")
        #expect(f.preview?.deltaText == "+1시간")
    }

    @Test func 미리보기가_현재_입력과_같을_때만_보인다() {
        let f = DayFixState.sample
        let same = f.initialDraft
        #expect(f.visiblePreview(for: same) != nil)
        var edited = same
        edited.reason = "다른 사유" // 사유는 계산과 무관 — 계속 보인다
        #expect(f.visiblePreview(for: edited) != nil)
        var later = same
        later.endMinutes = 1350
        #expect(f.visiblePreview(for: later) == nil)
        var otherBreak = same
        otherBreak.breakMinutes = 60
        #expect(f.visiblePreview(for: otherBreak) == nil)
        var absent = same
        absent.kind = .absent
        #expect(f.visiblePreview(for: absent) == nil)
    }

    @Test func 결근_쉬는_날이면_시간_행_없음() {
        let f = DayFixState.sample
        var draft = f.initialDraft
        #expect(DayFixState.showsTimes(draft))
        draft.kind = .absent
        #expect(!DayFixState.showsTimes(draft))
        let input = f.input(draft)
        #expect(input.start == nil && input.end == nil && input.breakMinutes == nil)
        draft.kind = .dayOff
        #expect(!DayFixState.showsTimes(draft))
    }

    @Test func 저장_값() {
        let f = DayFixState.sample
        var draft = f.initialDraft
        let input = f.input(draft)
        #expect(input == DayFixInput(dayID: "2026-10-07", kind: .worked, start: "16:00", end: "22:00",
                                     breakMinutes: 30, reason: "단체 예약으로 일찍 나옴"))
        draft.reason = "  "
        #expect(f.input(draft).reason == "")
        draft.startMinutes = 9 * 60 + 5
        #expect(f.input(draft).start == "09:05")
    }

    @Test func 시각_글자() {
        #expect(DayFixState.minutes(from: "16:00") == 960)
        #expect(DayFixState.minutes(from: "24:00") == nil)
        #expect(DayFixState.minutes(from: "abc") == nil)
        #expect(DayFixState.clock(960) == "16:00")
        #expect(DayFixState.breakText(0) == "없음")
        #expect(DayFixState.breakText(30) == "30분")
        #expect(DayFixState.breakText(60) == "1시간")
        #expect(DayFixState.breakText(45) == "45분")
    }
}
