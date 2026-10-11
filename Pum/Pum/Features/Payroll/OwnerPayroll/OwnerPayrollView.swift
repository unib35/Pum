// UI-IOS-1u · REQ-107 · DEC-005 — 사장님 급여 탭: 월 정산(직원별 금액 · 미처리 경고)
// 색: 주황 = 확인 필요 · 미처리, 초록 = 확정, 빨강 = 인건비 증가. 금액은 서버 값 그대로.
import SwiftUI

/// 이 화면 전용 크기 — 토큰에 없는 것만(DEC-005)
private enum OwnerPayrollLayout {
    /// 진행 단계 원 지름(목업 약 26)
    static let stepCircle: CGFloat = 26
    /// 단계 사이 선 굵기(목업 약 2) — space-2
    static let stepLine: CGFloat = PumTokens.Space.s2
    /// 경고 숫자 원 지름(목업 약 32)
    static let warnCircle: CGFloat = 32
    /// 직원 아바타(목업 약 44)
    static let avatar: CGFloat = PumTokens.Size.tapMin
}

struct OwnerPayrollView: View {
    var record: OwnerPayrollRecord = .sample
    var onPickMonth: () -> Void = {}
    var onProcess: () -> Void = {}
    var onEmployee: (OwnerPayrollEmployee) -> Void = { _ in }
    var onConfirm: () -> Void = {}
    @Environment(\.dynamicTypeSize) private var typeSize
    @ScaledMetric(relativeTo: .caption2) private var circle = OwnerPayrollLayout.stepCircle
    @ScaledMetric(relativeTo: .callout) private var warnCircle = OwnerPayrollLayout.warnCircle

