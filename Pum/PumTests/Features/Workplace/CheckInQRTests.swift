// UI-IOS-10m · REQ-020 — 출근 QR: 이미지 생성 · 문구 · PDF 저장 한 번만
import CoreGraphics
import Foundation
import Testing
@testable import Pum

struct CheckInQRTests {
    @Test func 토큰으로_QR_이미지가_만들어진다() {
        let image = CheckInQRImage.make(token: CheckInQRState.sample.token)
        #expect(image != nil)
        if let image { #expect(image.width > 0 && image.width == image.height) }
    }

    @Test func 빈_토큰은_이미지가_없다() {
        #expect(CheckInQRImage.make(token: "") == nil)
        #expect(CheckInQRState.loading.token.isEmpty)
    }

    @Test func 샘플은_원문_값() {
        let s = CheckInQRState.sample
        #expect(s.workplaceName == "종민김밥 본점")
        #expect(s.subtitle == "출근 · 퇴근 공용 · 9월 2일 만듦")
        #expect(s.scanCountText == "오늘 6회")
        #expect(CheckInQRState.regenerateSubtitle == "지금 QR은 바로 쓸 수 없게 돼요")
    }

    @Test func QR_음성_라벨은_토큰을_읽지_않는다() {
        let s = CheckInQRState.sample
        #expect(s.qrAccessibilityLabel == "종민김밥 본점 출근 QR")
        #expect(!s.qrAccessibilityLabel.contains(s.token))
    }

    @Test func PDF_저장은_한_번만() {
        var lock = CheckInQRSaveLock()
        let first = lock.begin()
        let second = lock.begin()
        #expect(first)
        #expect(!second)
    }

    @Test func PDF_저장_실패일_때만_풀린다() {
        var lock = CheckInQRSaveLock()
        _ = lock.begin()
        lock.finish(success: true)
        #expect(!lock.isSaving) // 성공 뒤에도 풀린다
        lock.finish(success: false)
        #expect(!lock.isSaving)
    }
}
