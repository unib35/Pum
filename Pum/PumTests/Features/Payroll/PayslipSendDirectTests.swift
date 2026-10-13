// UI-IOS-20h · REQ-007 · REQ-074 — 명세서 보내기 원문 값 · PDF 카드 · 읽기 문구 · 잠금
import Testing
@testable import Pum

struct PayslipSendDirectTests {
    let s = PayslipSendDirectState.sample

    @Test func 원문_값() {
        #expect(s.monthText == "2026년 9월분 \u{00B7} 지급일 10월 10일")
        #expect(s.title == "명세서 보내기")
        #expect(s.countText == "4명")
        #expect(s.sendTitle == "명세서 4건 보내기")
        #expect(s.recipients.map(\.initial) == ["하", "종", "서", "민"])
        #expect(s.recipients.map(\.methodText) == ["앱 알림", "앱 알림", "앱 알림", "알림톡 \u{00B7} 010-****-2048"])
        #expect(s.recipients.map(\.amountText) == ["972,345원", "1,118,610원", "917,660원", "556,360원"])
    }

    @Test func PDF_카드는_앱_없는_직원마다() {
        #expect(s.pdfRecipients.map(\.name) == ["김민지"])
        #expect(s.pdfRecipients[0].pdfTitle == "김민지 명세서 PDF")
    }

    @Test func 앱_없는_직원이_없으면_PDF_카드_없음() {
        #expect(PayslipSendDirectState.allApp.pdfRecipients.isEmpty)
    }

    @Test func 읽기_문구() {
        #expect(s.recipients[3].spokenText == "김민지, 알림톡 \u{00B7} 010-****-2048, 556,360원")
        #expect(s.recipients[0].spokenText == "김하늘, 앱 알림, 972,345원")
        #expect(s.pdfRecipients[0].pdfSpoken == "김민지 명세서 PDF 공유")
    }

    @Test func 보내기는_한_번만_성공이면_잠근_채() {
        var lock = PayslipSendDirectLock()
        let first = lock.beginSend()
        let second = lock.beginSend()
        #expect(first && !second && lock.isSending)
        lock.finishSend(success: true)
        #expect(lock.isLocked && !lock.isSending)
        let third = lock.beginSend()
        #expect(!third)
    }

    @Test func 실패하면_다시_보낼_수_있음() {
        var lock = PayslipSendDirectLock()
        _ = lock.beginSend()
        lock.finishSend(success: false)
        #expect(!lock.isLocked)
        let again = lock.beginSend()
        #expect(again)
    }
}
