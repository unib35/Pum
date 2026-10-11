// UI-IOS-4a · REQ-001 — 내 정보: 계정 → 소속 사업장 → 개인 근무 조건 · 서류 · 계좌 → 설정.
// 버튼 동작은 클로저로만. 탭 바는 원문 5개 — 공통 PumTabBar에 이 화면에서 목록을 넘긴다.
import SwiftUI

struct MyInfoView: View {
    var state: MyInfoState = .sample
    var onOpenAccount: () -> Void = {}
    var onAddInviteCode: () -> Void = {}
    var onOpenWorkplace: (MyInfoWorkplace) -> Void = { _ in }
    var onOpenPersonalTerms: () -> Void = {}
    var onOpenContracts: () -> Void = {}
    var onOpenDocuments: () -> Void = {}
    var onOpenPayAccount: () -> Void = {}
    var onOpenNotifications: () -> Void = {}
    var onStartOwnerMode: () -> Void = {}
    var onOpenSupport: () -> Void = {}
    var onSelectTab: (String) -> Void = { _ in }

    @State private var tab = "me"

    /// README 충돌 #9 — 확정 홈은 4개, 4a 원문은 5개. 공통 PumTabBar는 고치지 않고 여기서 5개를 만든다.
    private var tabs: [PumTabItem] {
        [
            .init(id: "home", title: "홈", systemImage: "house"),
            .init(id: "work", title: "근무", systemImage: "calendar"),
            .init(id: "news", title: "소식", systemImage: "bell"), // 원문 아이콘에 가까운 SF Symbol
            .init(id: "pay", title: "급여", systemImage: "wonsign.circle"),
            .init(id: "me", title: "내 정보", systemImage: "person"),
        ]
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: PumTokens.Space.s16) {
                Text("내 정보").pumText(.title1).foregroundStyle(PumColor.textPrimary)
                    .accessibilityAddTraits(.isHeader)
                    .padding(.top, PumTokens.Space.s8)
                accountCard
                workplaceSection
                PumCard {
                    MyInfoRow(title: "개인 근무 조건", note: "내 기록용", value: state.personalWageText, action: onOpenPersonalTerms)
                    MyInfoRow(title: "근로계약서 보관함", value: state.contractCountText, action: onOpenContracts)
                    MyInfoRow(title: "내 서류", note: "보건증·신분증·통장", value: state.healthCertText, valueIsAttention: true, action: onOpenDocuments)
                    MyInfoRow(title: "급여 계좌", value: state.bankText, isLast: true, action: onOpenPayAccount)
                }
                PumCard {
                    MyInfoRow(title: "알림 · 위치 · 잠금화면", action: onOpenNotifications)
                    MyInfoRow(title: "사장님 모드 시작하기", value: "사업장 만들기", valueIsAccent: true, showsChevron: false, action: onStartOwnerMode)
                    MyInfoRow(title: "고객센터 · 약관", isLast: true, action: onOpenSupport)
                }
            }
            .padding(.horizontal, PumTokens.Size.screenPad)
            .padding(.bottom, PumTokens.Space.s24)
        }
        .background(PumColor.bgApp)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            PumTabBar(items: tabs, selection: $tab)
        }
        .onChange(of: tab) { _, new in onSelectTab(new) }
    }

    // MARK: 계정

    private var accountCard: some View {
        Button(action: onOpenAccount) {
            PumCard {
                HStack(spacing: PumTokens.Space.s16) {
                    PumAvatar(name: state.name, colorIndex: 0, size: PumTokens.Size.buttonH) // 원문 약 52 → 54로 근사
                    VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                        Text(state.name).pumText(.headline, weight: .bold).foregroundStyle(PumColor.textPrimary) // 원문 18px 700 → headline 17
                        Text(state.accountLine).pumText(.footnote).foregroundStyle(PumColor.textSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    chevron
                }
                .padding(PumTokens.Space.s16)
                .frame(minHeight: PumTokens.Size.tapMin)
            }
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("\(state.name), \(state.accountLine)"))
        .accessibilityHint(Text("계정 정보를 열어요"))
    }

    // MARK: 소속 사업장

    private var workplaceSection: some View {
        VStack(spacing: PumTokens.Space.s8) {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .center) {
                    PumSectionHeader(title: state.workplaceHeader)
                    addButton
                }
                VStack(alignment: .leading, spacing: PumTokens.Space.s4) {
                    PumSectionHeader(title: state.workplaceHeader)
                    addButton
                }
            }
            if !state.workplaces.isEmpty {
                PumCard {
                    ForEach(Array(state.workplaces.enumerated()), id: \.element.id) { index, w in
                        WorkplaceRow(workplace: w, isLast: index == state.workplaces.count - 1) { onOpenWorkplace(w) }
                    }
                }
            }
        }
    }

    private var addButton: some View {
        Button(action: onAddInviteCode) {
            Text("+ 초대 코드로 추가")
                .font(PumFont.font(size: PumTokens.FontToken.caption.size, weight: .bold, relativeTo: .caption))
                .foregroundStyle(PumColor.accent)
                .padding(.horizontal, PumTokens.Space.s4)
                .frame(minHeight: PumTokens.Size.tapMin)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.vertical, -PumTokens.Space.s12) // 누름 영역만 44, 머리 줄 높이는 그대로
    }

    private var chevron: some View {
        Image(systemName: "chevron.right")
            .font(.body.weight(.semibold))
            .foregroundStyle(PumColor.textDisabled)
            .accessibilityHidden(true)
    }
}

