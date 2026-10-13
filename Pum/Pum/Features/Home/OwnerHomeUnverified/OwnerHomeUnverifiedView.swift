// UI-IOS-5a · REQ-010 · REQ-105 · DEC-007(1az 색) — 미인증 사업장 홈: 1aq와 같은 순서 · 같은 카드
// 할 일 자리에 「시작 준비」, 직원 초대만 사업장 인증 후. 체크 완료 = 회색 원 + 먹색 체크(초록 채움 금지)
// 원문과 다른 점: 사업장 칩은 먹색이 아니라 1aq와 같은 흰 칩(DEC-007). 「미인증」 배지는 칩 바로 옆에 둔다.
import SwiftUI

/// 이 화면 전용 크기 — 토큰에 없는 것만
private enum OwnerHomeUnverifiedLayout {
    /// 단계 원(원문 30)
    static let stepCircle: CGFloat = 30
}

struct OwnerHomeUnverifiedView: View {
    var state: OwnerHomeUnverifiedState = .sample
    var onSwitchWorkplace: () -> Void = {}
    var onBell: () -> Void = {}
    var onOpenStep: (String) -> Void = { _ in }
    var onCreateShifts: () -> Void = {}
    var onVerify: () -> Void = {}
    var onSaveQR: () -> Void = {}
    var onSelectTab: (String) -> Void = { _ in }
    @State private var tab = "home"

    var body: some View {
        ScrollView {
            VStack(spacing: PumTokens.Space.s14) {
                header
                titleBlock
                stepsCard
                todayCard
                payrollCard
            }
            .padding(.horizontal, PumTokens.Size.screenPad)
            .padding(.bottom, PumTokens.Space.s24)
        }
        .background(PumColor.bgApp)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            PumTabBar(items: PumTabItem.ownerTabs(), selection: $tab)
        }
        .onChange(of: tab) { _, new in onSelectTab(new) }
    }

    // MARK: 상단

    private var header: some View {
        HStack(alignment: .center) {
            // 1aq와 같은 흰 칩(DEC-007). 공통 칩이 배지를 지원하지 않아 옆에 따로 둔다.
            ViewThatFits(in: .horizontal) {
                HStack(spacing: PumTokens.Space.s8) { chip; unverifiedBadge }
                VStack(alignment: .leading, spacing: PumTokens.Space.s4) { chip; unverifiedBadge }
            }
            Spacer(minLength: PumTokens.Space.s8)
            PumIconButton(systemImage: "bell", label: "알림", showsDot: state.hasUnreadNotification, action: onBell)
        }
    }

    private var chip: some View {
        PumWorkplaceChip(name: state.workplaceName, initial: state.workplaceInitial,
                         tileColor: PumColor.surfaceInverse, role: "사장님", action: onSwitchWorkplace)
    }

    /// 원문: 10px 700 주황 글자 + 연주황 바탕
    private var unverifiedBadge: some View {
        Text("미인증")
            .pumText(.caption2, weight: .bold)
            .foregroundStyle(PumColor.statusAttention)
            .padding(.horizontal, PumTokens.Space.s6)
            .padding(.vertical, PumTokens.Space.s2)
            .background(PumColor.statusAttentionSoft, in: RoundedRectangle(cornerRadius: PumTokens.Radius.xs, style: .continuous))
            .accessibilityLabel(Text("사업장 미인증"))
    }

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
            Text(state.dateText).pumText(.footnote, weight: .medium).foregroundStyle(PumColor.textSecondary)
            // 1aq와 같이 목업 26px → title1
            Text("시작 준비").pumText(.title1).foregroundStyle(PumColor.textPrimary)
                .accessibilityAddTraits(.isHeader)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, PumTokens.Space.s4)
        .padding(.top, PumTokens.Space.s4)
    }

    // MARK: 시작 준비

    private var stepsCard: some View {
        PumCard {
            ForEach(state.steps) { step in
                StepRow(step: step, onOpen: { onOpenStep(step.id) }) {
                    if let title = step.actionTitle {
                        switch step.status {
                        case .todo:
                            PumChipButton(title: title, kind: .neutral, action: onCreateShifts)
                                .accessibilityLabel(Text("\(step.title) \(title)"))
                        case .locked:
                            PumChipButton(title: title, kind: .accent, action: onVerify)
                                .accessibilityLabel(Text("사업장 \(title)"))
                        case .done:
                            EmptyView()
                        }
                    }
                }
            }
        }
    }

    // MARK: 현장

    private var todayCard: some View {
        PumCard {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text(state.todayTitle).pumText(.body, weight: .bold).foregroundStyle(PumColor.textPrimary)
                        .accessibilityAddTraits(.isHeader)
                    Spacer(minLength: PumTokens.Space.s8)
                    Text(state.todayStaffCountText).pumText(.caption, weight: .medium).foregroundStyle(PumColor.textSecondary)
                }
                .padding(.top, PumTokens.Space.s14)
                .padding(.bottom, PumTokens.Space.s6)
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: PumTokens.Space.s12) {
                        emptyText.frame(maxWidth: .infinity, alignment: .leading)
                        saveQR
                    }
                    VStack(alignment: .leading, spacing: PumTokens.Space.s8) {
                        emptyText
                        saveQR
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.top, PumTokens.Space.s8)
                .padding(.bottom, PumTokens.Space.s14)
            }
            .padding(.horizontal, PumTokens.Space.s16)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var emptyText: some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
            Text("직원이 출근하면 여기에 보여요").pumText(.callout).foregroundStyle(PumColor.textPrimary)
            Text("출근 QR은 인증 전에도 저장해 둘 수 있어요").pumText(.caption).foregroundStyle(PumColor.textSecondary)
        }
        .accessibilityElement(children: .combine)
    }

    private var saveQR: some View {
        PumChipButton(title: "QR 저장", kind: .neutral, action: onSaveQR)
    }

    // MARK: 돈

    private var payrollCard: some View {
        PumCard {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text(state.payrollTitle).pumText(.footnote, weight: .medium).foregroundStyle(PumColor.textSecondary)
                    Spacer(minLength: PumTokens.Space.s8)
                    Text(state.staffCountText).pumText(.caption).foregroundStyle(PumColor.textSecondary)
                }
                // 값이 없다 — 계산하지 않고 「—」 (원문 22px 700 연회색 → title2)
                Text("—").pumText(.title2).foregroundStyle(PumColor.textTertiary)
                    .accessibilityLabel(Text("아직 계산 전"))
                    .padding(.top, PumTokens.Space.s4)
                Text("직원과 근로조건이 등록되면 계산돼요").pumText(.caption).foregroundStyle(PumColor.textSecondary)
                    .padding(.top, PumTokens.Space.s6)
            }
            .padding(.vertical, PumTokens.Space.s14)
            .padding(.horizontal, PumTokens.Space.s16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)
        }
    }
}

