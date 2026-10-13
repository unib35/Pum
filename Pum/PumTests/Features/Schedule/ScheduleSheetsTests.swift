// UI-IOS-17c · UI-IOS-17d — 게시 확인 · 게시 후 변경 시트: 원문 값 · 인력 부족은 막지 않음 · 읽기 문구 · 17a 기본 배지
import Testing
@testable import Pum

struct ScheduleSheetsTests {
    let confirm = PublishConfirmSheetState.sample
    let change = PublishedChangeSheetState.sample

    @Test func 게시_확인_원문_글자() {
        #expect(confirm.title == "다음 주 스케줄 게시")
        #expect(confirm.summary == "10월 5일 \u{2013} 11일 \u{00B7} 직원 6명 \u{00B7} 예상 인건비 2,184,000원")
        #expect(confirm.changesTitle == "바뀐 것 3건" && confirm.checksTitle == "점검")
        #expect(confirm.changes.map(\.kind.rawValue) == ["추가", "변경", "삭제"])
        #expect(confirm.changes.map(\.title) == ["이종민 \u{00B7} 10월 7일 수", "최유나 \u{00B7} 10월 7일 수", "정다은 \u{00B7} 10월 10일 토"])
        #expect(confirm.changes.map(\.detail) == ["17:00 \u{2013} 22:00", "출근 09:00 \u{2192} 10:00", "휴무 승인"])
        #expect(confirm.checks.map(\.title) == ["승인된 휴무와 겹침 없음", "4시간 이상 근무에 휴게 포함", "주 52시간 이내", "토 17\u{2013}22 \u{00B7} 1명 부족"])
        #expect(confirm.footnote == "게시 후 바꾸면 해당 직원이 수락해야 바뀌어요")
        #expect(PublishConfirmSheetState.cancelTitle == "취소" && PublishConfirmSheetState.publishTitle == "게시")
    }

    @Test func 인력_부족이어도_게시할_수_있다() {
        #expect(confirm.hasWarning)
        #expect(confirm.checks.last?.result == .warning)
        #expect(confirm.isBlocking == false)
        #expect(confirm.canPublish)
    }

    @Test func 서버가_막거나_처리_중이면_게시_불가() {
        let blocked = PublishConfirmSheetState(
            title: confirm.title, summary: confirm.summary, changesTitle: confirm.changesTitle, changes: confirm.changes,
            checksTitle: confirm.checksTitle, checks: confirm.checks, footnote: confirm.footnote,
            isBlocking: true, isPublishing: false)
        #expect(!blocked.canPublish)
        let busy = PublishConfirmSheetState(
            title: confirm.title, summary: confirm.summary, changesTitle: confirm.changesTitle, changes: confirm.changes,
            checksTitle: confirm.checksTitle, checks: confirm.checks, footnote: confirm.footnote,
            isBlocking: false, isPublishing: true)
        #expect(!busy.canPublish)
    }

    @Test func 게시_확인_읽기_문구() {
        #expect(confirm.changes[0].accessibilityText == "추가, 이종민 \u{00B7} 10월 7일 수, 17:00 \u{2013} 22:00")
        #expect(confirm.checks[0].accessibilityText == "통과, 승인된 휴무와 겹침 없음")
        #expect(confirm.checks[3].accessibilityText == "주의, 토 17\u{2013}22 \u{00B7} 1명 부족, 게시 후 추가 근무 요청으로 채울 수 있어요")
    }

    @Test func 변경_시트_원문_글자() {
        #expect(change.title == "게시된 근무 변경" && change.badge == "게시됨")
        #expect(change.rowTitle == "김하늘 \u{00B7} 10월 7일 수" && change.note == "휴게 30분")
        #expect(change.beforeText == "17:00 \u{2013} 22:00" && change.afterText == "18:00 \u{2013} 22:00")
        #expect(change.workedLabel == "인정 근무" && change.workedText == "4h 30m \u{2192} 3h 30m")
        #expect(change.payLabel == "예상 급여" && change.payText == "\u{2212}12,000원")
        #expect(change.reasonLabel == "사유 \u{00B7} 직원에게 보여요" && change.initialReason == "저녁 단체 예약 취소")
        #expect(change.footnote == "김하늘님이 수락하면 바뀌어요 \u{00B7} 응답 전까지 기존 근무")
        #expect(PublishedChangeSheetState.beforeLabel == "기존" && PublishedChangeSheetState.afterLabel == "변경")
        #expect(PublishedChangeSheetState.sendTitle == "변경 요청 보내기")
    }

    @Test func 변경_시트_읽기_문구() {
        #expect(change.spokenTimes == "기존 17:00부터 22:00, 변경 18:00부터 22:00")
        #expect(change.spokenSummary == "인정 근무 4h 30m \u{2192} 3h 30m, 예상 급여 \u{2212}12,000원")
    }

    @Test func 시트는_서버_값이_있을_때만_열린다() {
        let base = ScheduleDraftState.sample
        #expect(base.hasSheet == false)
        #expect(ScheduleDraftState.addingShift.hasSheet)
        #expect(ScheduleDraftState.confirmingPublish.publishSheet == confirm)
        #expect(ScheduleDraftState.confirmingPublish.sheet == nil && ScheduleDraftState.confirmingPublish.changeSheet == nil)
        #expect(ScheduleDraftState.changingPublished.changeSheet == change)
        #expect(ScheduleDraftState.changingPublished.publishSheet == nil)
        // 17c는 17a 그대로 위에 열린다
        #expect(ScheduleDraftState.confirmingPublish.shifts == base.shifts)
        #expect(ScheduleDraftState.confirmingPublish.weekBadge == base.weekBadge)
    }

    @Test func 일칠에이_기본_배지는_그대로() {
        let base = ScheduleDraftState.sample
        #expect(base.weekBadge.text == "초안 \u{00B7} 직원에게 안 보임")
        #expect(base.weekBadge.text == ScheduleDraftState.draftBadge)
        #expect(base.weekBadge.kind == .waiting)
        #expect(base.showsBottomBar)
        #expect(ScheduleDraftState.addingShift.weekBadge == base.weekBadge)
    }

    @Test func 게시된_주_배지와_근무() {
        let p = ScheduleDraftState.published
        #expect(p.weekBadge.text == "게시됨 \u{00B7} 10월 3일" && p.weekBadge.kind == .done)
        #expect(p.shifts.allSatisfy { $0.badge == nil })
        #expect(p.showsBottomBar == false)
        #expect(p.weekTitle == ScheduleDraftState.sample.weekTitle)
        #expect(p.days == ScheduleDraftState.sample.days)
    }
}
