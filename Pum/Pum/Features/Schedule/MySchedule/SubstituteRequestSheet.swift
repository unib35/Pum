// UI-IOS-1j · REQ-042 — 대타 요청 시트(화면 전용 뷰)
// 공통 C9 바텀시트 컴포넌트가 아직 없어 이 화면 안에 둔다 → 「공통 변경 요청」 후보.
import SwiftUI

struct SubstituteRequestSheet: View {
    let request: SubstituteRequest
    /// 홈 인디케이터 영역만큼 아래 여백(바탕은 화면 끝까지)
    var bottomInset: CGFloat = 0
    var onCancelRequest: () -> Void = {}
    /// 시트 닫기(막 누름 · VoiceOver 두 손가락 문지르기)
    var onDismiss: () -> Void = {}

    @AccessibilityFocusState private var titleFocused: Bool

    // 화면 전용 상수 — 토큰에 없는 값(DEC-005)
    private enum Local {
        /// 손잡이: 목업 약 36×5, gray300 계열
        static let handleWidth: CGFloat = 36
        static let handleHeight: CGFloat = 5
    }

    var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(PumTokens.ColorToken.gray300)
                .frame(width: Local.handleWidth, height: Local.handleHeight)
                .padding(.top, PumTokens.Space.s8)
                .padding(.bottom, PumTokens.Space.s12)
                .accessibilityHidden(true)
            // 짧으면 내용 높이만큼(원문), 받은 높이를 넘으면(큰 글자) 그 안에서 스크롤 — 높이 상한은 부모가 준다
            ViewThatFits(in: .vertical) {
                content
                ScrollView { content }.scrollBounceBehavior(.basedOnSize)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, bottomInset)
        .background(
            UnevenRoundedRectangle(topLeadingRadius: PumTokens.Radius.xl, topTrailingRadius: PumTokens.Radius.xl, style: .continuous)
                .fill(PumColor.bgApp)
                .ignoresSafeArea(.container, edges: .bottom)
        )
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isModal)
        // 모달이라 뒤의 막(「닫기」)은 VoiceOver가 닿지 않는다 — 두 손가락 문지르기로 닫는다
        .accessibilityAction(.escape, onDismiss)
        .task {
            // 시트가 열리면(M3 열림 시간 뒤) 제목에 포커스
            try? await Task.sleep(for: .seconds(PumTokens.Duration.sheet))
            titleFocused = true
        }
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s12) {
            HStack(alignment: .center, spacing: PumTokens.Space.s8) {
                Text(SubstituteRequest.heading).pumText(.caption, weight: .medium)
                    .foregroundStyle(PumColor.textSecondary)
                    .accessibilityHidden(true) // 제목 라벨이 「대타 요청, …」으로 읽는다
                Spacer(minLength: PumTokens.Space.s8)
                PumBadge(text: request.statusText, kind: .attention)
            }
            // 목업 22px 700 → title3(20): title2(24)와 2씩 같은 거리, 시트 안 다른 글자와 균형을 위해 작은 쪽
            Text(request.title).pumText(.title3, weight: .bold)
                .foregroundStyle(PumColor.textPrimary)
                .accessibilityLabel(Text(request.titleAccessibility))
                .accessibilityAddTraits(.isHeader)
                .accessibilityFocused($titleFocused)
            applicantsCard
            HStack(alignment: .firstTextBaseline, spacing: PumTokens.Space.s8) {
                Text(SubstituteRequest.reasonLabel).pumText(.footnote).foregroundStyle(PumColor.textTertiary)
                Text(request.reason).pumText(.footnote).foregroundStyle(PumColor.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .accessibilityElement(children: .combine)
            Text(request.notice).pumText(.caption).foregroundStyle(PumColor.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            PumButton(title: SubstituteRequest.cancelTitle, kind: .outline, action: onCancelRequest)
                .padding(.top, PumTokens.Space.s4)
        }
        .padding(.horizontal, PumTokens.Size.screenPad)
        .padding(.bottom, PumTokens.Space.s16)
    }

    private var applicantsCard: some View {
        PumCard {
            VStack(alignment: .leading, spacing: PumTokens.Space.s12) {
                // 목업 13px 700 → footnote bold
                Text(request.applicantsHeader).pumText(.footnote, weight: .bold)
                    .foregroundStyle(PumColor.textSecondary)
                    .accessibilityAddTraits(.isHeader)
                ForEach(Array(request.applicants.enumerated()), id: \.offset) { _, who in
                    HStack(spacing: PumTokens.Space.s12) {
                        PumAvatar(name: who.name, colorIndex: who.colorIndex)
                        VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                            // 목업 15px 600 → body(16) semibold
                            Text(who.name).pumText(.body, weight: .semibold).foregroundStyle(PumColor.textPrimary)
                            Text(who.statusLine).pumText(.caption).foregroundStyle(PumColor.textSecondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(minHeight: PumTokens.Size.tapMin)
                    .accessibilityElement(children: .combine)
                }
            }
            .padding(PumTokens.Space.s16)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

#Preview("1j 시트") {
    SubstituteRequestSheet(request: MyScheduleState.sample.substitute!)
        .frame(maxHeight: .infinity, alignment: .bottom)
        .background(PumColor.surfaceFill)
}