// MARK: - 소속 사업장 행

private struct WorkplaceRow: View {
    let workplace: MyInfoWorkplace
    let isLast: Bool
    let action: () -> Void
    @ScaledMetric private var tile = PumLayout.avatar

    var body: some View {
        Button(action: action) {
            HStack(spacing: PumTokens.Space.s12) {
                // 공통 후보 — 목록 행용 사업장 색 네모(C7). 지금은 이 화면 전용(원문 36pt · 글자 13px 700)
                Text(workplace.initial)
                    .pumText(.footnote, weight: .bold)
                    .foregroundStyle(.white)
                    .frame(width: tile, height: tile)
                    .background(PumAvatarPalette.stores[workplace.colorIndex % PumAvatarPalette.stores.count],
                                in: RoundedRectangle(cornerRadius: tile * PumLayout.storeTileRadiusRatio, style: .continuous))
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                    Text(workplace.name).pumText(.body, weight: .semibold).foregroundStyle(PumColor.textPrimary)
                    Text(workplace.subtitle)
                        .pumText(.caption, weight: workplace.hasAttention ? .semibold : .regular)
                        .foregroundStyle(workplace.hasAttention ? PumColor.statusAttention : PumColor.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: "chevron.right")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(PumColor.textDisabled)
                    .accessibilityHidden(true)
            }
            .padding(.vertical, PumTokens.Size.rowPadY)
            .padding(.horizontal, PumTokens.Size.rowPadX)
            .frame(minHeight: PumTokens.Size.tapMin)
            .contentShape(Rectangle())
            .overlay(alignment: .bottom) {
                if !isLast { Rectangle().fill(PumColor.borderHairline).frame(height: 1) } // 원문: 카드 폭 전체 구분선
            }
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(workplace.accessibilityText))
        .accessibilityHint(Text("사업장 정보를 열어요"))
    }
}

// MARK: - 설정 · 값 행

/// 공통 후보 — 제목 옆 작은 보조 글자(· 내 기록용) + 오른쪽 값 + ›. 공통 PumRow는 보조 글자 · 값 색을 못 해 이 화면 전용.
private struct MyInfoRow: View {
    let title: String
    var note: String?
    var value: String?
    var valueIsAttention = false
    var valueIsAccent = false
    var showsChevron = true
    var isLast = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            // 값이 길어지면(글자 크게) 제목 아래로 내린다
            ViewThatFits(in: .horizontal) {
                HStack(spacing: PumTokens.Space.s12) {
                    titleLine
                    Spacer(minLength: PumTokens.Space.s8)
                    valueText
                    chevron
                }
                HStack(alignment: .top, spacing: PumTokens.Space.s12) {
                    VStack(alignment: .leading, spacing: PumTokens.Space.s4) {
                        titleLine
                        valueText
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    chevron
                }
            }
            .padding(.vertical, PumTokens.Size.rowPadY)
            .padding(.horizontal, PumTokens.Size.rowPadX)
            .frame(minHeight: PumTokens.Size.tapMin)
            .contentShape(Rectangle())
            .overlay(alignment: .bottom) {
                if !isLast { Rectangle().fill(PumColor.borderHairline).frame(height: 1) }
            }
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(accessibilityText))
    }

    private var titleLine: some View {
        // 원문: 제목 15px 500 + 보조 12px 500 회색
        let main = Text(title).font(PumTextStyle.body.font).foregroundStyle(PumColor.textPrimary)
        let sub = Text(" · \(note ?? "")")
            .font(PumFont.font(size: PumTokens.FontToken.caption.size, weight: .medium, relativeTo: .caption))
            .foregroundStyle(PumColor.textSecondary)
        return Group {
            if note != nil { main + sub } else { main }
        }
        .tracking(PumTokens.Tracking.body)
        .multilineTextAlignment(.leading)
    }

    @ViewBuilder private var valueText: some View {
        if let value {
            Text(value)
                .pumText(.footnote, weight: valueIsAttention || valueIsAccent ? .semibold : .regular)
                .foregroundStyle(valueIsAttention ? PumColor.statusAttention : valueIsAccent ? PumColor.accent : PumColor.textSecondary)
                .multilineTextAlignment(.trailing)
        }
    }

    @ViewBuilder private var chevron: some View {
        if showsChevron {
            Image(systemName: "chevron.right")
                .font(.body.weight(.semibold))
                .foregroundStyle(PumColor.textDisabled)
                .accessibilityHidden(true)
        }
    }

    private var accessibilityText: String {
        [title, note, value].compactMap { $0 }.joined(separator: ", ")
    }
}

#Preview("내 정보 4a") { MyInfoView(state: .sample) }
#Preview("내 정보 · 사업장 없음") {
    var s = MyInfoState.sample
    s.workplaces = []
    return MyInfoView(state: s)
}