// MARK: - 화면 전용 뷰

/// 1aq와 중복 — 공통 후보: OwnerPersonRow와 같은 행 틀(왼쪽 정보 · 오른쪽 동작, 큰 글자에서는 아래로)
private struct StepRow<Trailing: View>: View {
    let step: OwnerHomeUnverifiedState.Step
    let onOpen: () -> Void
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
        .padding(.vertical, PumTokens.Space.s10) // 원문 행 높이 약 54
        .padding(.horizontal, PumTokens.Size.rowPadX)
        .frame(minHeight: PumTokens.Size.tapMin)
        .overlay(alignment: .bottom) {
            Rectangle().fill(PumColor.borderHairline).frame(height: 1).padding(.horizontal, PumTokens.Size.rowPadX)
        }
    }

    private var info: some View {
        Button(action: onOpen) {
            HStack(spacing: PumTokens.Space.s12) {
                StepCircle(status: step.status)
                VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                    Text(step.title).pumText(.callout)
                        .foregroundStyle(step.status == .done ? PumColor.textSecondary : PumColor.textPrimary)
                    Text(step.detail).pumText(.caption).foregroundStyle(PumColor.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            // 보이는 높이는 내용만큼, 누름 영역만 행 여백까지 넓힌다(행이 원문보다 높아지지 않게)
            .padding(.vertical, PumTokens.Space.s10)
            .contentShape(Rectangle())
            .padding(.vertical, -PumTokens.Space.s10)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(step.accessibilityText))
    }
}

/// 단계 원: 완료 = 회색 원 + 먹색 체크 · 미완료 = 빈 원(회색 테두리) · 잠김 = 회색 원 + 자물쇠
private struct StepCircle: View {
    let status: OwnerHomeUnverifiedState.Step.Status
    @ScaledMetric(relativeTo: .body) private var size = OwnerHomeUnverifiedLayout.stepCircle

    var body: some View {
        Circle()
            .fill(status == .todo ? PumColor.surfaceCard : PumColor.surfaceFill)
            .overlay {
                switch status {
                case .done:
                    Image(systemName: "checkmark").font(.footnote.weight(.bold)).foregroundStyle(PumColor.textPrimary)
                case .todo:
                    Circle().strokeBorder(PumTokens.ColorToken.gray300, lineWidth: 1.5)
                case .locked:
                    Image(systemName: "lock").font(.footnote.weight(.medium)).foregroundStyle(PumColor.textTertiary)
                }
            }
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}

#Preview("5a") { OwnerHomeUnverifiedView(state: .sample) }
#Preview("5a · 큰 글자") { OwnerHomeUnverifiedView(state: .sample).dynamicTypeSize(.xxxLarge) }
