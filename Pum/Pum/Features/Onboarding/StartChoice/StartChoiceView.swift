// UI-IOS-2c · REQ-001 · REQ-005 · DEC-005 — 시작 방식(초대 없으면 개인 모드로). 탭 바 · 헤더 없음.
// 원문 캡처 비교: `StartChoiceView(state: .sample)`. 실제 진입은 선택 없음.
import SwiftUI

struct StartChoiceView: View {
    var onNext: (StartChoice) -> Void = { _ in }

    @State private var state: StartChoiceState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(state: StartChoiceState = .init(), onNext: @escaping (StartChoice) -> Void = { _ in }) {
        _state = State(initialValue: state)
        self.onNext = onNext
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: PumTokens.Space.s16) {
                header
                ForEach(StartChoice.allCases, id: \.self) { choice in
                    StartChoiceCard(choice: choice, state: state) { select(choice) }
                }
                Text("사업장은 검색해서 들어갈 수 없어요. 사장님의 초대를 받아야 소속돼요.")
                    .pumText(.caption).foregroundStyle(PumColor.textTertiary)
                    .padding(.horizontal, PumTokens.Space.s8) // 원문: 카드보다 약 8 안쪽
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, PumTokens.Size.screenPad)
            .padding(.top, PumTokens.Space.s24)
            .padding(.bottom, PumTokens.Space.s16)
        }
        .scrollBounceBehavior(.basedOnSize)
        .safeAreaInset(edge: .bottom, spacing: 0) { nextButton }
        .background(PumColor.bgApp)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s8) {
            // 26px 700 → 가까운 단계 title1(28) — title2(24)와 같은 거리라 큰 쪽(DEC-005, 2a 제목과 같은 처리)
            Text("어떻게 시작할까요?").pumText(.title1).foregroundStyle(PumColor.textPrimary)
                .accessibilityAddTraits(.isHeader)
            Text("나중에 언제든 바꾸거나 추가할 수 있어요")
                .pumText(.callout, weight: .regular).foregroundStyle(PumColor.textSecondary) // 14px 400
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, PumTokens.Space.s8)
    }

    private var nextButton: some View {
        PumButton(title: "다음", kind: .primary) {
            if let choice = state.selected { onNext(choice) }
        }
        .disabled(!state.isNextEnabled)
        .padding(.horizontal, PumTokens.Size.screenPad)
        .padding(.vertical, PumTokens.Space.s12)
        .background(PumColor.bgApp)
    }

    private func select(_ choice: StartChoice) {
        withAnimation(PumMotion.respecting(reduceMotion, PumMotion.fast)) { state.select(choice) }
    }
}

// MARK: - 선택 카드 (공통 후보: 카드형 라디오 선택 행)

/// 흰 카드 + 오른쪽 위 라디오. 선택 = 파랑 2pt 테두리, 아니면 hairline. 카드 전체가 누르는 영역.
private struct StartChoiceCard: View {
    let choice: StartChoice
    let state: StartChoiceState
    let action: () -> Void

    /// 선택 테두리 두께(목업 2) — 토큰 밖 이름 상수(DEC-005)
    private let selectedRing: CGFloat = 2
    /// 카드 안쪽 여백(목업 약 18)
    private let pad = PumTokens.Space.s18

    var body: some View {
        let on = state.isSelected(choice)
        let r = PumTokens.Radius.lg
        Button(action: action) {
            HStack(alignment: .top, spacing: PumTokens.Space.s12) {
                VStack(alignment: .leading, spacing: PumTokens.Space.s6) {
                    // 16px 700 → headline(17) 근사
                    Text(choice.title).pumText(.headline, weight: .bold).foregroundStyle(PumColor.textPrimary)
                    Text(choice.detail).pumText(.footnote).foregroundStyle(PumColor.textSecondary) // 13px 400
                        .fixedSize(horizontal: false, vertical: true)
                    if !choice.tags.isEmpty {
                        StartChoiceFlow(spacing: PumTokens.Space.s6) {
                            ForEach(choice.tags, id: \.self) { StartChoiceTag(title: $0) }
                        }
                        .padding(.top, PumTokens.Space.s6)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                PumRadioMark(isOn: on)
            }
            .padding(pad)
            .frame(maxWidth: .infinity, minHeight: PumTokens.Size.tapMin, alignment: .leading)
            .background(PumColor.surfaceCard, in: RoundedRectangle(cornerRadius: r, style: .continuous))
            .overlay {
                if on {
                    RoundedRectangle(cornerRadius: r, style: .continuous)
                        .strokeBorder(PumColor.accent, lineWidth: selectedRing)
                } else {
                    RoundedRectangle(cornerRadius: r, style: .continuous)
                        .strokeBorder(PumColor.borderHairline, lineWidth: 1)
                }
            }
            .contentShape(RoundedRectangle(cornerRadius: r, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore) // 설명 · 태그를 카드 하나로 읽는다
        .accessibilityLabel(Text(state.accessibilityLabel(for: choice)))
        .accessibilityValue(Text(state.accessibilityValue(for: choice)))
        .accessibilityAddTraits(on ? [.isButton, .isSelected] : .isButton)
    }
}

/// 기능 태그 — 11px 600 회색 글자 + 회색 바탕 알약(공통 후보)
private struct StartChoiceTag: View {
    let title: String

    var body: some View {
        Text(title).pumText(.caption2) // 11px 600
            .foregroundStyle(PumColor.textSecondary)
            .padding(.horizontal, PumTokens.Space.s10)
            .padding(.vertical, PumTokens.Space.s6)
            .background(PumColor.surfaceFill, in: RoundedRectangle(cornerRadius: PumTokens.Radius.sm, style: .continuous))
    }
}

/// 줄바꿈되는 가로 배치(큰 글자에서 태그가 넘치지 않게). 공통 후보.
private struct StartChoiceFlow: Layout {
    var spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        arrange(width: proposal.width ?? .infinity, subviews: subviews).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(width: bounds.width, subviews: subviews)
        for (i, origin) in result.origins.enumerated() {
            subviews[i].place(at: CGPoint(x: bounds.minX + origin.x, y: bounds.minY + origin.y), proposal: .unspecified)
        }
    }

    private func arrange(width: CGFloat, subviews: Subviews) -> (size: CGSize, origins: [CGPoint]) {
        var origins: [CGPoint] = []
        var x: CGFloat = 0, y: CGFloat = 0, rowH: CGFloat = 0, maxX: CGFloat = 0
        for v in subviews {
            let s = v.sizeThatFits(.unspecified)
            if x > 0, x + s.width > width { x = 0; y += rowH + spacing; rowH = 0 }
            origins.append(CGPoint(x: x, y: y))
            x += s.width + spacing
            rowH = max(rowH, s.height)
            maxX = max(maxX, x - spacing)
        }
        return (CGSize(width: maxX, height: y + rowH), origins)
    }
}

#Preview("2c") { StartChoiceView() }
#Preview("2c · 원문 캡처") { StartChoiceView(state: .sample) }
#Preview("2c · 큰 글자") { StartChoiceView(state: .sample).dynamicTypeSize(.xxxLarge) }
#Preview("2c · 접근성 큰 글자") { StartChoiceView(state: .sample).dynamicTypeSize(.accessibility3) }
