// UI-IOS-9c · REQ-051 — 절감안 상세: 왜 저렴한지 · 무엇이 바뀌는지. 탭 바 없음.
// 색: 초록 = 비용 감소 · 충족 / 파랑 = 주 버튼. 반영은 직원 수락 경로 — 요청만 보낸다. 수당 회피를 유도하는 문구 · 강조 없음.
// 금액 · 차이 · 이유 · 전후 시간은 서버(엔진) 값 그대로 — 화면에서 계산하지 않는다.
import SwiftUI

struct ScheduleOptionDetailView: View {
    var state: ScheduleOptionDetailState = .sample
    var onBack: () -> Void = {}
    /// 변경 요청 보내기. 결과를 done(성공 여부)로 알린다. 연결 전 기본값은 실패(done(false)).
    var onSendRequests: (_ done: @escaping (Bool) -> Void) -> Void = { done in done(false) }

    @State private var lock = WorkClosingLock() // 같은 의미(한 번만 · 실패일 때만 풀림)라 재사용
    private var isSending: Bool { lock.isClosing }

    var body: some View {
        VStack(spacing: 0) {
            PumNavHeader(title: state.title, onBack: onBack) { EmptyView() }
                .padding(.horizontal, PumTokens.Size.screenPad)
            ScrollView {
                VStack(alignment: .leading, spacing: PumTokens.Space.s12) {
                    summaryCard
                    PumSectionHeader(title: state.reasonsTitle)
                    reasonsCard
                    PumSectionHeader(title: state.changesTitle)
                    changesCard
                }
                .padding(.horizontal, PumTokens.Size.screenPad)
                .padding(.vertical, PumTokens.Space.s12)
            }
            PumButton(title: state.sendTitle, kind: .primary, isLoading: isSending, loadingTitle: "요청을 보내는 중", action: send)
                .padding(.horizontal, PumTokens.Size.screenPad)
                .padding(.top, PumTokens.Space.s8)
                .padding(.bottom, PumTokens.Space.s12)
        }
        .background(PumColor.bgApp)
    }

    // MARK: 요약

    private var summaryCard: some View {
        PumCard {
            VStack(alignment: .leading, spacing: PumTokens.Space.s12) {
                VStack(alignment: .leading, spacing: PumTokens.Space.s4) {
                    Text(state.summaryTitle).pumText(.caption, weight: .regular).foregroundStyle(PumColor.textSecondary)
                    ViewThatFits(in: .horizontal) {
                        HStack(alignment: .firstTextBaseline, spacing: PumTokens.Space.s8) { oldAmount; newAmount }
                        VStack(alignment: .leading, spacing: PumTokens.Space.s2) { oldAmount; newAmount } // 넘치면 아래로
                    }
                    Text(state.deltaText).pumText(.footnote, weight: .bold)
                        .foregroundStyle(state.direction == .decrease ? PumColor.statusDone : PumColor.textSecondary)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text(state.summaryAccessibilityText))
                Rectangle().fill(PumColor.borderHairline).frame(height: 1)
                checkFlow
                    .accessibilityHidden(true) // 요약 라벨이 같은 내용을 읽는다
            }
            .padding(PumTokens.Space.s16)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var oldAmount: some View {
        Text(state.currentText).pumText(.body, weight: .regular) // 원문 15px 400
            .strikethrough().foregroundStyle(PumColor.textTertiary)
    }

    private var newAmount: some View {
        Text(state.newText).pumText(.title1, weight: .bold) // 원문 26px 700 → 28px 근사
            .foregroundStyle(PumColor.textPrimary)
    }

    /// 한 줄에 안 들어가면 줄바꿈 흐름. 9b 체크 표시와 같은 값(공통 후보: 초록 체크 항목)
    private var checkFlow: some View {
        PumCheckFlowLayout(spacing: PumTokens.Space.s12, lineSpacing: PumTokens.Space.s8) {
            ForEach(state.checks, id: \.title) { item in
                HStack(spacing: PumTokens.Space.s4) {
                    if item.met {
                        Image(systemName: "checkmark").font(.caption.weight(.bold)).accessibilityHidden(true)
                    }
                    Text(item.title).pumText(.footnote, weight: .semibold)
                }
                .foregroundStyle(item.met ? PumColor.statusDone : PumColor.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: 줄어든 이유

    private var reasonsCard: some View {
        PumCard {
            ForEach(Array(state.reasons.enumerated()), id: \.element.id) { index, reason in
                if index > 0 { divider }
                reasonRow(reason)
            }
        }
    }

    private func reasonRow(_ r: ScheduleSavingReason) -> some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .center, spacing: PumTokens.Space.s12) {
                reasonText(r).frame(maxWidth: .infinity, alignment: .leading)
                reasonAmount(r)
            }
            VStack(alignment: .leading, spacing: PumTokens.Space.s4) { // 넘치면 금액은 아래로
                reasonText(r)
                reasonAmount(r)
            }
        }
        .padding(.horizontal, PumTokens.Size.rowPadX)
        .padding(.vertical, PumTokens.Space.s12)
        .frame(maxWidth: .infinity, minHeight: PumTokens.Size.tapMin, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(r.accessibilityText))
    }

    private func reasonText(_ r: ScheduleSavingReason) -> some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
            Text(r.title).pumText(.callout, weight: .semibold).foregroundStyle(PumColor.textPrimary)
            Text(r.detail).pumText(.caption, weight: .regular).foregroundStyle(PumColor.textSecondary)
        }
    }

    private func reasonAmount(_ r: ScheduleSavingReason) -> some View {
        Text(r.amountText).pumText(.callout, weight: .bold)
            .foregroundStyle(r.direction == .decrease ? PumColor.statusDone : PumColor.textSecondary)
    }

    // MARK: 변경 목록

    private var changesCard: some View {
        PumCard {
            ForEach(Array(state.changes.enumerated()), id: \.element.id) { index, change in
                if index > 0 { divider }
                changeRow(change)
            }
        }
    }

    private func changeRow(_ c: ScheduleStaffChange) -> some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .center, spacing: PumTokens.Space.s12) {
                PumAvatar(name: c.name, colorIndex: c.colorIndex)
                changeText(c).frame(maxWidth: .infinity, alignment: .leading)
                changeTag(c)
            }
            HStack(alignment: .top, spacing: PumTokens.Space.s12) { // 넘치면 증감은 이름 아래로
                PumAvatar(name: c.name, colorIndex: c.colorIndex)
                VStack(alignment: .leading, spacing: PumTokens.Space.s4) {
                    changeText(c)
                    changeTag(c)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.horizontal, PumTokens.Size.rowPadX)
        .padding(.vertical, PumTokens.Space.s10)
        .frame(maxWidth: .infinity, minHeight: PumTokens.Size.tapMin, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(c.spokenText))
    }

