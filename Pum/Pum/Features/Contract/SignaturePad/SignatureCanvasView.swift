// UI-IOS-1aa · REQ-060 — 서명 칸: 흰 카드 · 지우기 칩 · 그리기 · 기준선 · 안내
import SwiftUI

struct SignatureCanvasView: View {
    @Binding var drawing: SignatureDrawing

    /// 화면 전용 상수 — 토큰에 없는 값(DEC-005)
    enum Local {
        /// 칸 높이 약 200. 그리기 영역이라 글자 크기와 무관하게 고정(@ScaledMetric 쓰지 않음)
        static let padHeight: CGFloat = 200
        /// 선 굵기 약 2.5–3
        static let lineWidth: CGFloat = 3
        /// 기준선 좌우 안쪽 여백 약 24 → space s24
        static let baselineInset = PumTokens.Space.s24
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Canvas { context, _ in
                let style = StrokeStyle(lineWidth: Local.lineWidth, lineCap: .round, lineJoin: .round)
                for stroke in drawing.strokes + (drawing.current.map { [$0] } ?? []) {
                    guard let first = stroke.points.first else { continue }
                    var path = Path()
                    if stroke.points.count == 1 {
                        path.move(to: first)
                        path.addLine(to: first)
                    } else {
                        path.addLines(stroke.points)
                    }
                    context.stroke(path, with: .color(PumColor.textPrimary), style: style)
                }
            }
            .contentShape(Rectangle())
            // 시트가 스크롤로 바뀌어도 그리기 드래그가 먼저 받는다
            .highPriorityGesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .local)
                    .onChanged { drawing.move(to: $0.location) }
                    .onEnded { _ in drawing.end() }
            )
            .accessibilityElement()
            .accessibilityLabel(Text(SignaturePadContent.padLabel))
            .accessibilityHint(Text(SignaturePadContent.padHint))
            .accessibilityValue(Text(drawing.hasSignature ? SignaturePadContent.padSigned : ""))
            .accessibilityAddTraits(.allowsDirectInteraction)

            // 원문은 서명이 있어도 안내가 보인다
            VStack(spacing: PumTokens.Space.s6) {
                Rectangle().fill(PumColor.borderHairline).frame(height: 1)
                Text(SignaturePadContent.placeholder).pumText(.caption).foregroundStyle(PumColor.textTertiary)
            }
            .padding(.horizontal, Local.baselineInset)
            .padding(.bottom, PumTokens.Space.s12)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        }
        .frame(height: Local.padHeight)
        .frame(maxWidth: .infinity)
        .background(PumColor.surfaceCard, in: RoundedRectangle(cornerRadius: PumTokens.Radius.lg, style: .continuous))
        .clipShape(RoundedRectangle(cornerRadius: PumTokens.Radius.lg, style: .continuous))
        .pumRing(.hairline, cornerRadius: PumTokens.Radius.lg)
        .overlay(alignment: .topTrailing) {
            clearChip
        }
    }

    /// 목업 13px 600 보조색 · 회색 바탕 캡슐. PumChipButton은 모서리 12 · 12px 700이라 모양이 달라 화면 안에서 만든다.
    private var clearChip: some View {
        Button { drawing.clear() } label: {
            Text(SignaturePadContent.clear).pumText(.footnote, weight: .semibold)
                .foregroundStyle(PumColor.textSecondary)
                .padding(.horizontal, PumTokens.Space.s12)
                .padding(.vertical, PumTokens.Space.s6)
                .background(PumColor.surfaceFill, in: Capsule())
                .frame(minWidth: PumTokens.Size.tapMin, minHeight: PumTokens.Size.tapMin) // 터치 44
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.top, PumTokens.Space.s2)
        .padding(.trailing, PumTokens.Space.s2)
    }
}
