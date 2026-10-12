// UI-IOS-5d · REQ-012 — 중복 감지: 문구 조합 · 삭제 안내 조건 · 한 번만 선택
import Testing
@testable import Pum

struct DuplicateBusinessTests {
    let s = DuplicateBusinessState.sample

    @Test func 문구_조합() {
        #expect(s.introText == "123-45-67890 · 사업자 확인은 됐어요. 같은 곳이라면 새로 만들지 말고 기존 사업장에 참여하는 게 좋아요.")
        #expect(s.existingSubtitle == "대표 박민수 · 직원 5명 · 2024.03 등록")
        #expect(s.joinSubtitle == "대표 박민수님이 승인하면 관리자 권한을 받아요")
        #expect(s.initial == "종")
    }

    @Test func 삭제_안내는_직원과_기록이_없을_때만() {
        #expect(s.showsDeleteNote)
        var a = s; a.myStaffCount = 1
        #expect(!a.showsDeleteNote)
        var b = s; b.myRecordCount = 3
        #expect(!b.showsDeleteNote)
    }

    @Test func 색_번호_범위_밖도_안전() {
        var x = s; x.colorIndex = -1
        _ = x.tileColor
        x.colorIndex = 999
        _ = x.tileColor
    }

    @Test func 선택은_한_번만_실패하면_풀림() {
        var lock = DuplicateChoiceLock()
        let first = lock.begin(.requestJoin)
        let second = lock.begin(.dispute)
        #expect(first)
        #expect(!second)
        #expect(lock.isLocked)
        lock.finish(success: false)
        #expect(!lock.isLocked)
        let again = lock.begin(.newBranch)
        #expect(again)
        lock.finish(success: true)
        #expect(lock.isLocked)
    }
}
