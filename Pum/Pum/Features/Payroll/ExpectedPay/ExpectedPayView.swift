// UI-IOS-1l · REQ-107 · REQ-071 · DEC-005 — 확정 · 예상 급여: 구성 막대 + 계산 과정 펼침
// 금액 · 계산 근거는 서버 값을 그대로 보여 준다. 초록 = 확정 금액, 빨강 = 공제, 예정은 흐리게.
import SwiftUI

struct ExpectedPayView: View {
    var record: ExpectedPayRecord = .sample
    var onWorkplace: () -> Void = {}
    var onItem: (ExpectedPayItem) -> Void = { _ in }

    @State private var tab = "pay"
    @State private var disclosure = ExpectedPayDisclosure()
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ScrollView {
            VStack(spacing: PumTokens.Space.s14) {
                header
                summaryCard
                confirmedCard
                itemsCard
            }
            .padding(.horizontal, PumTokens.Size.screenPad)
            .padding(.bottom, PumTokens.Space.s12) // 위 여백 없음 — 머리 줄은 안전 영역 바로 아래(원문)
        }
        .background(PumColor.bgApp)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            PumTabBar(items: PumTabItem.employeeTabs, selection: $tab)
        }
    }

    // MARK: 머리

    private var header: some View {
        HStack(alignment: .center, spacing: PumTokens.Space.s8) {
            // 목업 28px 700 = title1
            Text("급여").pumText(.title1).foregroundStyle(PumColor.textPrimary)
                .accessibilityAddTraits(.isHeader)
            Spacer(minLength: PumTokens.Space.s8)
            PumWorkplaceChip(name: record.workplaceName, initial: record.workplaceInitial, action: onWorkplace)
        }
    }

    // MARK: 먹색 요약 카드

    private var summaryCard: some View {
        // 원문: 머리 줄 → 금액 6 · 금액 → 막대 18 · 막대 → 범례 12 · 패딩 20 20 18
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                Text(record.titleText).pumText(.footnote, weight: .medium)
                    .foregroundStyle(PumColor.textOnInverseSecondary)
                Spacer(minLength: PumTokens.Space.s8)
                Text(record.payDateText).pumText(.caption, weight: .regular)
                    .foregroundStyle(PumColor.textOnInverseSecondary)
            }
            // 목업 실측 약 42px 700 → hero 32(52보다 가까운 토큰 단계, DEC-005), 「원」 20px 600 → title3
            HStack(alignment: .firstTextBaseline, spacing: PumTokens.Space.s2) {
                Text(record.totalText).pumText(.hero).foregroundStyle(.white)
                    .lineLimit(1).minimumScaleFactor(0.5)
                Text("원").pumText(.title3, weight: .semibold).foregroundStyle(.white)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text("\(record.totalText)원"))
            .padding(.top, PumTokens.Space.s6)
            ExpectedPayBar(record: record)
                .padding(.top, PumTokens.Space.s18)
            ExpectedPayLegend(record: record)
                .padding(.top, PumTokens.Space.s12)
        }
        .padding(.top, PumTokens.Space.s20)
        .padding(.horizontal, PumTokens.Space.s20)
        .padding(.bottom, PumTokens.Space.s18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(PumColor.surfaceInverse, in: RoundedRectangle(cornerRadius: PumTokens.Radius.xl, style: .continuous))
    }

    // MARK: 확정 / 남은 예정 (2칸, 좁으면 세로)

    /// 디자인 1l: 두 칸은 각각 따로 된 흰 카드
    private var confirmedCard: some View {
        let layout = typeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(spacing: PumTokens.Space.s12))
            : AnyLayout(HStackLayout(alignment: .top, spacing: PumTokens.Space.s12))
        return layout {
            PumCard(radius: PumTokens.Radius.md) { confirmedCell.padding(.vertical, PumTokens.Space.s14).padding(.horizontal, PumTokens.Space.s16) }
            PumCard(radius: PumTokens.Radius.md) { remainingCell.padding(.vertical, PumTokens.Space.s14).padding(.horizontal, PumTokens.Space.s16) }
        }
    }

    private var confirmedCell: some View {
        cell(title: "확정된 금액", titleColor: PumColor.statusDone,
             amount: record.confirmedText, amountColor: PumColor.textPrimary, detail: record.confirmedDetail)
    }

    /// 예정이라 금액을 보조색으로 흐리게
    private var remainingCell: some View {
        cell(title: "남은 예정", titleColor: PumColor.textSecondary,
             amount: record.remainingText, amountColor: PumColor.textSecondary, detail: record.remainingDetail)
    }

    private func cell(title: String, titleColor: Color, amount: String, amountColor: Color, detail: String) -> some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
            Text(title).pumText(.caption, weight: .semibold).foregroundStyle(titleColor)
                .padding(.bottom, PumTokens.Space.s2) // 제목 → 금액 4 = 2 + 2
            // 목업 18px 700 → headline 17 bold(가까운 단계)
            Text(amount).pumText(.headline, weight: .bold).foregroundStyle(amountColor)
                .lineLimit(1).minimumScaleFactor(0.7)
            Text(detail).pumText(.caption, weight: .regular).foregroundStyle(PumColor.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("\(title) \(amount), \(detail)"))
    }

    // MARK: 항목 카드

    private var itemsCard: some View {
        PumCard {
            // 원문: 카드 padding 0 18 · 행 위아래 14 · 구분선은 그 폭 안
            VStack(spacing: 0) {
                ForEach(Array(record.items.enumerated()), id: \.element.id) { index, item in
                    let isLast = index == record.items.count - 1
                    if item.isExpandable {
                        expandableRow(item, isLast: isLast)
                    } else {
                        itemRow(item, isLast: isLast)
                    }
                }
            }
            .padding(.horizontal, PumTokens.Space.s18)
        }
    }

    private func amountColor(_ item: ExpectedPayItem) -> Color {
        item.kind == .deduction ? PumColor.statusDanger : PumColor.textPrimary
    }

    private func rowLabel(_ item: ExpectedPayItem) -> some View {
        // 항목 이름 15px 600 → body semibold, 금액 16px 600 → body semibold
        HStack(spacing: PumTokens.Space.s12) {
            Text(item.label).pumText(.body, weight: .semibold).foregroundStyle(PumColor.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(item.amountText).pumText(.body, weight: .semibold).foregroundStyle(amountColor(item))
                .lineLimit(1).fixedSize(horizontal: true, vertical: false) // 숫자 중간 줄바꿈 금지
        }
    }

    private func itemRow(_ item: ExpectedPayItem, isLast: Bool) -> some View {
        Button { onItem(item) } label: {
            HStack(spacing: PumTokens.Space.s8) {
                rowLabel(item)
                Image(systemName: "chevron.right").font(.footnote.weight(.semibold))
                    .foregroundStyle(PumColor.textDisabled).accessibilityHidden(true)
            }
            .rowFrame(isLast: isLast)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(item.kind == .deduction
            ? "\(item.label) 마이너스 \(PumFormat.amount(item.amount))원" : "\(item.label) \(PumFormat.amount(item.amount))원"))
    }

    private func expandableRow(_ item: ExpectedPayItem, isLast: Bool) -> some View {
        let open = disclosure.isExpanded
        return VStack(spacing: 0) {
            Button {
                // M11 펼침 · 접힘 base, 동작 줄이기면 즉시(M22 「펼침 즉시」)
                withAnimation(reduceMotion ? nil : PumMotion.base) { disclosure.toggle() }
            } label: {
                HStack(spacing: PumTokens.Space.s8) {
                    rowLabel(item)
                    // 펼침 상태 = 파란 위 화살표
                    Image(systemName: "chevron.up").font(.footnote.weight(.semibold))
                        .foregroundStyle(PumColor.accent)
                        .rotationEffect(.degrees(open ? 0 : 180))
                        .accessibilityHidden(true)
                }
                .rowFrame(isLast: isLast && !open)
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text("\(item.label) \(PumFormat.amount(item.amount))원"))
            .accessibilityValue(Text(disclosure.stateText))
            .accessibilityHint(Text(open ? "계산 과정을 접어요" : "계산 과정을 펼쳐요"))
            if open {
                calcBox(item.calcLines)
                    .padding(.bottom, PumTokens.Space.s14)
                    .transition(reduceMotion ? .identity : .opacity.combined(with: .move(edge: .top)))
                    .overlay(alignment: .bottom) {
                        if !isLast {
                            Rectangle().fill(PumColor.borderHairline).frame(height: 1)
                        }
                    }
            }
        }
        .clipped()
    }

    /// 회색 바탕 상자: 서버가 준 계산 근거 줄을 그대로
    private func calcBox(_ lines: [ExpectedPayCalcLine]) -> some View {
        // 원문: 상자 padding 12 14 · 줄 사이 8 · 합계 줄은 위 구분선 + 위 padding 8
        VStack(spacing: PumTokens.Space.s8) {
            ForEach(lines) { l in
                if l.separatorAbove {
                    VStack(spacing: PumTokens.Space.s8) {
                        Rectangle().fill(PumColor.borderHairline).frame(height: 1)
                        calcLine(l)
                    }
                } else {
                    calcLine(l)
                }
            }
        }
        .padding(.vertical, PumTokens.Space.s12)
        .padding(.horizontal, PumTokens.Space.s14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(PumColor.surfaceFill, in: RoundedRectangle(cornerRadius: PumTokens.Radius.lg, style: .continuous))
    }

    private func calcLine(_ l: ExpectedPayCalcLine) -> some View {
        // 목업: 값은 13px 600, 마지막 합계만 700
        let valueWeight: Font.Weight = l.tone == .strong ? .bold : .semibold
        let valueColor: Color = l.tone == .positive ? PumColor.statusDone : PumColor.textPrimary
        return ViewThatFits(in: .horizontal) {
            HStack(alignment: .firstTextBaseline, spacing: PumTokens.Space.s8) {
                Text(l.label).pumText(.footnote, weight: .regular).foregroundStyle(PumColor.textSecondary)
                Spacer(minLength: PumTokens.Space.s8)
                Text(l.value).pumText(.footnote, weight: valueWeight).foregroundStyle(valueColor)
            }
            VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                Text(l.label).pumText(.footnote, weight: .regular).foregroundStyle(PumColor.textSecondary)
                Text(l.value).pumText(.footnote, weight: valueWeight).foregroundStyle(valueColor)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("\(l.label), \(l.value)"))
    }
}

private extension View {
    /// 원문 행: 위아래 14 · 44pt 최소 높이 · 구분선(좌우 여백은 카드가 준다)
    func rowFrame(isLast: Bool) -> some View {
        padding(.vertical, PumTokens.Space.s14)
            .frame(minHeight: PumTokens.Size.tapMin)
            .contentShape(Rectangle())
            .overlay(alignment: .bottom) {
                if !isLast {
                    Rectangle().fill(PumColor.borderHairline).frame(height: 1)
                }
            }
    }
}

#Preview("1l") { ExpectedPayView() }
#Preview("1l · 큰 글자") { ExpectedPayView().dynamicTypeSize(.accessibility2) }
