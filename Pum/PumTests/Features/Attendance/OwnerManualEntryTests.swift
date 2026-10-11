// UI-IOS-1af — 근무기록 직접 추가: 추가 조건 · 미리보기 비움 · 200자 · 문구 · 중복 보내기 방지
import Testing
@testable import Pum

struct OwnerManualEntryTests {
    let sample = OwnerManualEntryDraft.sample

    @Test func 진입_기본값은_비어_있고_추가_못함() {
        let d = OwnerManualEntryDraft.initial
        #expect(d.employeeName == nil && d.dateText == nil)
        #expect(d.reasonChip == nil && !d.hasReasonText && d.breakOption == .none)
        #expect(d.preview == nil)
        #expect(!d.canSubmit)
    }

    @Test func 추가_활성_조건은_직원_날짜_사유() {
        var d = OwnerManualEntryDraft.initial
        d.setEmployee(name: "이종민", colorIndex: 0)
        #expect(!d.canSubmit)
        d.setDate("10월 4일 (일)")
        #expect(!d.canSubmit) // 사유 없음
        d.reasonText = "  \n "
        #expect(!d.canSubmit) // 공백만
        d.reasonText = "급한 호출"
        #expect(d.canSubmit) // 문장만
        d.reasonText = ""
        d.toggleReason(.appError)
        #expect(d.canSubmit) // 칩만
        d.toggleReason(.appError)
        #expect(!d.canSubmit)
        var e = sample
        e.employeeName = nil
        #expect(!e.canSubmit)
        e = sample
        e.dateText = nil
        #expect(!e.canSubmit)
    }

    @Test func 입력이_바뀌면_미리보기를_비운다() {
        var d = sample
        d.step(.start, by: 10); #expect(d.preview == nil)
        d = sample; d.setTime(.end, minute: 19 * 60); #expect(d.preview == nil)
        d = sample; d.setBreak(.sixty); #expect(d.preview == nil)
        d = sample; d.setDate("10월 5일 (월)"); #expect(d.preview == nil)
        d = sample; d.setEmployee(name: "김하늘", colorIndex: 1); #expect(d.preview == nil)
        d = sample; d.setBreak(.thirty); #expect(d.preview != nil) // 같은 값 다시 누름
        d = sample; d.select(.end); d.reasonText = "다른 사유"; d.toggleReason(.other)
        #expect(d.preview != nil) // 사유 · 선택 강조는 계산 입력이 아니다
    }

    @Test func 원문_문구와_서버_미리보기_값() {
        #expect(sample.previewWorkLine == "인정 근무 4시간 30분")
        #expect(sample.previewPayText == "기본급 54,000원")
        #expect(sample.previewNoteText == " \u{00B7} 예정 없는 근무")
        #expect(OwnerManualEntryDraft.title == "근무기록 추가")
        #expect(OwnerManualEntryDraft.submitTitle == "기록 추가 \u{00B7} 직원에게 알림")
        let n = OwnerManualEntryDraft.notice
        #expect(n.lead + n.strong + n.tail == "직접 추가한 기록은 \"사업주 입력\"으로 표시되고 직원에게 알림이 가요. 직원이 이의를 제기하면 수정 요청으로 이어져요.")
        #expect(OwnerManualEntryBreak.allCases.map(\.title) == ["없음", "30분", "1시간"])
        #expect(OwnerManualEntryReason.allCases.map(\.title) == ["출퇴근 기록 누락", "앱 오류", "급한 호출", "기타"])
        #expect(sample.startText == "13:00" && sample.endText == "18:00")
        #expect(sample.employeeAccessibility == "직원, 이종민")
        #expect(sample.timeAccessibility(.start) == "출근, 13:00, 선택됨")
        #expect(sample.timeAccessibility(.end) == "퇴근, 18:00")
    }

    @Test func 사유는_200자로_자른다() {
        #expect(OwnerManualEntryDraft.clampedReason(String(repeating: "가", count: 250)).count == 200)
        let s200 = String(repeating: "가", count: 200)
        #expect(OwnerManualEntryDraft.clampedReason(s200) == s200)
        #expect(OwnerManualEntryDraft.clampedReason(s200 + "나").count == 200)
        #expect(OwnerManualEntryDraft.clampedReason(String(repeating: "👨‍👩‍👧", count: 201)).count == 200)
        #expect(OwnerManualEntryDraft.clampedReason("짧음") == "짧음")
    }

    @Test func 보내기는_처리_중에_두_번_못한다() {
        var d = sample
        let first = d.beginSend()
        #expect(first)
        #expect(d.isSending)
        let second = d.beginSend()
        #expect(!second)
        d.endSend()
        let third = d.beginSend()
        #expect(third)
        var empty = OwnerManualEntryDraft.initial
        let none = empty.beginSend()
        #expect(!none && !empty.isSending)
    }

    @Test func 퇴근이_더_이르면_다음날_플래그만() {
        var d = sample
        #expect(!d.endsNextDay)
        d.setTime(.end, minute: 2 * 60)
        #expect(d.endsNextDay)
        #expect(d.endText == "02:00") // 표시는 그대로
    }
}
