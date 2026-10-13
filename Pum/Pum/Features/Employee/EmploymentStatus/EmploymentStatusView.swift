// UI-IOS-6j · REQ-063 — 재직 상태 변경(탭 바 없음). 원문은 「퇴사」 상태만 있다 — 재직 · 휴직의 내용은 원문 없음(세그먼트 선택만 바뀐다).
// 퇴사 처리는 되돌리기 어려워 처리 중 표시는 이 버튼에만 두고, 성공 뒤엔 잠근 채 둔다(isProcessing · isDone).
import SwiftUI

struct EmploymentStatusView: View {
    private let serverState: EmploymentStatusState
    @State private var draft: EmploymentStatusDraft
    var isProcessing = false
    var isDone = false
    var onBack: () -> Void
    /// 퇴사일 행 — 날짜 고르는 화면 원문 없음, 클로저만
    var onPickLeaveDate: () -> Void
    /// 확인 창 원문 없음 — 클로저만
    var onConfirmLeave: (LeaveReason) -> Void

    /// 세그먼트 칸 높이 — 원문 전체 36 = 칸 30 + 안쪽 3×2, 안쪽 2(가까운 토큰)라 칸 32(누름 영역 44)
    @ScaledMetric(relativeTo: .callout) private var segmentHeight: CGFloat = 32
    /// 아바타 — 원문 약 44
    @ScaledMetric(relativeTo: .body) private var avatarSize = PumLayout.avatar + PumTokens.Space.s8

    init(state: EmploymentStatusState = .sample,
         isProcessing: Bool = false,
         isDone: Bool = false,
         onBack: @escaping () -> Void = {},
         onPickLeaveDate: @escaping () -> Void = {},
         onConfirmLeave: @escaping (LeaveReason) -> Void = { _ in }) {
        self.serverState = state
        _draft = State(initialValue: state.initialDraft)
        self.isProcessing = isProcessing
        self.isDone = isDone
        self.onBack = onBack
        self.onPickLeaveDate = onPickLeaveDate
        self.onConfirmLeave = onConfirmLeave
    }

    private var locked: Bool { isProcessing || isDone }

