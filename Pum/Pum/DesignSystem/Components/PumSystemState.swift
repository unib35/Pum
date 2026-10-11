// C12 System States — 그림 · 아이콘 없이 제목 한 줄 + 이유 한 줄 + 행동 하나
// M8 로딩(0.5초 넘으면) · M32 스켈레톤 → 콘텐츠 · M22 동작 줄이기면 고정 회색
import SwiftUI

struct PumStateView: View {
    let title: String
    let reason: String
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s8) {
            Text(title).pumText(.title3).foregroundStyle(PumColor.textPrimary)
            Text(reason).pumText(.footnote).foregroundStyle(PumColor.textSecondary)
            if let actionTitle, let action {
                // 디자인 C12: 작은 외곽선 버튼 하나
                PumButton(title: actionTitle, kind: .outline, size: .small, action: action)
                    .fixedSize()
                    .padding(.top, PumTokens.Space.s4)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .contain)
    }
}

/// 상태 문구 — 디자인 C12 · 6p–6s · 21n 기준
nonisolated enum PumStateCopy {
    static let empty = (title: "아직 근무기록이 없어요", reason: "첫 출근을 기록하면 여기에 쌓여요.")
    static let loadFailed = (title: "불러오지 못했어요", reason: "마지막으로 받은 화면을 보여드리고 있어요.", action: "다시 시도")
    static let offline = (title: "오프라인이에요", reason: "출퇴근은 이 기기에 저장되고 연결되면 전송돼요.")
}

/// 스켈레톤 한 줄 — 반짝임(shimmer) 없이 투명도만 .55 ↔ 1, 1.4초 왕복(M8)
struct PumSkeletonBlock: View {
    var width: CGFloat? = nil
    var height: CGFloat = 14
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var dim = false

    var body: some View {
        RoundedRectangle(cornerRadius: PumTokens.Radius.xs, style: .continuous)
            .fill(PumColor.surfaceFill)
            .frame(width: width, height: height)
            .opacity(reduceMotion ? 1 : (dim ? 0.55 : 1))
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) { dim = true }
            }
            .accessibilityHidden(true)
    }
}

/// M32: 0.5초 안에 오면 스켈레톤을 건너뛰고, 넘으면 스켈레톤 → 콘텐츠를 --dur-fast로 교차.
struct PumLoadingContainer<Content: View, Placeholder: View>: View {
    let isLoading: Bool
    @ViewBuilder let content: Content
    @ViewBuilder let placeholder: Placeholder
    @State private var showPlaceholder = false

    var body: some View {
        ZStack {
            if isLoading {
                if showPlaceholder {
                    placeholder.transition(.opacity)
                        .accessibilityElement()
                        .accessibilityLabel(Text("불러오는 중"))
                }
            } else {
                content.transition(.opacity)
            }
        }
        .animation(PumMotion.fast, value: isLoading)
        .animation(PumMotion.fast, value: showPlaceholder)
        .task(id: isLoading) {
            showPlaceholder = false
            guard isLoading else { return }
            try? await Task.sleep(for: .milliseconds(500))
            if !Task.isCancelled { showPlaceholder = true }
        }
    }
}
