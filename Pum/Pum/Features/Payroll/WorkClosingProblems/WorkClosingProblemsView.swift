// UI-IOS-8b · REQ-028 · REQ-070 — 사장님 문제 기록 처리: 마감 화면에서 바로, 처리하면 아래로. 탭 바 없음.
// 색: 초록 = 확정 · 주황 = 처리 필요 · 빨강 = 퇴근 미기록. 「인정」 · 「거절」은 원문 색 그대로(REQ-051 — 수당 회피 유도 없음).
// 처리 성공 후 「처리됨」으로 내려가는 것은 서버 새 상태(state)로 다시 그리는 것이다.
import SwiftUI

struct WorkClosingProblemsView: View {
    var state: WorkClosingProblemsState = .sample
    var onBack: () -> Void = {}
    /// 「직접 입력」 · 「수정」 — 입력 화면을 연다
    var onEdit: (_ itemId: String) -> Void = { _ in }
    /// 「확인 요청」 · 「인정」 · 「거절」. 결과를 done(성공 여부)로 알린다. 연결 전 기본값은 실패(done(false)).
    var onAction: (_ itemId: String, _ action: WorkClosingProblemAction, _ done: @escaping (Bool) -> Void) -> Void = { _, _, done in done(false) }

    @State private var lock = WorkClosingRowLock()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .body) private var barHeight = PumTokens.Space.s6 // 원문 막대 높이 6
    @ScaledMetric(relativeTo: .body) private var rowAvatar = PumLayout.avatar - PumTokens.Space.s4 // 남은 행 아바타 원문 약 32pt
    @ScaledMetric(relativeTo: .body) private var smallAvatar = PumLayout.avatar - PumTokens.Space.s8 // 처리됨 행 아바타 약 28pt

    var body: some View {
        VStack(spacing: 0) {
            PumNavHeader(title: state.title, onBack: onBack) { EmptyView() }
                .padding(.horizontal, PumTokens.Size.screenPad)
            ScrollView {
                VStack(alignment: .leading, spacing: PumTokens.Space.s14) { // 원문 블록 사이 14
                    progressRow
                    if !state.remaining.isEmpty { remainingSection }
                    if !state.resolved.isEmpty { resolvedSection }
                    Text(state.footnote)
                        .pumText(.caption).foregroundStyle(PumColor.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, PumTokens.Space.s4)
                }
                .padding(.horizontal, PumTokens.Size.screenPad)
                .padding(.top, PumTokens.Space.s14) // 원문 머리 줄 아래 14
                .padding(.bottom, PumTokens.Space.s12)
            }
        }
        .background(PumColor.bgApp)
        .onChange(of: state) { lock.reset() } // 서버 새 상태로 다시 그리면 잠금 해제
    }

    // MARK: 진행 막대

    private var progressRow: some View {
        HStack(spacing: PumTokens.Space.s10) { // 원문 막대~숫자 10
            bar
            Text(state.progressText).pumText(.footnote, weight: .bold).foregroundStyle(PumColor.textPrimary)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(state.progressAccessibilityText))
    }

    private var bar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(PumColor.surfaceFill)
                Capsule().fill(PumColor.statusDone)
                    .frame(width: geo.size.width * state.progress)
                    .animation(PumMotion.respecting(reduceMotion, PumMotion.progress), value: state.progress) // M22
            }
        }
        .frame(height: barHeight)
    }

    // MARK: 남은 건

    private var remainingSection: some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s8) {
            PumSectionHeader(title: state.remainingHeader, attention: true).padding(.top, PumTokens.Space.s2) // 원문 padding 2 4 0
            PumCard {
                ForEach(Array(state.remaining.enumerated()), id: \.element.id) { i, item in
                    if i > 0 { divider }
                    problemRow(item)
                }
            }
        }
    }

    private func problemRow(_ item: WorkClosingProblemItem) -> some View {
        let locked = lock.isLocked(item.id)
        // 원문: 위 줄은 아바타 옆 이름 · 배지, 아래 줄(설명 · 버튼)은 아바타 아래까지 카드 폭 전체
        return VStack(alignment: .leading, spacing: PumTokens.Space.s10) { // 원문 두 줄 사이 10
            HStack(alignment: .center, spacing: PumTokens.Space.s10) { // 원문 아바타~이름 10
                PumAvatar(name: item.name, colorIndex: item.colorIndex, size: rowAvatar)
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .firstTextBaseline, spacing: PumTokens.Space.s8) {
                        nameDate(item)
                        Spacer(minLength: PumTokens.Space.s8)
                        problemBadge(item)
                    }
                    VStack(alignment: .leading, spacing: PumTokens.Space.s4) {
                        nameDate(item)
                        problemBadge(item)
                    }
                }
            }
            .accessibilityHidden(true) // 행 라벨이 한 번에 읽는다
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .center, spacing: PumTokens.Space.s10) {
                    detail(item)
                    Spacer(minLength: PumTokens.Space.s8)
                    buttons(item, locked: locked)
                }
                VStack(alignment: .leading, spacing: PumTokens.Space.s8) { // 큰 글자는 버튼을 설명 아래 줄로
                    detail(item)
                    buttons(item, locked: locked)
                }
            }
        }
        .padding(.horizontal, PumTokens.Size.rowPadX)
        .padding(.vertical, PumTokens.Space.s12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text(item.accessibilityText))
    }

    private func nameDate(_ item: WorkClosingProblemItem) -> some View {
        Text("\(Text(item.name).font(PumFont.font(size: PumTokens.FontToken.body.size, weight: .semibold, relativeTo: .body)).foregroundColor(PumColor.textPrimary))\(Text(" \u{00B7} \(item.dateText)").font(PumFont.font(size: PumTokens.FontToken.caption.size, weight: .regular, relativeTo: .caption)).foregroundColor(PumColor.textSecondary))") // 원문 12px 400 회색
            .fixedSize(horizontal: false, vertical: true)
    }

    private func detail(_ item: WorkClosingProblemItem) -> some View {
        Text(item.detailText).pumText(.footnote, weight: .regular).foregroundStyle(PumColor.textSecondary)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityHidden(true) // 행 라벨이 읽는다
    }

    /// 원문 배지는 11px 700(공통 PumBadge는 12px 600이라 화면 전용) — 공통 후보
    private func problemBadge(_ item: WorkClosingProblemItem) -> some View {
        let c = badgeColors(item.kind)
        return Text(item.badgeText).pumText(.caption2, weight: .bold).foregroundStyle(c.fg)
            .padding(.vertical, PumTokens.Space.s4)
            .padding(.horizontal, PumTokens.Space.s8)
            .background(c.bg, in: RoundedRectangle(cornerRadius: PumTokens.Radius.xs, style: .continuous)) // 원문 모서리 6
            .fixedSize(horizontal: false, vertical: true)
    }

    private func badgeColors(_ kind: WorkClosingProblemKind) -> (fg: Color, bg: Color) {
        switch kind {
        case .missingClockOut: (PumColor.statusDanger, PumColor.statusDangerSoft)
        case .overtime: (PumColor.statusAttention, PumColor.statusAttentionSoft)
        case .offSchedule: (PumTokens.ColorToken.gray700, PumColor.surfaceFill)
        }
    }

    private func buttons(_ item: WorkClosingProblemItem, locked: Bool) -> some View {
        HStack(spacing: PumTokens.Space.s6) { // 원문 버튼 사이 6
            ProblemPill(title: item.leadingTitle, style: .outline, locked: locked, context: item.buttonContext) {
                if let action = item.leadingAction { run(item.id, action) } else { onEdit(item.id) }
            }
            ProblemPill(title: item.trailingTitle, style: item.kind == .missingClockOut ? .dark : .accent, locked: locked, context: item.buttonContext) {
                run(item.id, item.trailingAction)
            }
        }
    }

    /// 누른 행만 한 번 — 누르는 즉시 잠그고, 실패일 때만 푼다
    private func run(_ id: String, _ action: WorkClosingProblemAction) {
        guard lock.begin(id) else { return }
        onAction(id, action) { success in lock.finish(id, success: success) }
    }

    // MARK: 처리됨

    private var resolvedSection: some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s8) {
            PumSectionHeader(title: state.resolvedHeader).padding(.top, PumTokens.Space.s2)
            PumCard {
                ForEach(Array(state.resolved.enumerated()), id: \.element.id) { i, item in
                    if i > 0 { divider }
                    resolvedRow(item)
                }
            }
        }
    }

    private func resolvedRow(_ item: WorkClosingResolvedItem) -> some View {
        HStack(spacing: PumTokens.Space.s10) { // 원문 아바타~이름 10
            PumAvatar(name: item.name, colorIndex: item.colorIndex, size: smallAvatar)
            ViewThatFits(in: .horizontal) {
                HStack(spacing: PumTokens.Space.s8) {
                    resolvedName(item)
                    Spacer(minLength: PumTokens.Space.s8)
                    resolvedResult(item)
                }
                VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                    resolvedName(item)
                    resolvedResult(item)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.horizontal, PumTokens.Size.rowPadX)
        .padding(.vertical, PumTokens.Space.s12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(item.accessibilityText))
    }

    private func resolvedName(_ item: WorkClosingResolvedItem) -> some View {
        Text(item.nameDateText).pumText(.callout, weight: .regular) // 원문 14px 400 회색
            .foregroundStyle(PumTokens.ColorToken.gray700)
            .fixedSize(horizontal: false, vertical: true)
    }
    private func resolvedResult(_ item: WorkClosingResolvedItem) -> some View {
        Text(item.resultText).pumText(.caption, weight: .semibold).foregroundStyle(PumColor.statusDone)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var divider: some View {
        Rectangle().fill(PumColor.borderHairline).frame(height: 1) // 카드 끝까지
    }
}

/// 작은 알약 버튼 — 보이는 높이 약 32pt, 누름 영역은 44pt. 공통 후보(C1 SMALL 옆 알약 변형)
private struct ProblemPill: View {
    enum Style { case outline, dark, accent }
    let title: String
    let style: Style
    let locked: Bool
    /// VoiceOver 맥락 — 「박서준 10월 28일 화요일」(버튼 목록에서도 어느 행인지 알게)
    var context: String = ""
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title).pumText(.footnote, weight: style == .outline ? .semibold : .bold)
                .foregroundStyle(style == .outline ? PumColor.textPrimary : .white)
                .lineLimit(1)
                .padding(.horizontal, PumTokens.Space.s12) // 원문 padding 7 12
                .padding(.vertical, PumTokens.Space.s8) // 원문 높이 약 31
                // 원문 모서리 10px 둥근 사각형(알약 아님) — 토큰에 10이 없어 md(12)
                .background(fill, in: RoundedRectangle(cornerRadius: PumTokens.Radius.md, style: .continuous))
                .overlay { if style == .outline { RoundedRectangle(cornerRadius: PumTokens.Radius.md, style: .continuous).strokeBorder(PumColor.textPrimary, lineWidth: PumTokens.Shadow.outline.spread) } }
                // 누름 영역: 키운 뒤 같은 만큼 음수 padding으로 되돌려 배치는 그대로
                .padding(.vertical, PumTokens.Space.s8) // 알약 약 30 + 위아래 8 → 44 이상
                .padding(.horizontal, PumTokens.Space.s4)
                .contentShape(Rectangle())
                .padding(.vertical, -PumTokens.Space.s8)
                .padding(.horizontal, -PumTokens.Space.s4)
        }
        .buttonStyle(ProblemPillPressStyle())
        .disabled(locked)
        .opacity(locked ? 0.5 : 1) // 처리 중 — 그 행의 두 버튼 모두
        .accessibilityLabel(Text(context.isEmpty ? title : "\(context) \(title)"))
        .accessibilityValue(Text(locked ? "처리 중" : ""))
    }

    private var fill: Color {
        switch style {
        case .outline: PumColor.surfaceCard
        case .dark: PumColor.surfaceInverse
        case .accent: PumColor.accent
        }
    }
}

private struct ProblemPillPressStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.97 : 1) // M1
            .animation(PumMotion.respecting(reduceMotion, PumMotion.press), value: configuration.isPressed)
    }
}

#Preview("8b") { WorkClosingProblemsView(state: .sample) }
#Preview("8b · 큰 글자") { WorkClosingProblemsView(state: .sample).dynamicTypeSize(.xxxLarge) }
#Preview("8b · 남은 0건") {
    var s = WorkClosingProblemsState.sample
    s.remaining = []; s.doneCount = 5
    return WorkClosingProblemsView(state: s)
}
