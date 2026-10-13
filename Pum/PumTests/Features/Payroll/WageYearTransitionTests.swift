// UI-IOS-19a · UI-IOS-19b · REQ-082 — 연도 전환: 원문 값 · 최저 미만이면 보내기 불가 · 퇴사 예정은 대상 아님 · 읽기 문구
import Testing
@testable import Pum

struct WageYearTransitionTests {
    let s = WageYearTransitionState.sample
    let sheet = NewWageSheetState.sample

    @Test func 원문_값() {
        #expect(s.effectiveDateText == "2027년 1월 1일부터")
        #expect(s.minimumTitle == "최저임금 10,700원")
        #expect(s.increaseLine == "올해 10,320원 · 380원 인상")
        #expect(s.belowHeader == "시급이 모자란 직원 2명")
        #expect(s.thinHeader == "여유가 적은 직원 1명")
        #expect(s.marginBadge(s.thin[0]) == "100원 위")
        #expect(s.fineNames == "김하늘 · 이종민")
        #expect(s.fineWages == "11,500원 · 12,000원")
        #expect(s.footerNotice == "계약서 서명 전에도 1월 1일부터 10,700원 이상으로 계산돼요")
        #expect(sheet.minimumLine == "최저 10,700원")
        #expect(sheet.costValue == "+36,290원")
        #expect(sheet.contractValue == "2건")
        #expect(sheet.sendTitle == "계약서 2건 보내기")
    }

    @Test func 퇴사_예정은_대상_아님() {
        let e = s.excluded[0]
        #expect(s.excludedDetail(e) == "10월 31일 퇴사 · 대상 아님")
        #expect(!s.below.contains { $0.id == e.id } && !s.thin.contains { $0.id == e.id } && !s.fine.contains { $0.id == e.id })
        #expect(!sheet.rows.contains { $0.id == e.id })
    }

    @Test func 초안이_최저_이상이면_보낼_수_있다() {
        #expect(sheet.canSend(sheet.initialWages))
        let inputs = sheet.inputs(sheet.initialWages)
        #expect(inputs.map(\.wage) == [10_700, 10_700, 10_800])
    }

    @Test func 최저_미만이면_보내기_불가() {
        var draft = sheet.initialWages
        draft["yuna"] = 10_699
        #expect(!sheet.canSend(draft))
        #expect(sheet.isRowBelowMinimum(sheet.rows[0], in: draft))
        #expect(!sheet.isRowBelowMinimum(sheet.rows[1], in: draft))
        draft["yuna"] = 0 // 비움
        #expect(!sheet.canSend(draft))
        draft["yuna"] = 10_700
        #expect(sheet.canSend(draft))
    }

    @Test func 손대지_않은_행은_서버_초기값() {
        #expect(sheet.wage("sejin", in: [:]) == 10_800)
        #expect(sheet.wage("sejin", in: ["sejin": 11_000]) == 11_000)
    }

    @Test func 읽기_문구() {
        #expect(s.belowReadout(s.below[0]) == "최유나, 지금 10,320원, 미달")
        #expect(s.thinReadout(s.thin[0]) == "오세진, 지금 10,800원, 100원 위")
        #expect(s.fineReadout == "김하늘 · 이종민, 11,500원 · 12,000원")
        #expect(s.excludedReadout(s.excluded[0]) == "박서준, 10월 31일 퇴사 · 대상 아님")
        #expect(sheet.inputLabel(sheet.rows[0]) == "최유나, 지금 10,320원, 새 시급")
    }
}