    var body: some View {
        VStack(spacing: 0) {
            PumNavHeader(title: EmploymentStatusState.headerTitle, onBack: onBack)
                .padding(.horizontal, PumTokens.Size.screenPad)
            ScrollView {
                VStack(alignment: .leading, spacing: PumTokens.Space.s14) {
                    targetBlock
                    segments
                    if draft.status == .left {
                        infoCard
                        reasonSection
                        notice
                    }
                }
                .padding(.horizontal, PumTokens.Size.screenPad)
                .padding(.top, PumTokens.Space.s14) // 머리–대상 14
                .padding(.bottom, PumTokens.Space.s8)
                .allowsHitTesting(!locked) // 처리 중 · 성공 뒤엔 입력만 막고, 처리 중 모양은 버튼에만
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .background(PumColor.bgApp)
        .onChange(of: serverState) { old, new in
            if !old.hasChanges(draft) || !new.hasChanges(draft) { draft = new.initialDraft }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if draft.status == .left { bottomBar }
        }
    }

    // MARK: 대상

    private var targetBlock: some View {
        HStack(spacing: PumTokens.Space.s12) {
            PumAvatar(name: serverState.targetName, colorIndex: serverState.targetColorIndex, size: avatarSize).accessibilityHidden(true)
            VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                Text(serverState.targetName).pumText(.headline, weight: .bold).foregroundStyle(PumColor.textPrimary)
                Text(serverState.subtitle).pumText(.footnote, weight: .regular).foregroundStyle(PumColor.textSecondary)
            }
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(serverState.headerSpoken))
    }

    // MARK: 상태 세그먼트 — 공통에 없어 화면 전용(6h와 같은 값)

    private var segments: some View {
        HStack(spacing: 0) {
            ForEach(EmploymentStatus.allCases) { status in
                let selected = status == draft.status
                Button {
                    draft = serverState.choosing(draft, status: status)
                } label: {
                    Text(status.title)
                        .pumText(.footnote, weight: selected ? .semibold : .medium)
                        .foregroundStyle(selected ? PumColor.textPrimary : PumColor.textSecondary)
                        .frame(maxWidth: .infinity, minHeight: segmentHeight)
                        .background {
                            if selected {
                                RoundedRectangle(cornerRadius: PumTokens.Radius.pill, style: .continuous).fill(PumColor.surfaceCard)
                            }
                        }
                        // 보이는 칸 32, 누름 영역은 44 유지(배치 높이만 원문에 맞춤)
                        .padding(.vertical, max(0, PumTokens.Size.tapMin - segmentHeight) / 2)
                        .contentShape(Rectangle())
                        .padding(.vertical, -max(0, PumTokens.Size.tapMin - segmentHeight) / 2)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text(status.title))
                .accessibilityAddTraits(selected ? [.isButton, .isSelected] : .isButton)
            }
        }
        .padding(PumTokens.Space.s2)
        .background(PumColor.surfaceFill, in: Capsule()) // 원문 모서리 999
    }

    // MARK: 퇴사 정보

    private var infoCard: some View {
        PumCard {
            ForEach(Array(serverState.rows.enumerated()), id: \.element.id) { i, row in
                if i > 0 {
                    Rectangle().fill(PumColor.borderHairline).frame(height: 1)
                        .padding(.horizontal, PumTokens.Space.s18)
                }
                infoRow(row)
            }
        }
    }

    @ViewBuilder private func infoRow(_ row: EmploymentInfoRow) -> some View {
        let label = Text(row.label).pumText(.body, weight: .regular).foregroundStyle(PumColor.textSecondary)
        let value = Text(row.value).pumText(.body, weight: .semibold).foregroundStyle(PumColor.textPrimary)
        let content = ViewThatFits(in: .horizontal) {
            HStack(spacing: PumTokens.Space.s12) {
                label
                Spacer(minLength: 0)
                value.fixedSize()
            }
            VStack(alignment: .leading, spacing: PumTokens.Space.s4) { // 넘치면 값은 라벨 아래로
                label
                value.multilineTextAlignment(.leading)
            }
        }
        .padding(.vertical, PumTokens.Space.s14)
        .padding(.horizontal, PumTokens.Space.s18)
        .frame(maxWidth: .infinity, minHeight: PumTokens.Size.tapMin, alignment: .leading)

        if row.id == EmploymentStatusState.leaveDateRowID {
            Button(action: onPickLeaveDate) { content.contentShape(Rectangle()) }
                .buttonStyle(.plain)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text(row.spoken))
                .accessibilityAddTraits(.isButton)
        } else {
            content
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text(row.spoken))
        }
    }

    // MARK: 사유

    private var reasonSection: some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s8) { // 제목–칩 14-6
            Text(EmploymentStatusState.reasonHeader).pumText(.caption, weight: .bold).foregroundStyle(PumColor.textSecondary)
                .padding(.horizontal, PumTokens.Space.s4)
                .accessibilityAddTraits(.isHeader)
            ReasonFlowLayout(spacing: PumTokens.Space.s6) {
                ForEach(Array(LeaveReason.allCases.enumerated()), id: \.element.id) { i, reason in
                    PumChoicePill(title: reason.title, isOn: draft.reason == reason, offStyle: .outlined,
                                  position: (i, LeaveReason.allCases.count)) {
                        draft = serverState.choosing(draft, reason: reason)
                    }
                }
            }
        }
        .padding(.top, PumTokens.Space.s2)
    }

    // MARK: 안내

    private var notice: some View {
        Text("\(serverState.noticeBefore)\(Text(EmploymentStatusState.noticeEmphasis).bold())\(serverState.noticeAfter)")
            .pumText(.caption, weight: .regular)
            .foregroundStyle(PumTokens.ColorToken.gray700)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.vertical, PumTokens.Space.s12)
            .padding(.horizontal, PumTokens.Space.s16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(PumColor.surfaceFill, in: RoundedRectangle(cornerRadius: PumTokens.Radius.md, style: .continuous))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(serverState.noticeSpoken))
    }

    // MARK: 하단

    private var bottomBar: some View {
        // 원문 먹색 버튼(되돌리기 어려운 처리)
        PumButton(title: serverState.confirmTitle, kind: .dark, isLoading: isProcessing) {
            onConfirmLeave(draft.reason)
        }
        .disabled(isDone)
        .padding(.horizontal, PumTokens.Size.screenPad)
        .padding(.top, PumTokens.Space.s12)
        .padding(.bottom, PumTokens.Space.s10)
        .background(PumColor.bgApp)
    }
}

/// 칩이 한 줄에 안 들어가면 다음 줄로 넘기는 배치
private struct ReasonFlowLayout: Layout {
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
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowH: CGFloat = 0
        var maxW: CGFloat = 0
        for sub in subviews {
            let s = sub.sizeThatFits(.unspecified)
            if x > 0 && x + s.width > width { x = 0; y += rowH + spacing; rowH = 0 }
            origins.append(CGPoint(x: x, y: y))
            x += s.width + spacing
            rowH = max(rowH, s.height)
            maxW = max(maxW, x - spacing)
        }
        return (CGSize(width: maxW, height: y + rowH), origins)
    }
}

#Preview("6j") { EmploymentStatusView() }
#Preview("6j · 큰 글자") { EmploymentStatusView().dynamicTypeSize(.xxxLarge) }
