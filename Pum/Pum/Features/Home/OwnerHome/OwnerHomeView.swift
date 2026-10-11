// UI-IOS-1aq · REQ-105 · REQ-027 · DEC-007(1az 색) — 사장님 홈: 결정 → 현장 → 돈, 한 번에 끝나는 것만 홈에서 처리
// 색: 주황 = 처리 필요, 파랑 = 인정 · 선택 · 진행, 초록 = 확정 금액, 아바타 연한 색, 칩 · 배지 무채색
import SwiftUI

/// 이 화면 전용 크기(디자인 1az 목업 값) — 토큰에 없는 것만
private enum OwnerHomeLayout {
    /// 근무 중 행 오른쪽 작은 진행 막대
    static let miniBarWidth: CGFloat = 64
    static let miniBarHeight: CGFloat = PumTokens.Space.s6
    /// 인건비 막대 높이
    static let payBarHeight: CGFloat = PumTokens.Space.s8
}

struct OwnerHomeView: View {
    var state: OwnerHomeState = .sample
    var onDecide: (OwnerHomeState.Decision) -> Void = { _ in }
    var onClockOutCheck: (OwnerHomeState.OnDuty) -> Void = { _ in }
    var onOpenOthers: () -> Void = {}
    @State private var tab = "home"

    var body: some View {
        ScrollView {
            VStack(spacing: PumTokens.Space.s12) {
                header
                titleBlock
                decisionCard
                workingCard
                payrollCard
            }
            .padding(.horizontal, PumTokens.Size.screenPad)
            .padding(.bottom, PumTokens.Space.s24)
        }
        .background(PumColor.bgApp)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            PumTabBar(items: PumTabItem.ownerTabs(workBadge: state.workTabBadge), selection: $tab)
        }
    }

    // MARK: 상단

    private var header: some View {
        HStack {
            PumWorkplaceChip(name: state.workplaceName, initial: state.workplaceInitial,
                             tileColor: PumColor.surfaceInverse, role: "사장님") {}
            Spacer(minLength: PumTokens.Space.s8)
            PumIconButton(systemImage: "bell", label: "알림", showsDot: state.hasUnreadNotification) {}
        }
        .padding(.top, PumTokens.Space.s8)
    }

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s4) {
            Text(state.dateText).pumText(.footnote, weight: .medium).foregroundStyle(PumColor.textSecondary)
            // 목업 26px → title1(28): 24와 28이 같은 거리, 화면 제목이라 큰 쪽
            (Text("처리할 일 ").foregroundStyle(PumColor.textPrimary)
                + Text("\(state.attentionCount)").foregroundStyle(PumColor.statusAttention))
                .pumText(.title1)
                .accessibilityLabel(Text("처리할 일 \(state.attentionCount)건"))
                .accessibilityAddTraits(.isHeader)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, PumTokens.Space.s4)
        .padding(.top, PumTokens.Space.s8)
    }

    // MARK: 결정

    private var decisionCard: some View {
        PumCard {
            ForEach(state.decisions) { d in
                OwnerPersonRow(name: d.name, colorIndex: d.colorIndex, title: d.title, detail: d.detail) {
                    PumChipButton(title: d.actionTitle, kind: d.kind == .missingClockOut ? .neutral : .accent) { onDecide(d) }
                        .accessibilityLabel(Text("\(d.name) \(d.actionTitle)"))
                }
            }
            Button(action: onOpenOthers) {
                HStack(spacing: PumTokens.Space.s12) {
                    PumCountTile(count: state.otherCount)
                    VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                        Text("그 밖에 \(state.otherCount)건").pumText(.callout).foregroundStyle(PumColor.textPrimary)
                        Text(state.otherSummary).pumText(.caption).foregroundStyle(PumColor.textSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    Image(systemName: "chevron.right")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(PumColor.textDisabled)
                        .accessibilityHidden(true)
                }
                .padding(.vertical, PumTokens.Size.rowPadY)
                .padding(.horizontal, PumTokens.Size.rowPadX)
                .frame(minHeight: PumTokens.Size.tapMin)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .combine)
            .accessibilityHint(Text("목록으로 이동"))
        }
    }

    // MARK: 현장

    private var workingCard: some View {
        PumCard {
            HStack {
                Text("지금 근무 중 \(state.working.count)명").pumText(.body, weight: .bold).foregroundStyle(PumColor.textPrimary)
                Spacer(minLength: PumTokens.Space.s8)
                Text(OwnerHomeFormat.clock(state.nowMinute)).pumText(.caption, weight: .medium).foregroundStyle(PumColor.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isHeader)
            .padding(.top, PumTokens.Space.s14)
            .padding(.bottom, PumTokens.Space.s4)
            .padding(.horizontal, PumTokens.Size.rowPadX)

            ForEach(state.working) { p in
                let overdue = p.isOverdue(now: state.nowMinute)
                OwnerPersonRow(name: p.name, colorIndex: p.colorIndex, title: p.name,
                               detail: p.detail(now: state.nowMinute),
                               overdueText: overdue ? OwnerHomeFormat.overdue(minutes: p.overdueMinutes(now: state.nowMinute)) : nil) {
                    if overdue {
                        PumChipButton(title: "퇴근 확인", kind: .attention) { onClockOutCheck(p) }
                            .accessibilityLabel(Text("\(p.name) 퇴근 확인"))
                    } else {
                        MiniProgressBar(progress: p.progress(now: state.nowMinute))
                    }
                }
            }
            footer
        }
    }

    private var footer: some View {
        ViewThatFits(in: .horizontal) {
            HStack {
                Text(state.nextShiftText)
                Spacer(minLength: PumTokens.Space.s8)
                Text(state.lastClockOutText)
            }
            VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                Text(state.nextShiftText)
                Text(state.lastClockOutText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .pumText(.caption)
        .foregroundStyle(PumColor.textSecondary)
        .padding(.vertical, PumTokens.Space.s12)
        .padding(.horizontal, PumTokens.Size.rowPadX)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    // MARK: 돈

    private var payrollCard: some View {
        PumCard {
            VStack(alignment: .leading, spacing: PumTokens.Space.s10) {
                HStack {
                    Text(state.payrollTitle).pumText(.footnote, weight: .medium).foregroundStyle(PumColor.textSecondary)
                    Spacer(minLength: PumTokens.Space.s8)
                    Text("직원 \(state.staffCount)명").pumText(.caption).foregroundStyle(PumColor.textSecondary)
                }
                // 목업 22px 700 → title2(24): title3(20)보다 가깝고, 금액이 이 카드의 주인공
                Text(OwnerHomeFormat.won(state.expectedPay)).pumText(.title2).foregroundStyle(PumColor.textPrimary)
                PayrollBar(ratio: state.confirmedRatio)
                ViewThatFits(in: .horizontal) {
                    HStack {
                        confirmedText
                        Spacer(minLength: PumTokens.Space.s8)
                        remainingText
                    }
                    VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                        confirmedText
                        remainingText
                    }
                }
            }
            .padding(PumTokens.Space.s16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)
        }
    }

    private var confirmedText: some View {
        Text("확정 \(OwnerHomeFormat.won(state.confirmedPay))").pumText(.caption, weight: .semibold).foregroundStyle(PumColor.statusDone)
    }

    private var remainingText: some View {
        Text("남은 예정 \(OwnerHomeFormat.won(state.remainingPay))").pumText(.caption).foregroundStyle(PumColor.textSecondary)
    }
}

// MARK: - 화면 전용 뷰

/// 아바타 · 이름 · 둘째 줄 · 오른쪽 동작. 글자가 커지면 동작이 아래로 내려간다(동적 글자 크기).
private struct OwnerPersonRow<Trailing: View>: View {
    let name: String
    let colorIndex: Int
    let title: String
    let detail: String
    var overdueText: String?
    @ViewBuilder var trailing: Trailing

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: PumTokens.Space.s12) {
                info.frame(maxWidth: .infinity, alignment: .leading)
                trailing
            }
            VStack(alignment: .leading, spacing: PumTokens.Space.s8) {
                info
                trailing
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, PumTokens.Size.rowPadY)
        .padding(.horizontal, PumTokens.Size.rowPadX)
        .frame(minHeight: PumTokens.Size.tapMin)
        .overlay(alignment: .bottom) {
            Rectangle().fill(PumColor.borderHairline).frame(height: 1).padding(.horizontal, PumTokens.Size.rowPadX)
        }
    }

    // 이름 · 상황이 한 덩어리로 읽힌다(버튼은 따로)
    private var info: some View {
        HStack(spacing: PumTokens.Space.s12) {
            PumAvatar(name: name, colorIndex: colorIndex)
            VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                Text(title).pumText(.callout).foregroundStyle(PumColor.textPrimary)
                secondLine.pumText(.caption)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var secondLine: Text {
        let base = Text(detail).foregroundColor(PumColor.textSecondary)
        guard let overdueText else { return base }
        return base + Text(" · \(overdueText)").fontWeight(.semibold).foregroundColor(PumColor.statusAttention)
    }
}

/// 근무 중 행의 작은 진행 막대(파랑 = 근무 진행)
private struct MiniProgressBar: View {
    let progress: Double
    var body: some View {
        Capsule().fill(PumColor.surfaceFill)
            .overlay(alignment: .leading) {
                Capsule().fill(PumColor.accent).frame(width: OwnerHomeLayout.miniBarWidth * CGFloat(progress))
            }
            .frame(width: OwnerHomeLayout.miniBarWidth, height: OwnerHomeLayout.miniBarHeight)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text("예정 근무 진행"))
            .accessibilityValue(Text("\(Int((progress * 100).rounded()))%"))
    }
}

/// 인건비 막대 — 확정 부분 초록
private struct PayrollBar: View {
    let ratio: Double
    var body: some View {
        GeometryReader { geo in
            Capsule().fill(PumColor.surfaceFill)
                .overlay(alignment: .leading) {
                    Capsule().fill(PumColor.statusDone).frame(width: geo.size.width * CGFloat(ratio))
                }
        }
        .frame(height: OwnerHomeLayout.payBarHeight)
        .accessibilityHidden(true) // 금액은 아래 글자로 읽는다
    }
}

#Preview("1aq") { OwnerHomeView() }
#Preview("1aq · 큰 글자") { OwnerHomeView().dynamicTypeSize(.xxxLarge) }
