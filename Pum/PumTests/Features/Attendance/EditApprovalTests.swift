// UI-IOS-1s — 수정 요청 승인: 사람 줄 · 시간 변경 · 2칸 · 이력 단계 · 승인 버튼 문구
import Testing
@testable import Pum

struct EditApprovalTests {
    let s = EditApprovalState.sample

    @Test func 사람_줄_문구() {
        #expect(s.nameInitial == "하")
        #expect(s.subtitleText == "9월 30일 수 \u{00B7} 종민김밥 본점 \u{00B7} 시급 12,000원")
        #expect(s.personAccessibilityText == "김하늘, 9월 30일 수 \u{00B7} 종민김밥 본점 \u{00B7} 시급 12,000원, 검토 중")
    }

    @Test func 시간_변경_읽기() {
        #expect(s.recordedEndText == "22:00")
        #expect(s.requestedEndText == "22:30")
        #expect(s.timeAccessibilityText == "퇴근시간, 기록됨 22:00에서 요청 22:30으로")
    }

    @Test func 승인_버튼은_요청_시각에서() {
        #expect(s.approveText == "승인 \u{00B7} 22:30으로 확정")
        var x = s
        x.requestedEnd = 22 * 60 + 45
        #expect(x.approveText == "승인 \u{00B7} 22:45으로 확정")
    }

    @Test func 두_칸_문구는_서버_값_그대로() {
        #expect(s.recognizedChange.fromText + s.recognizedChange.toText == "4시간 30분 \u{2192} 5시간")
        #expect(s.payChange.fromText + s.payChange.toText == "54,000 \u{2192} 60,000원")
        #expect(s.recognizedChange.accessibilityText == "인정 근무, 4시간 30분에서 5시간으로")
        #expect(s.payChange.accessibilityText == "기본급, 54,000원에서 60,000원으로")
    }

    @Test func 이력_단계_상태와_문구() {
        #expect(s.history.map(\.status) == [.done, .current, .pending])
        #expect(s.history[0].title == "퇴근 기록 생성 \u{00B7} 22:00")
        #expect(s.history[1].title == "직원 수정 요청 \u{00B7} 22:00 \u{2192} 22:30")
        #expect(s.history[2].title == "사업주 승인 \u{00B7} 대기 중")
        #expect(s.history[2].detail == "승인하면 근무기록이 22:30으로 확정돼요")
        #expect(s.history[0].accessibilityText == "완료, 퇴근 기록 생성 \u{00B7} 22:00, 09/30 22:01 \u{00B7} 매장 QR \u{00B7} 시스템")
        #expect(s.history[1].accessibilityText.hasPrefix("진행, "))
        #expect(s.history[2].accessibilityText.hasPrefix("대기, "))
    }
}
