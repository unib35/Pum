// UI-IOS-1aa · REQ-060 — 서명 패드 모델. 서명 그림은 화면 안 상태(점 목록)로만 들고, 「서명 완료」 때 클로저로 넘긴다.
// 본인인증 · PDF 교부 · 서버 저장은 연결 후속.
import CoreGraphics

/// 손가락이 한 번 닿았다 떨어질 때까지의 점 목록(획 하나)
nonisolated struct SignatureStroke: Equatable {
    var points: [CGPoint]

    /// 이보다 짧은 획(점 하나를 톡 찍은 것)은 서명으로 치지 않는다 — 화면 pt 길이
    static let minLength: CGFloat = 4

    /// 점 사이 거리의 합
    var length: CGFloat {
        zip(points, points.dropFirst()).reduce(0) { $0 + hypot($1.1.x - $1.0.x, $1.1.y - $1.0.y) }
    }

    var isValid: Bool { length >= Self.minLength }
}

struct SignatureDrawing: Equatable {
    private(set) var strokes: [SignatureStroke] = []
    /// 지금 그리는 중인 획
    private(set) var current: SignatureStroke?

    init(strokes: [SignatureStroke] = []) { self.strokes = strokes }

    /// 서명으로 치는 획
    var validStrokes: [SignatureStroke] { strokes.filter(\.isValid) }
    var hasSignature: Bool { !validStrokes.isEmpty }

    mutating func move(to point: CGPoint) {
        if current == nil { current = SignatureStroke(points: [point]) } else { current?.points.append(point) }
    }

    /// 손가락을 뗄 때: 너무 짧은 획은 버린다
    mutating func end() {
        if let current, current.isValid { strokes.append(current) }
        current = nil
    }

    mutating func clear() {
        strokes = []
        current = nil
    }
}

/// 화면 문구 · 가짜 예시 값(원문 그대로)
enum SignaturePadContent {
    static let backTitle = "근로계약서"
    static let contractTitle = "표준근로계약서"
    static let periodLabel = "계약 기간"
    static let period = "2026.10.05 \u{2013} 2027.04.04"
    static let wageLabel = "시급"
    static let wage = "12,000원"
    static let sheetTitle = "서명"
    static let signer = "근로자 이종민"
    static let clear = "지우기"
    static let placeholder = "여기에 서명하세요"
    static let notice = "서명 시각·기기·휴대폰 본인인증 정보가 함께 기록되고, 서명본 PDF는 사장님과 나에게 각각 교부돼요."
    static let complete = "서명 완료"
    static let padLabel = "서명 칸"
    static let padHint = "손가락으로 서명해요"
    static let padSigned = "서명됨"
}

extension SignatureDrawing {
    /// 원문 캡처의 예시 서명(대략 「Mm~」) — 칸 왼쪽 위 기준 pt
    static let sample: SignatureDrawing = {
        func curve(_ pts: [(CGFloat, CGFloat)]) -> SignatureStroke {
            SignatureStroke(points: pts.map { CGPoint(x: $0.0, y: $0.1) })
        }
        return SignatureDrawing(strokes: [
            curve([(40, 130), (52, 80), (62, 60), (72, 90), (84, 120), (96, 80), (110, 56), (118, 80), (124, 126)]), // M
            curve([(142, 122), (148, 96), (158, 88), (168, 106), (174, 124), (184, 98), (196, 90), (202, 116), (206, 124)]), // m
            curve([(214, 112), (232, 98), (250, 124), (270, 100), (290, 112)]), // ~
        ])
    }()
}