    var body: some View {
        ScrollView {
            VStack(spacing: PumTokens.Space.s16) {
                header
                stepper
                if record.showsWarning { warning }
                summaryCard
                employeeCard
            }
            .padding(.horizontal, PumTokens.Size.screenPad)
            .padding(.vertical, PumTokens.Space.s12)
        }
        .background(PumColor.bgApp)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            VStack(spacing: 0) {
                if record.showsConfirmButton {
                    PumButton(title: record.confirmTitle, kind: .primary, action: onConfirm)
                        .disabled(!record.canConfirm) // 비활성 모양은 공통 버튼 것, 이유는 문구에
                        .accessibilityLabel(Text(record.confirmAccessibilityLabel))
                        .accessibilityHint(Text(record.confirmAccessibilityHint))
                        .padding(.horizontal, PumTokens.Size.screenPad)
                        .padding(.vertical, PumTokens.Space.s8)
                }
                // 원문 1u는 탭 바 없이 확정 버튼만 하단 고정
            }
            .background(PumColor.bgApp)
        }
    }

    // MARK: 머리

    private var header: some View {
        // 큰 글자에서 월 칩이 잘리지 않게 좁으면 세로로
        let layout = typeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: PumTokens.Space.s8))
            : AnyLayout(HStackLayout(alignment: .center, spacing: PumTokens.Space.s8))
        return layout {
            Text("급여").pumText(.title1).foregroundStyle(PumColor.textPrimary) // 28px 700
                .accessibilityAddTraits(.isHeader)
            if !typeSize.isAccessibilitySize { Spacer(minLength: PumTokens.Space.s8) }
            Button(action: onPickMonth) {
                HStack(spacing: PumTokens.Space.s4) {
                    Text(record.monthTitle).pumText(.body, weight: .semibold).lineLimit(1) // 15px 600
                    Image(systemName: "chevron.down").font(.caption.weight(.semibold)).accessibilityHidden(true)
                }
                .foregroundStyle(PumColor.textPrimary)
                .padding(.horizontal, PumTokens.Space.s14)
                .frame(minHeight: PumTokens.Size.tapMin)
                .background(PumColor.surfaceCard, in: Capsule())
                .pumRing(.hairline, cornerRadius: PumTokens.Radius.pill)
                .contentShape(Capsule())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(record.monthTitle))
            .accessibilityHint(Text("월을 바꿔요"))
        }
    }

    // MARK: 진행 단계

    private var stepper: some View {
        HStack(alignment: .top, spacing: 0) {
            ForEach(OwnerPayrollStage.allCases, id: \.self) { s in
                let phase = s.phase(current: record.stage)
                VStack(spacing: PumTokens.Space.s4) {
                    HStack(spacing: 0) {
                        line(visible: s != .calculating, dark: phase != .waiting)
                        dot(phase)
                        line(visible: s != .paid, dark: phase == .done)
                    }
                    Text(s.title)
                        .pumText(.caption2, weight: phase == .waiting ? .regular : .bold) // 10px → 11
                        .foregroundStyle(phase == .current ? PumColor.statusAttention : PumColor.textTertiary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .minimumScaleFactor(0.7)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(record.stageAccessibilityText))
    }

    /// 단계 사이 선: 지나온 쪽은 진하게, 앞쪽은 연하게
    @ViewBuilder private func line(visible: Bool, dark: Bool) -> some View {
        Rectangle().fill(visible ? (dark ? PumColor.surfaceInverse : PumColor.surfaceFill) : .clear)
            .frame(height: OwnerPayrollLayout.stepLine)
            .frame(maxWidth: .infinity)
    }

    @ViewBuilder private func dot(_ phase: OwnerPayrollStage.Phase) -> some View {
        switch phase {
        case .done: // 체크리스트 규칙: 회색 원 + 먹색 체크
            Circle().fill(PumColor.surfaceFill)
                .overlay { Image(systemName: "checkmark").pumText(.caption2, weight: .bold).foregroundStyle(PumColor.textPrimary) }
                .frame(width: circle, height: circle)
        case .current:
            Circle().fill(PumColor.statusAttentionDot).frame(width: circle, height: circle) // amber400
        case .waiting:
            Circle().fill(PumColor.surfaceCard)
                .overlay { Circle().strokeBorder(PumTokens.ColorToken.gray200, lineWidth: 2) } // 원문 대기 원: 회색 테두리가 보임
                .frame(width: circle, height: circle)
        }
    }

    // MARK: 경고

    private var warning: some View {
        HStack(spacing: PumTokens.Space.s12) {
            Text("\(record.pendingCount)").pumText(.callout, weight: .bold).foregroundStyle(.white) // 15px 700 → 14
                .frame(width: warnCircle, height: warnCircle)
                .background(PumColor.statusAttentionDot, in: Circle())
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                Text(record.warningTitle).pumText(.callout, weight: .bold).foregroundStyle(PumTokens.ColorToken.amber800)
                Text(record.warningBody).pumText(.caption, weight: .regular).foregroundStyle(PumColor.statusAttention)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Button(action: onProcess) {
                HStack(spacing: PumTokens.Space.s2) {
                    Text(record.warningActionText).pumText(.footnote, weight: .bold) // 13px 700
                    Image(systemName: "chevron.right").font(.caption.weight(.bold)).accessibilityHidden(true)
                }
                .foregroundStyle(PumColor.statusAttention)
                .frame(minWidth: PumTokens.Size.tapMin, minHeight: PumTokens.Size.tapMin)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityHidden(true) // 경고 한 문장의 끝(「처리」)으로 읽는다
        }
        .padding(.leading, PumTokens.Space.s14)
        .padding(.trailing, PumTokens.Space.s8)
        .padding(.vertical, PumTokens.Space.s10)
        .background(PumColor.statusAttentionSoft, in: RoundedRectangle(cornerRadius: PumTokens.Radius.md, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(record.warningAccessibilityText))
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { onProcess() }
    }

    // MARK: 요약 카드

    private var summaryCard: some View {
        PumCard {
            VStack(alignment: .leading, spacing: PumTokens.Space.s8) {
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(record.summaryTitle).pumText(.footnote, weight: .medium)
                        Spacer(minLength: PumTokens.Space.s8)
                        Text(record.payDayLabel).pumText(.caption, weight: .regular)
                    }
                    VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                        Text(record.summaryTitle).pumText(.footnote, weight: .medium)
                        Text(record.payDayLabel).pumText(.caption, weight: .regular)
                    }
                }
                .foregroundStyle(PumColor.textSecondary)
                // 32px 700 → hero. 원문 1u는 「4,210,000원」 한 덩어리(「원」도 같은 크기)
                Text(record.totalText + "원").pumText(.hero).foregroundStyle(PumColor.textPrimary)
                    .lineLimit(1).minimumScaleFactor(0.5)
                footer
            }
            .padding(PumTokens.Space.s16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(record.summaryAccessibilityText))
        }
    }

    /// 한 줄: 좁으면 줄바꿈
    private var footer: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .firstTextBaseline, spacing: PumTokens.Space.s8) { facts }
            VStack(alignment: .leading, spacing: PumTokens.Space.s2) { facts }
        }
    }

    @ViewBuilder private var facts: some View {
        Text(record.headcountText).pumText(.caption, weight: .regular).foregroundStyle(PumColor.textSecondary)
        Text(record.totalWorkText).pumText(.caption, weight: .regular).foregroundStyle(PumColor.textSecondary)
        (Text("전월 대비 ").foregroundColor(PumColor.textSecondary)
         + Text(record.deltaText).fontWeight(.bold).foregroundColor(deltaColor))
            .pumText(.caption, weight: .regular)
    }

    /// 인건비 증가 = 빨강(원문). 감소 · 같음은 디자인 없음 → 보조색
    private var deltaColor: Color { record.deltaAmount > 0 ? PumColor.statusDanger : PumColor.textSecondary }

    // MARK: 직원 카드

    private var employeeCard: some View {
        PumCard {
            VStack(spacing: 0) {
                ForEach(Array(record.employees.enumerated()), id: \.element.id) { i, e in
                    if i > 0 { Rectangle().fill(PumTokens.ColorToken.borderHairline).frame(height: 1) }
                    row(e)
                }
            }
        }
    }

    private func row(_ e: OwnerPayrollEmployee) -> some View {
        Button { onEmployee(e) } label: {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: PumTokens.Space.s12) {
                    who(e).frame(maxWidth: .infinity, alignment: .leading)
                    trailing(e, alignment: .trailing)
                }
                VStack(alignment: .leading, spacing: PumTokens.Space.s8) {
                    who(e)
                    trailing(e, alignment: .leading)
                }
            }
            .padding(.vertical, PumTokens.Space.s12)
            .padding(.horizontal, PumTokens.Space.s16)
            .frame(maxWidth: .infinity, minHeight: PumTokens.Size.tapMin, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(e.accessibilityText))
    }

    private func who(_ e: OwnerPayrollEmployee) -> some View {
        HStack(spacing: PumTokens.Space.s12) {
            PumAvatar(name: e.name, colorIndex: e.colorIndex, size: OwnerPayrollLayout.avatar)
            VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                Text(e.name).pumText(.body, weight: .semibold).foregroundStyle(PumColor.textPrimary) // 15px 600
                Text(e.detailText).pumText(.caption, weight: .regular).foregroundStyle(PumColor.textSecondary)
            }
        }
    }

    private func trailing(_ e: OwnerPayrollEmployee, alignment: HorizontalAlignment) -> some View {
        VStack(alignment: alignment, spacing: PumTokens.Space.s2) {
            Text(e.amountText).pumText(.headline, weight: .bold).foregroundStyle(PumColor.textPrimary) // 16px 700 → 17
                .lineLimit(1).minimumScaleFactor(0.7)
            Text(e.statusText).pumText(.caption2, weight: .semibold) // 11px 600
                .foregroundStyle(e.hasPending ? PumColor.statusAttention : PumColor.statusDone)
        }
    }
}

#Preview("1u") { OwnerPayrollView() }
#Preview("1u · 미처리 없음") { OwnerPayrollView(record: .sampleClear) }
#Preview("1u · 큰 글자") { OwnerPayrollView().dynamicTypeSize(.accessibility2) }
