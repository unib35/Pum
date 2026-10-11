// UI-IOS-1x — 직원 초대: 번호 형식 · 코드 표시 · 버튼 문구 · 활성 조건 · 방법별 안내
import Testing
@testable import Pum

struct StaffInviteTests {
    @Test func 번호_하이픈() {
        #expect(StaffInviteDraft.formatPhone("01041827750") == "010-4182-7750")
        #expect(StaffInviteDraft.formatPhone("010") == "010")
        #expect(StaffInviteDraft.formatPhone("0104") == "010-4")
        #expect(StaffInviteDraft.formatPhone("0104182") == "010-4182")
        #expect(StaffInviteDraft.formatPhone("01041827") == "010-4182-7")
    }

    @Test func 번호_지우기와_초과() {
        #expect(StaffInviteDraft.formatPhone("010-4182-775") == "010-4182-775")
        #expect(StaffInviteDraft.formatPhone("010-4182-") == "010-4182")
        #expect(StaffInviteDraft.formatPhone("") == "")
        // 11자리 초과는 잘리고, 숫자 아닌 글자는 버린다
        #expect(StaffInviteDraft.formatPhone("0104182775099") == "010-4182-7750")
        #expect(StaffInviteDraft.formatPhone("abc010x4182") == "010-4182")
    }

    @Test func 코드_표시() {
        #expect(StaffInviteDraft.codeDisplay("K7X4MP") == "K7X 4MP")
        #expect(StaffInviteDraft.codeDisplay("K7X") == "K7X")
        #expect(StaffInviteDraft.sample.codeAccessibility == "초대 코드, K 7 X 4 M P")
    }

    @Test func 보내기_문구() {
        var d = StaffInviteDraft.sample
        #expect(d.sendTitle == "알림톡으로 초대 보내기")
        d.method = .sms
        #expect(d.sendTitle == "문자로 초대 보내기")
        d.method = .app
        #expect(d.sendTitle == "앱으로 초대 보내기")
    }

    @Test func 보내기_활성_조건() {
        #expect(StaffInviteDraft.sample.canSend)
        #expect(!StaffInviteDraft.empty.canSend)
        var d = StaffInviteDraft.sample
        d.name = "  "
        #expect(!d.canSend)
        d = .sample
        d.phone = "010-4182-775"
        #expect(!d.canSend)
        d.phone = ""
        #expect(!d.canSend)
    }

    @Test func 방법별_안내() {
        #expect(InviteMethod.alimtalk.guide == "알림톡이 안 가면 같은 내용을 문자로 보내요 \u{00B7} 7일 동안 \u{00B7} 이 번호로만 수락")
        #expect(InviteMethod.sms.guide == "7일 동안 \u{00B7} 이 번호로만 수락")
        #expect(InviteMethod.app.guide == InviteMethod.sms.guide)
    }

    @Test func 수락대기_문구() {
        let p = StaffInviteDraft.sample.pending[0]
        #expect(p.statusText == "한지우 \u{00B7} 수락 대기")
        #expect(p.detailText == "어제 알림톡 \u{00B7} 6일 남음")
        #expect(p.accessibilityLabel == "한지우, 수락 대기, 어제 알림톡, 6일 남음")
        #expect(p.avatarInitial == "한")
        #expect(StaffInviteDraft.sample.ownerLine == "종민김밥 본점 \u{00B7} 대표 박민수")
    }
}
