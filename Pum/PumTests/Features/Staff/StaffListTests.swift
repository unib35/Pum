// UI-IOS-1ac — 요약 줄 · 상태 문구와 색 종류 · 시급 표기 · 초대 중 행 · 보건증 경고
import Testing
@testable import Pum

struct StaffListTests {
    let r = StaffRoster.sample

    @Test func 요약_줄() {
        #expect(r.headcountText == "5명" && r.headcountSuffix == " 재직")
        #expect(r.breakdownText == "계약 완료 3 \u{00B7} 서명 대기 1 \u{00B7} 초대 중 1")
        #expect(r.summaryAccessibilityText == "5명 재직, 계약 완료 3 \u{00B7} 서명 대기 1 \u{00B7} 초대 중 1")
    }

    @Test func 상태_문구와_색_종류() {
        #expect(r.members.map(\.status.title) == ["계약 완료", "계약 완료", "계약 완료", "서명 대기", "초대 중"])
        #expect(StaffContractStatus.contracted.tone == .done)
        #expect(StaffContractStatus.awaitingSignature.tone == .attention)
        #expect(StaffContractStatus.invited.tone == .neutral)
    }

    @Test func 조건_줄과_시급_표기() {
        #expect(r.members[0].conditionText == "월·수·금 17\u{2013}22")
        #expect(r.members[1].conditionText == "화·목·토 17\u{2013}22 \u{00B7} 홀 서빙")
        #expect(r.members[2].conditionText == "월–금 09\u{2013}15 \u{00B7} 주방 보조 \u{00B7} 3년차")
        #expect(r.members.compactMap(\.wageText) == ["12,000", "11,500", "13,000", "11,000"])
    }

    @Test func 초대_중_행() {
        let m = r.members[4]
        #expect(m.isInvited && m.wageText == nil && !m.showsCallButton)
        #expect(m.scheduleText == "초대 중 \u{00B7} 조건 미설정")
        #expect(PumAvatar.initial(for: m.name) == "우")
        #expect(m.setConditionAccessibilityLabel == "정우진 조건 설정")
        #expect(r.members.filter(\.isInvited).count == 1)
    }

    @Test func 보건증_경고_플래그() {
        let m = r.members[0]
        #expect(m.healthCertText == "보건증 42일 남음" && m.healthCertWarning)
        #expect(r.members[1].healthCertText == nil && !r.members[1].healthCertWarning)
        // 서버가 경고가 아니라고 하면 일수가 있어도 경고 아님(앱이 기준을 계산하지 않는다)
        var calm = m
        calm = StaffMember(id: calm.id, name: calm.name, colorIndex: calm.colorIndex, status: calm.status, daysText: calm.daysText,
                           startHour: calm.startHour, endHour: calm.endHour, note: calm.note, healthCertDaysLeft: 42,
                           healthCertWarning: false, hourlyWage: calm.hourlyWage, showsCallButton: calm.showsCallButton)
        #expect(!calm.healthCertWarning && calm.healthCertText == "보건증 42일 남음")
    }

    @Test func 전화_버튼과_음성_안내() {
        #expect(r.members.map(\.showsCallButton) == [true, false, false, false, false])
        #expect(r.members[0].callAccessibilityLabel == "이종민에게 전화")
        #expect(r.members[0].accessibilityText == "이종민, 월·수·금 17시부터 22시, 보건증 42일 남음, 확인 필요, 시급 12,000원, 계약 완료")
        #expect(r.members[3].accessibilityText == "박서준, 토·일 9시부터 15시, 홀 서빙, 시급 11,000원, 서명 대기")
        #expect(r.members[4].accessibilityText == "정우진, 초대 중, 조건 미설정")
    }
}
