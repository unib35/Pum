// UI-IOS-10m · REQ-020 — 출근 QR 상태. 토큰 · 사업장 이름 · 만든 날 · 스캔 횟수는 서버 값. 토큰은 로그 · print 금지.
import CoreImage
import CoreImage.CIFilterBuiltins
import Foundation

struct CheckInQRState: Equatable {
    static let screenTitle = "출근 QR"
    static let regenerateTitle = "QR 새로 만들기"
    static let regenerateSubtitle = "지금 QR은 바로 쓸 수 없게 돼요"
    static let scanLogTitle = "스캔 기록"
    static let guide = "프린트해서 매장에 붙이면 끝이에요. QR은 어느 사업장인지, 위치는 실제로 근처인지 확인해요."
    static let saveTitle = "인쇄용 PDF 저장"
    static let savingTitle = "저장하는 중"
    static let sizeHint = "A4 · A5 · 스티커 크기"

    /// 서버가 준 QR 토큰. 비어 있으면 불러오는 중으로 본다.
    var token: String
    var workplaceName: String
    /// 「9월 2일」 — 서버 값
    var createdDateText: String
    var todayScanCount: Int

    var subtitle: String { "출근 · 퇴근 공용 · \(createdDateText) 만듦" }
    var scanCountText: String { "오늘 \(todayScanCount)회" }
    var qrAccessibilityLabel: String { "\(workplaceName) 출근 QR" }
    var scanLogAccessibilityLabel: String { "\(Self.scanLogTitle), \(scanCountText)" }
    var regenerateAccessibilityLabel: String { "\(Self.regenerateTitle), \(Self.regenerateSubtitle)" }

    /// 원문(10m) 값. 토큰은 가짜.
    static let sample = CheckInQRState(token: "pum-demo-qr-0001", workplaceName: "종민김밥 본점",
                                       createdDateText: "9월 2일", todayScanCount: 6)
    /// 토큰을 아직 못 받은 상태(원문 없음 — QR 자리만 회색 칸)
    static let loading = CheckInQRState(token: "", workplaceName: "종민김밥 본점",
                                        createdDateText: "9월 2일", todayScanCount: 6)
}

/// 토큰 문자열 → QR 이미지(보정 수준 M). 빈 토큰은 nil.
enum CheckInQRImage {
    /// 한 칸을 이 배율로 키워 만든다(화면에서는 `.interpolation(.none)`으로 그대로 늘림).
    private static let moduleScale: CGFloat = 12

    static func make(token: String) -> CGImage? {
        guard !token.isEmpty else { return nil }
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(token.utf8)
        filter.correctionLevel = "M"
        guard let output = filter.outputImage else { return nil }
        let scaled = output.transformed(by: CGAffineTransform(scaleX: moduleScale, y: moduleScale))
        return CIContext().createCGImage(scaled, from: scaled.extent)
    }
}

/// PDF 저장 한 번만 — 누르는 즉시 잠그고 실패일 때만 푼다.
nonisolated struct CheckInQRSaveLock: Equatable, Sendable {
    private(set) var isSaving = false
    mutating func begin() -> Bool {
        guard !isSaving else { return false }
        isSaving = true
        return true
    }
    mutating func finish(success: Bool) { if !success { isSaving = false } }
}
