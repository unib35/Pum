// UI-IOS-1j · REQ-042 — 대타 요청 시트 내용. 시트 판 · 막 · 모션은 공통 C9(`pumBottomSheet`).
import SwiftUI

struct SubstituteRequestSheet: View {
    let request: SubstituteRequest
    var onCancelRequest: () -> Void = {}

    @AccessibilityFocusState private var titleFocused: Bool
    /// 요청 사유 라벨 칸 폭 — 원문 60 (DEC-005 화면 전용)
    @ScaledMetric(relativeTo: .footnote) private var reasonLabelWidth: CGFloat = 60

    var body: some View {
        content
            .task {
                // 시트가 열리면(M3 열림 시간 뒤) 제목에 포커스
                try? await Task.sleep(for: .seconds(PumTokens.Duration.sheet))
                titleFocused = true
            }
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s12) {
            // 원문: 「대타 요청」 · 제목은 2 간격으로 붙고, 배지는 둘 오른쪽 위. 좁거나 글자가 크면 배지를 작은 글자 줄로 올린다
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .top, spacing: PumTokens.Space.s8) {
                    VStack(alignment: .leading, spacing: PumTokens.Space.s2) { heading; titleText }
                    Spacer(minLength: PumTokens.Space.s8)
                    PumBadge(text: request.statusText, kind: .attention)
                }
                VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                    HStack(alignment: .center, spacing: PumTokens.Space.s8) {
                        heading
                        Spacer(minLength: PumTokens.Space.s8)
                        PumBadge(text: request.statusText, kind: .attention)
                    }
                    titleText
                }
            }
            applicantsCard
            // 원문: 좌우 4 · 라벨 폭 60 · 간격 12
            HStack(alignment: .firstTextBaseline, spacing: PumTokens.Space.s12) {
                Text(SubstituteRequest.reasonLabel).pumText(.footnote).foregroundStyle(PumColor.textTertiary)
                    .frame(minWidth: reasonLabelWidth, alignment: .leading)
                Text(request.reason).pumText(.footnote).foregroundStyle(PumColor.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, PumTokens.Space.s4)
            .accessibilityElement(children: .combine)
            Text(request.notice).pumText(.caption).foregroundStyle(PumColor.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, PumTokens.Space.s4)
            PumButton(title: SubstituteRequest.cancelTitle, kind: .outline, action: onCancelRequest)
        }
        .padding(.horizontal, PumTokens.Size.screenPad)
        .padding(.bottom, PumTokens.Space.s16)
    }

    private var heading: some View {
        Text(SubstituteRequest.heading).pumText(.caption, weight: .medium)
            .foregroundStyle(PumColor.textSecondary)
            .accessibilityHidden(true) // 제목 라벨이 「대타 요청, …」으로 읽는다
    }

    // 목업 22px 700 → title3(20): title2(24)와 2씩 같은 거리, 시트 안 다른 글자와 균형을 위해 작은 쪽
    private var titleText: some View {
        Text(request.title).pumText(.title3, weight: .bold)
            .foregroundStyle(PumColor.textPrimary)
            .accessibilityLabel(Text(request.titleAccessibility))
            .accessibilityAddTraits(.isHeader)
            .accessibilityFocused($titleFocused)
    }

    private var applicantsCard: some View {
        PumCard(radius: PumTokens.Radius.md) {
            VStack(alignment: .leading, spacing: PumTokens.Space.s10) { // 원문: 제목 아래 10
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
                    .accessibilityElement(children: .combine)
                }
            }
            .padding(.vertical, PumTokens.Space.s14)
            .padding(.horizontal, PumTokens.Space.s16)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

#Preview("1j 시트") {
    SubstituteRequestSheet(request: MyScheduleState.sample.substitute!)
        .frame(maxHeight: .infinity, alignment: .bottom)
        .background(PumColor.surfaceFill)
}
