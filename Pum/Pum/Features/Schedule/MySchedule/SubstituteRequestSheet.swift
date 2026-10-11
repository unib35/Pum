// UI-IOS-1j · REQ-042 — 대타 요청 시트 내용. 시트 판 · 막 · 모션은 공통 C9(`pumBottomSheet`).
import SwiftUI

struct SubstituteRequestSheet: View {
    let request: SubstituteRequest
    var onCancelRequest: () -> Void = {}

    @AccessibilityFocusState private var titleFocused: Bool

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
