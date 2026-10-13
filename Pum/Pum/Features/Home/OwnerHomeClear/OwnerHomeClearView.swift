// UI-IOS-1ar · REQ-105 · DEC-007(1az 색) — 사장님 홈 · 할 일 0건: 할 일은 한 줄로 접히고 현황판이 위로
// 색: 주황 없음(처리 필요 없음), 파랑 = 근무 진행, 초록 = 확정 금액, 아바타 연한 색, 칩 · 배지 무채색
import SwiftUI

/// 이 화면 전용 크기(디자인 1ar 목업 값) — 토큰에 없는 것만
private enum OwnerHomeClearLayout {
    /// 근무 중 행 오른쪽 작은 진행 막대
    static let miniBarWidth: CGFloat = 64
    static let miniBarHeight: CGFloat = PumTokens.Space.s6
    /// 인건비 막대 높이
    static let payBarHeight: CGFloat = PumTokens.Space.s8
    /// 접힌 할 일 줄의 완료 원(아바타와 같은 크기)
    static let doneCircle: CGFloat = PumLayout.avatar
}

struct OwnerHomeClearView: View {
    var state: OwnerHomeClearState = .sample
    var onOpenHistory: () -> Void = {}
    @State private var tab = "home"

    var body: some View {
        ScrollView {
            VStack(spacing: PumTokens.Space.s12) {
                header
                titleBlock
                foldedTaskRow
                todayCard
                payrollCard
            }
            .padding(.horizontal, PumTokens.Size.screenPad)
            .padding(.bottom, PumTokens.Space.s24)
        }
        .background(PumColor.bgApp)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            PumTabBar(items: PumTabItem.ownerTabs(workBadge: 0), selection: $tab)
        }
    }

    // MARK: 상단

    private var header: some View {
        HStack {
            PumWorkplaceChip(name: state.workplaceName, initial: state.workplaceInitial,
                             tileColor: PumColor.surfaceInverse, role: "사장님") {}
            Spacer(minLength: PumTokens.Space.s8)
            PumIconButton(systemImage: "bell", label: "알림", showsDot: false) {}
        }
    }

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s4) {
            Text(state.dateText).pumText(.footnote, weight: .medium).foregroundStyle(PumColor.textSecondary)
            // 목업 26px → title1(28): 24와 28이 같은 거리, 화면 제목이라 큰 쪽
            Text("오늘 근무").pumText(.title1).foregroundStyle(PumColor.textPrimary)
                .accessibilityAddTraits(.isHeader)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, PumTokens.Space.s4)
        .padding(.top, PumTokens.Space.s8)
    }

    // MARK: 접힌 할 일

    private var foldedTaskRow: some View {
        PumCard {
            Button(action: onOpenHistory) {
                HStack(spacing: PumTokens.Space.s12) {
                    // 완료 표시: 회색 원 + 먹색 체크(초록 채움 금지)
                    Circle().fill(PumColor.surfaceFill)
                        .overlay {
                            Image(systemName: "checkmark")
                                .pumText(.footnote, weight: .bold)
                                .foregroundStyle(PumColor.textPrimary)
                        }
                        .frame(width: OwnerHomeClearLayout.doneCircle, height: OwnerHomeClearLayout.doneCircle)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                        Text("처리할 일 없음").pumText(.callout, weight: .semibold).foregroundStyle(PumColor.textPrimary)
                        Text(state.lastHandledText).pumText(.caption).foregroundStyle(PumColor.textSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    Text("기록").pumText(.caption).foregroundStyle(PumColor.textSecondary)
                    Image(systemName: "chevron.right")
                        .pumText(.footnote, weight: .semibold)
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
            .accessibilityHint(Text("처리 기록으로 이동"))
        }
    }

    // MARK: 오늘 근무

    private var todayCard: some View {
        PumCard {
            HStack {
                Text(state.todayTitle).pumText(.body, weight: .bold).foregroundStyle(PumColor.textPrimary)
                Spacer(minLength: PumTokens.Space.s8)
                Text(state.nowSummary).pumText(.caption, weight: .medium).foregroundStyle(PumColor.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isHeader)
            .padding(.top, PumTokens.Space.s14)
            .padding(.bottom, PumTokens.Space.s4)
            .padding(.horizontal, PumTokens.Size.rowPadX)

            ForEach(state.working) { p in
                ClearPersonRow(name: p.name, colorIndex: p.colorIndex, detail: p.detail,
                               isDimmed: false, accessibilityPrefix: "근무 중") {
                    MiniProgressBar(progress: p.progress(now: state.nowMinute))
                }
            }
            ForEach(state.scheduled) { p in
                ClearPersonRow(name: p.name, colorIndex: p.colorIndex, detail: p.detail,
                               isDimmed: true, accessibilityPrefix: "출근 전",
                               showsDivider: p.id != state.scheduled.last?.id) { EmptyView() }
            }
        }
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
                // 목업 28px 700 → title1(28)
                Text(OwnerHomeFormat.won(state.expectedPay)).pumText(.title1).foregroundStyle(PumColor.textPrimary)
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

/// 아바타 · 이름 · 둘째 줄 · 오른쪽 막대(근무 중만). 예정 행은 이름 · 시간 모두 흐린 글자.
private struct ClearPersonRow<Trailing: View>: View {
    let name: String
    let colorIndex: Int
    let detail: String
    let isDimmed: Bool
    /// VoiceOver에서 근무 중 / 출근 전을 구분하는 말
    let accessibilityPrefix: String
    var showsDivider: Bool = true
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
            // 행 사이에만 구분선 — 카드 마지막 행 아래에는 없음(C5)
            if showsDivider {
                Rectangle().fill(PumColor.borderHairline).frame(height: 1).padding(.horizontal, PumTokens.Size.rowPadX)
            }
        }
    }

    private var info: some View {
        HStack(spacing: PumTokens.Space.s12) {
            PumAvatar(name: name, colorIndex: colorIndex)
            VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                Text(name).pumText(.callout)
                    .foregroundStyle(isDimmed ? PumColor.textSecondary : PumColor.textPrimary)
                Text(detail).pumText(.caption)
                    .foregroundStyle(isDimmed ? PumColor.textTertiary : PumColor.textSecondary)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("\(accessibilityPrefix), \(name), \(detail)"))
    }
}

/// 근무 중 행의 작은 진행 막대(파랑 = 근무 진행)
private struct MiniProgressBar: View {
    let progress: Double
    var body: some View {
        Capsule().fill(PumColor.surfaceFill)
            .overlay(alignment: .leading) {
                Capsule().fill(PumColor.accent).frame(width: OwnerHomeClearLayout.miniBarWidth * CGFloat(progress))
            }
            .frame(width: OwnerHomeClearLayout.miniBarWidth, height: OwnerHomeClearLayout.miniBarHeight)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text("근무 진행"))
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
        .frame(height: OwnerHomeClearLayout.payBarHeight)
        .accessibilityHidden(true)
    }
}

#Preview("1ar") { OwnerHomeClearView() }
#Preview("1ar · 큰 글자") { OwnerHomeClearView().dynamicTypeSize(.xxxLarge) }
