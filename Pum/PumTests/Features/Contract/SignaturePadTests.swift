// UI-IOS-1aa · REQ-060 — 서명 패드: 획 추가 · 지우기 · 완료 활성 조건 · 문구
import CoreGraphics
import Testing
@testable import Pum

struct SignaturePadTests {
    func draw(_ d: inout SignatureDrawing, _ points: [CGPoint]) {
        for p in points { d.move(to: p) }
        d.end()
    }
    let line = [CGPoint(x: 0, y: 0), CGPoint(x: 20, y: 10), CGPoint(x: 40, y: 0)]

    @Test func 빈_상태는_서명_없음() {
        #expect(!SignatureDrawing().hasSignature)
    }

    @Test func 획을_그으면_추가된다() {
        var d = SignatureDrawing()
        draw(&d, line)
        draw(&d, line)
        #expect(d.validStrokes.count == 2)
        #expect(d.hasSignature)
    }

    @Test func 점_하나는_획이_아니다() {
        var d = SignatureDrawing()
        draw(&d, [CGPoint(x: 5, y: 5)])
        #expect(d.strokes.isEmpty)
        #expect(!d.hasSignature)
        draw(&d, [CGPoint(x: 5, y: 5), CGPoint(x: 5 + SignatureStroke.minLength / 2, y: 5)])
        #expect(!d.hasSignature)
    }

    @Test func 지우기는_모두_비운다() {
        var d = SignatureDrawing.sample
        #expect(d.hasSignature)
        d.clear()
        #expect(d.strokes.isEmpty && d.current == nil)
        #expect(!d.hasSignature)
    }

    @Test func 예시_서명은_세_획() {
        #expect(SignatureDrawing.sample.validStrokes.count == 3)
    }

    @Test func 문구_원문_그대로() {
        typealias C = SignaturePadContent
        #expect(C.period == "2026.10.05 \u{2013} 2027.04.04")
        #expect(C.signer == "근로자 이종민")
        #expect(C.notice == "서명 시각·기기·휴대폰 본인인증 정보가 함께 기록되고, 서명본 PDF는 사장님과 나에게 각각 교부돼요.")
        #expect(C.placeholder == "여기에 서명하세요")
        #expect([C.clear, C.complete, C.padLabel, C.padHint, C.padSigned] == ["지우기", "서명 완료", "서명 칸", "손가락으로 서명해요", "서명됨"])
    }

    @Test func 최소_길이_경계() {
        var d = SignatureDrawing()
        d.move(to: .zero); d.move(to: CGPoint(x: SignatureStroke.minLength, y: 0)); d.end()
        #expect(d.hasSignature) // 정확히 기준 = 서명
        var e = SignatureDrawing()
        e.move(to: .zero); e.move(to: CGPoint(x: SignatureStroke.minLength - 1, y: 0)); e.end()
        #expect(!e.hasSignature)
    }

    @Test func 지운_뒤_다시_쓰기() {
        var d = SignatureDrawing.sample
        d.clear()
        #expect(!d.hasSignature)
        d.move(to: .zero); d.move(to: CGPoint(x: 40, y: 10)); d.end()
        #expect(d.hasSignature && d.validStrokes.count == 1)
    }

    @Test func 그리는_중에는_아직_서명_아님() {
        var d = SignatureDrawing()
        d.move(to: .zero); d.move(to: CGPoint(x: 40, y: 10))
        #expect(!d.hasSignature)
    }
}
