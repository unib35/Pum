// UI-IOS-1ac · REQ-060 · DEC-005 — 사장님 「사업장」 탭: 직원 관리(직원마다 다른 시급 · 계약 상태 · 전화)
// 색: 초록 = 계약 완료, 주황 = 서명 대기 · 보건증 임박, 파랑 = 다음 동작(조건 설정). 값은 서버 그대로.
import SwiftUI

/// 이 화면 전용 크기 — 토큰에 없는 것만(DEC-005)
private enum StaffListLayout {
    /// 직원 아바타 — 원문 40
    static let avatar: CGFloat = PumLayout.navRow
    /// 전화 버튼 원 지름(목업 약 36) — 터치 영역은 44
    static let callCircle: CGFloat = 36
}

struct StaffListView: View {
    var roster: StaffRoster = .sample
    var onMember: (StaffMember) -> Void = { _ in }
    var onCall: (StaffMember) -> Void = { _ in }
    var onSetCondition: (StaffMember) -> Void = { _ in }
    var onAdd: () -> Void = {}
    @State private var tab = "store"
    @Environment(\.dynamicTypeSize) private var typeSize
    @ScaledMetric(relativeTo: .body) private var avatar = StaffListLayout.avatar
    @ScaledMetric(relativeTo: .body) private var callCircle = StaffListLayout.callCircle

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: PumTokens.Space.s14) { // 원문 블록 사이 14
                header
                summary
                listCard
            }
            .padding(.horizontal, PumTokens.Size.screenPad)
            .padding(.bottom, PumTokens.Space.s24)
        }
        .background(PumColor.bgApp)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            PumTabBar(items: PumTabItem.ownerTabs(workBadge: 0), selection: $tab)
        }
    }

    /// 한 글자 크기 단계 + 굵기 — 한 줄 안에서 굵기가 섞이는 글자용
    private func run(_ style: PumTextStyle, _ weight: Font.Weight) -> Font {
        PumFont.font(size: style.token.size, weight: weight, relativeTo: style.relativeTo)
    }

    // MARK: 머리

    private var header: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: PumTokens.Space.s8) {
                title
                Spacer(minLength: PumTokens.Space.s8)
                PumInverseWorkplaceChip(name: roster.workplaceName, initial: roster.workplaceInitial)
                addButton
            }
            VStack(alignment: .leading, spacing: PumTokens.Space.s8) {
                title
                HStack(spacing: PumTokens.Space.s8) {
                    PumInverseWorkplaceChip(name: roster.workplaceName, initial: roster.workplaceInitial)
                    Spacer(minLength: PumTokens.Space.s8)
                    addButton
                }
            }
        }
    }

    private var title: some View {
        Text("직원").pumText(.title1).foregroundStyle(PumColor.textPrimary) // 28px 700
            .accessibilityAddTraits(.isHeader)
    }

    private var addButton: some View {
        PumIconButton(systemImage: "plus", label: "직원 추가", action: onAdd)
    }

    // MARK: 요약 한 줄

    private var summary: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: PumTokens.Space.s14) { summaryParts } // 원문 gap 14
            VStack(alignment: .leading, spacing: PumTokens.Space.s2) { summaryParts }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(roster.summaryAccessibilityText))
    }

    @ViewBuilder private var summaryParts: some View {
        // 13px: 「5명」 700 먹색 + 「 재직」 보조색
        Text("\(Text(roster.headcountText).font(run(.footnote, .bold)).foregroundColor(PumColor.textPrimary))\(Text(roster.headcountSuffix).font(run(.footnote, .regular)).foregroundColor(PumColor.textSecondary))")
            .pumText(.footnote, weight: .regular)
        Text(roster.breakdownText).pumText(.footnote, weight: .regular).foregroundStyle(PumColor.textSecondary)
    }

    // MARK: 직원 카드

    private var listCard: some View {
        PumCard {
            VStack(spacing: 0) {
                ForEach(Array(roster.members.enumerated()), id: \.element.id) { i, m in
                    if i > 0 { Rectangle().fill(PumColor.borderHairline).frame(height: 1) } // 행 사이 전폭 hairline
                    if m.isInvited { invitedRow(m) } else { row(m) }
                }
            }
        }
    }

    private var stacked: Bool { typeSize.isAccessibilitySize }

    private func row(_ m: StaffMember) -> some View {
        // 행 전체가 누름(상세 2l). 전화 버튼은 따로 눌려서, 행 버튼은 배경에 두고 글자는 터치를 통과시킨다.
        Group {
            if stacked {
                VStack(alignment: .leading, spacing: PumTokens.Space.s8) {
                    who(m).allowsHitTesting(false)
                    HStack(spacing: PumTokens.Space.s8) {
                        if m.showsCallButton { callButton(m) }
                        trailing(m, alignment: .leading).allowsHitTesting(false)
                    }
                }
            } else {
                HStack(spacing: PumTokens.Space.s8) {
                    who(m).frame(maxWidth: .infinity, alignment: .leading).allowsHitTesting(false)
                    if m.showsCallButton { callButton(m) }
                    trailing(m, alignment: .trailing).allowsHitTesting(false)
                }
            }
        }
        .padding(.vertical, PumTokens.Space.s14) // 원문 padding 14 16
        .padding(.horizontal, PumTokens.Space.s16)
        .frame(maxWidth: .infinity, minHeight: PumTokens.Size.tapMin, alignment: .leading)
        .background {
            Button { onMember(m) } label: { Color.clear.contentShape(Rectangle()) }
                .buttonStyle(.plain)
                .accessibilityLabel(Text(m.accessibilityText))
                .accessibilityHint(Text("직원 상세 보기"))
        }
    }

    private func invitedRow(_ m: StaffMember) -> some View {
        // 초대 중: 행 누름 없음, 「조건 설정」 버튼만
        Group {
            if stacked {
                VStack(alignment: .leading, spacing: PumTokens.Space.s8) { invitedWho(m); setConditionButton(m) }
            } else {
                HStack(spacing: PumTokens.Space.s8) {
                    invitedWho(m).frame(maxWidth: .infinity, alignment: .leading)
                    setConditionButton(m)
                }
            }
        }
        .padding(.vertical, PumTokens.Space.s14) // 원문 padding 14 16
        .padding(.horizontal, PumTokens.Space.s16)
        .frame(maxWidth: .infinity, minHeight: PumTokens.Size.tapMin, alignment: .leading)
    }

    private func who(_ m: StaffMember) -> some View {
        HStack(spacing: PumTokens.Space.s12) {
            PumAvatar(name: m.name, colorIndex: m.colorIndex, size: avatar) // 글자 크기는 공통 아바타 비율
            VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                Text(m.name).pumText(.body, weight: .semibold).foregroundStyle(PumColor.textPrimary) // 15px 600
                condition(m)
            }
        }
        .accessibilityHidden(true) // 행 버튼 라벨이 한 문장으로 읽는다
    }

    /// 12px 조건 줄 + 보건증(12px 600 — 서버 경고 플래그일 때만 주황)
    private func condition(_ m: StaffMember) -> some View {
        var t = Text(m.conditionText).font(run(.caption, .regular)).foregroundColor(PumColor.textSecondary)
        if let cert = m.healthCertText {
            let sep = Text(" \u{00B7} ").font(run(.caption, .regular)).foregroundColor(PumColor.textSecondary)
            let certText = Text(cert).font(run(.caption, .semibold))
                .foregroundColor(m.healthCertWarning ? PumColor.statusAttention : PumColor.textSecondary)
            t = Text("\(t)\(sep)\(certText)")
        }
        return t.pumText(.caption, weight: .regular).fixedSize(horizontal: false, vertical: true)
    }

    private func trailing(_ m: StaffMember, alignment: HorizontalAlignment) -> some View {
        VStack(alignment: alignment, spacing: PumTokens.Space.s2) {
            if let wage = m.wageText {
                // 17px 700 「12,000」 + 12px 500 「원/h」
                Text("\(Text(wage).font(run(.headline, .bold)).foregroundColor(PumColor.textPrimary))\(Text("원/h").font(run(.caption, .medium)).foregroundColor(PumColor.textSecondary))")
                    .pumText(.headline, weight: .bold)
                    .fixedSize(horizontal: false, vertical: true) // 시급은 핵심 값 — 큰 글자에서 줄이지 않는다(좁으면 행이 세로로 바뀜)
            }
            Text(m.status.title).pumText(.caption2, weight: .semibold) // 11px 600
                .foregroundStyle(color(m.status.tone))
        }
        .accessibilityHidden(true)
    }

    private func color(_ tone: StaffContractStatus.Tone) -> Color {
        switch tone {
        case .done: PumColor.statusDone
        case .attention: PumColor.statusAttention
        case .neutral: PumColor.textSecondary
        }
    }

    private func callButton(_ m: StaffMember) -> some View {
        Button { onCall(m) } label: {
            Image(systemName: "phone").pumText(.footnote, weight: .medium).foregroundStyle(PumColor.textPrimary)
                .frame(width: callCircle, height: callCircle)
                .background(PumColor.surfaceFill, in: Circle())
                .frame(minWidth: PumTokens.Size.tapMin, minHeight: PumTokens.Size.tapMin) // 보이는 36, 터치 44
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(m.callAccessibilityLabel))
    }

    // MARK: 초대 중 행

    private func invitedWho(_ m: StaffMember) -> some View {
        HStack(spacing: PumTokens.Space.s12) {
            // 회색 아바타(원문 #EAECF1 · #5B6170, 14px 700)
            Text(PumAvatar.initial(for: m.name)).pumText(.callout, weight: .bold)
                .foregroundStyle(PumTokens.ColorToken.gray700)
                .frame(width: avatar, height: avatar)
                .background(PumColor.surfaceFill, in: Circle())
            VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                Text(m.name).pumText(.body, weight: .semibold).foregroundStyle(PumColor.textSecondary)
                Text(m.scheduleText).pumText(.caption, weight: .regular).foregroundStyle(PumColor.textTertiary)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(m.accessibilityText))
    }

    private func setConditionButton(_ m: StaffMember) -> some View {
        Button { onSetCondition(m) } label: {
            Text("조건 설정").pumText(.footnote, weight: .semibold).foregroundStyle(PumColor.accent) // 13px 600
                .padding(.horizontal, PumTokens.Space.s4)
                .frame(minHeight: PumTokens.Size.tapMin)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(m.setConditionAccessibilityLabel))
    }
}

// MARK: - 먹색 사업장 칩

/// 1ac 원문은 1t와 같은 먹색 캡슐(꺾쇠 없음). 공통 PumWorkplaceChip에 먹색 변형이 없어 화면 전용 — 공통 후보

#Preview("1ac") { StaffListView() }
#Preview("1ac · 큰 글자") { StaffListView().dynamicTypeSize(.accessibility2) }