    private func changeText(_ c: ScheduleStaffChange) -> some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
            Text(c.name).pumText(.callout, weight: .semibold).foregroundStyle(PumColor.textPrimary)
            HStack(spacing: PumTokens.Space.s4) {
                Text(c.beforeDisplay).pumText(.caption, weight: .regular)
                    .strikethrough(c.beforeText != nil).foregroundStyle(PumColor.textTertiary)
                Image(systemName: "arrow.right").font(.caption2.weight(.semibold))
                    .foregroundStyle(PumColor.textTertiary).accessibilityHidden(true)
                Text(c.afterText).pumText(.caption, weight: .bold).foregroundStyle(PumColor.textPrimary)
            }
        }
    }

    private func changeTag(_ c: ScheduleStaffChange) -> some View {
        Text(c.changeText).pumText(.caption, weight: .semibold).foregroundStyle(PumColor.textSecondary)
    }

    private var divider: some View {
        Rectangle().fill(PumColor.borderHairline).frame(height: 1) // 카드 끝까지
    }

    /// 한 번만 — 누르는 즉시 잠그고, 실패일 때만 푼다.
    /// 성공 뒤 화면 이동(이전 화면 · 요청 완료 표시)은 부르는 쪽 몫. 실패 안내 문구는 원문 없음(결정 필요).
    private func send() {
        guard lock.begin(canClose: true) else { return }
        onSendRequests { success in lock.finish(success: success) }
    }
}

/// 줄바꿈 흐름 배치(체크 항목) — 공통 후보
private struct PumCheckFlowLayout: Layout {
    var spacing: CGFloat
    var lineSpacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let size = arrange(width: proposal.width ?? .infinity, subviews: subviews).size
        // 받은 폭을 그대로 쓴다 — 더 좁게 돌려주면 배치 때 줄이 더 꺾여 마지막 줄이 잘린다
        if let w = proposal.width, w.isFinite { return CGSize(width: w, height: size.height) }
        return size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(width: bounds.width, subviews: subviews)
        for (i, origin) in result.origins.enumerated() {
            subviews[i].place(at: CGPoint(x: bounds.minX + origin.x, y: bounds.minY + origin.y), proposal: .unspecified)
        }
    }

    private func arrange(width: CGFloat, subviews: Subviews) -> (size: CGSize, origins: [CGPoint]) {
        var origins: [CGPoint] = []
        var x: CGFloat = 0, y: CGFloat = 0, lineH: CGFloat = 0, maxW: CGFloat = 0
        for v in subviews {
            let s = v.sizeThatFits(.unspecified)
            if x > 0, x + s.width > width { x = 0; y += lineH + lineSpacing; lineH = 0 }
            origins.append(CGPoint(x: x, y: y))
            x += s.width + spacing
            lineH = max(lineH, s.height)
            maxW = max(maxW, x - spacing)
        }
        return (CGSize(width: maxW, height: y + lineH), origins)
    }
}

#Preview("9c") { ScheduleOptionDetailView(state: .sample) }
#Preview("9c · 큰 글자") { ScheduleOptionDetailView(state: .sample).dynamicTypeSize(.xxxLarge) }
