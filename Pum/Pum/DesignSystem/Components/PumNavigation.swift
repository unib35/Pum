// C6 Navigation — 사업장 칩(무채색) · 원형 아이콘 버튼 · 하단 탭 바
// 활성 탭 파랑, 비활성 --gray-500(= textTertiary #8A919E) · 아이콘은 SF Symbols(F8) · 알림 점은 주황(처리 필요)
import SwiftUI

/// 상단 사업장 칩 — 누르면 사업장 전환 시트(1y)
struct PumWorkplaceChip: View {
    let name: String
    let initial: String
    var tileColor: Color = PumColor.accent
    /// 역할 배지(예: 「사장님」). 사장님 사업장은 타일도 무채색(DEC-007 · 1az)
    var role: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: PumTokens.Space.s8) {
                Text(initial)
                    .pumText(.caption2, weight: .bold)
                    .foregroundStyle(.white)
                    .frame(width: PumLayout.storeTileSmall, height: PumLayout.storeTileSmall)
                    .background(tileColor, in: RoundedRectangle(cornerRadius: PumLayout.storeTileSmall * PumLayout.storeTileRadiusRatio, style: .continuous))
                Text(name).pumText(.callout).foregroundStyle(PumColor.textPrimary)
                if let role {
                    Text(role)
                        .pumText(.caption2, weight: .bold)
                        .foregroundStyle(PumTokens.ColorToken.gray700)
                        .padding(.horizontal, PumTokens.Space.s6)
                        .padding(.vertical, PumTokens.Space.s2)
                        .background(PumColor.surfaceFill, in: RoundedRectangle(cornerRadius: PumTokens.Radius.xs, style: .continuous))
                }
                Image(systemName: "chevron.down")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(PumColor.textSecondary)
            }
            .padding(.leading, PumTokens.Space.s8)
            .padding(.trailing, PumTokens.Space.s12)
            .frame(minHeight: PumTokens.Size.tapMin)
            .background(PumColor.surfaceCard, in: Capsule())
            .pumRing(.hairline, cornerRadius: PumTokens.Size.tapMin / 2)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text("사업장: \(name)\(role.map { ", \($0)" } ?? "")"))
        .accessibilityHint(Text("사업장을 바꿔요"))
    }
}

/// C6 NAV HEADER — 왼쪽 원형 뒤로 버튼 · 가운데 제목 · 오른쪽 선택 동작(예: 편집)
struct PumNavHeader<Trailing: View>: View {
    let title: String
    var onBack: (() -> Void)?
    @ViewBuilder var trailing: Trailing

    var body: some View {
        ZStack {
            Text(title)
                .pumText(.headline)
                .foregroundStyle(PumColor.textPrimary)
                .lineLimit(1)
                .padding(.horizontal, PumTokens.Size.tapMin + PumTokens.Space.s8)
                .accessibilityAddTraits(.isHeader)
            HStack {
                if let onBack {
                    PumIconButton(systemImage: "chevron.left", label: "뒤로", action: onBack)
                } else {
                    Color.clear.frame(width: PumTokens.Size.tapMin, height: PumTokens.Size.tapMin)
                }
                Spacer()
                trailing
            }
        }
        .padding(.top, PumTokens.Space.s8)
    }
}

extension PumNavHeader where Trailing == EmptyView {
    init(title: String, onBack: (() -> Void)? = nil) {
        self.init(title: title, onBack: onBack) { EmptyView() }
    }
}

/// 원형 아이콘 버튼(알림 등). `showsDot`이면 처리 필요 점(주황).
struct PumIconButton: View {
    let systemImage: String
    let label: String
    var showsDot = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: PumLayout.navIcon, weight: .medium))
                .foregroundStyle(PumColor.textPrimary)
                .frame(width: PumTokens.Size.tapMin, height: PumTokens.Size.tapMin)
                .background(PumColor.surfaceCard, in: Circle())
                .pumRing(.hairline, cornerRadius: PumTokens.Size.tapMin / 2)
                .overlay(alignment: .topTrailing) {
                    if showsDot {
                        Circle().fill(PumColor.statusAttentionDot)
                            .frame(width: PumLayout.notificationDot, height: PumLayout.notificationDot)
                            .offset(x: -PumTokens.Space.s6, y: PumTokens.Space.s6)
                    }
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(showsDot ? "\(label), 새 항목 있음" : label))
    }
}

struct PumTabItem: Identifiable, Hashable {
    let id: String
    let title: String
    let systemImage: String
    /// 처리 필요 개수(0이면 표시 안 함) — 탭 바에서 유일한 원형 배지(C2 · #C8641A)
    var badge: Int = 0
}

/// 하단 탭 바 — 디자인 1at 기준 4개(홈 · 근무 · 급여 · 내 정보). 탭 구성은 README 충돌 #9 참고.
struct PumTabBar: View {
    let items: [PumTabItem]
    @Binding var selection: String

    var body: some View {
        HStack(spacing: 0) {
            ForEach(items) { item in
                let active = item.id == selection
                Button { selection = item.id } label: {
                    VStack(spacing: PumLayout.tabLabelGap) {
                        Image(systemName: item.systemImage).font(.system(size: PumLayout.tabIcon, weight: .regular))
                            .symbolVariant(.none) // F8: 채운 아이콘 없음(선택돼도 외곽선)
                            .overlay(alignment: .topTrailing) {
                                if item.badge > 0 {
                                    Text("\(item.badge)")
                                        .pumText(.caption2, weight: .bold)
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, PumTokens.Space.s4)
                                        .frame(minWidth: PumLayout.tabBadge, minHeight: PumLayout.tabBadge)
                                        .background(PumColor.statusAttentionDot, in: Capsule())
                                        .offset(x: PumTokens.Space.s12, y: -PumTokens.Space.s6)
                                }
                            }
                        Text(item.title).pumText(.caption2, weight: .medium)
                    }
                    .foregroundStyle(active ? PumColor.accent : PumColor.textTertiary)
                    .frame(maxWidth: .infinity, minHeight: PumTokens.Size.tapMin)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text(item.badge > 0 ? "\(item.title), 처리할 일 \(item.badge)건" : item.title))
                .accessibilityHint(Text("탭"))
                .accessibilityAddTraits(active ? [.isSelected] : [])
            }
        }
        .padding(.top, PumTokens.Space.s8)
        .background(PumColor.surfaceCard) // 불투명: 스크롤한 내용이 비쳐 글자가 겹치지 않게
        .overlay(alignment: .top) { Rectangle().fill(PumColor.borderHairline).frame(height: 1) }
    }
}

extension PumTabItem {
    static let employeeTabs: [PumTabItem] = [
        .init(id: "home", title: "홈", systemImage: "house"),
        .init(id: "work", title: "근무", systemImage: "calendar"),
        .init(id: "pay", title: "급여", systemImage: "wonsign.circle"),
        .init(id: "me", title: "내 정보", systemImage: "person"),
    ]

    /// 사장님 탭 4개(디자인 1az · C6 「사장님 4」)
    static func ownerTabs(workBadge: Int = 0) -> [PumTabItem] {
        [
            .init(id: "home", title: "홈", systemImage: "house"),
            .init(id: "work", title: "근무", systemImage: "calendar", badge: workBadge),
            .init(id: "pay", title: "급여", systemImage: "wonsign.circle"),
            .init(id: "store", title: "사업장", systemImage: "storefront"),
        ]
    }
}
