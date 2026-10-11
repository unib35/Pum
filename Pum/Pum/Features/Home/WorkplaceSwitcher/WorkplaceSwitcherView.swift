// UI-IOS-1y · REQ-008 · DEC-005 — 사업장 전환: 홈 상단 칩을 누르면 열리는 시트. 홈 어느 안에서든 같다.
// 사업장 선택 · 모아보기 · 초대 코드 추가는 바깥에서 처리한다(클로저). 막을 누르면 닫는다.
import SwiftUI

struct WorkplaceSwitcherView: View {
    @State private var state: WorkplaceSwitcherState
    @State private var sheetOpen: Bool
    var onClose: () -> Void
    /// 고른 사업장 id
    var onSelect: (String) -> Void
    var onShowAll: () -> Void
    var onAddByCode: () -> Void

    init(state: WorkplaceSwitcherState = .sample, sheetOpen: Bool = true,
         onClose: @escaping () -> Void = {},
         onSelect: @escaping (String) -> Void = { _ in },
         onShowAll: @escaping () -> Void = {},
         onAddByCode: @escaping () -> Void = {}) {
        _state = State(initialValue: state)
        _sheetOpen = State(initialValue: sheetOpen)
        self.onClose = onClose
        self.onSelect = onSelect
        self.onShowAll = onShowAll
        self.onAddByCode = onAddByCode
    }

    var body: some View {
        background
            .background(PumColor.bgApp)
            .pumBottomSheet(isPresented: $sheetOpen, onDismiss: onClose) {
                WorkplaceSwitcherSheet(
                    state: state,
                    onSelect: { id in state.select(id); sheetOpen = false; onSelect(id) },
                    onShowAll: { sheetOpen = false; onShowAll() },
                    onAddByCode: { sheetOpen = false; onAddByCode() }
                )
            }
    }

    /// 뒤 화면: 열린 칩 + 알림 + 오늘 카드(시트에 덮여 어둡게)
    private var background: some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s12) {
            HStack {
                OpenWorkplaceChip(workplace: state.selected)
                Spacer()
                PumIconButton(systemImage: "bell", label: "알림", showsDot: state.hasUnreadNotification) {}
            }
            .padding(.top, PumTokens.Space.s8)
            todayCard
            Spacer(minLength: 0)
        }
        .padding(.horizontal, PumTokens.Size.screenPad)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private var todayCard: some View {
        PumCard {
            VStack(alignment: .leading, spacing: PumTokens.Space.s12) {
                HStack {
                    Text(state.todayTitle).pumText(.footnote, weight: .medium).foregroundStyle(PumColor.textSecondary)
                    Spacer()
                    PumBadge(text: "출근 전", kind: .waiting)
                }
                ViewThatFits(in: .horizontal) {
                    shiftRange(spacing: PumTokens.Space.s8)
                    shiftRange(spacing: PumTokens.Space.s4).minimumScaleFactor(0.6)
                }
            }
            .padding(PumTokens.Space.s20)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    /// 「17:00 – 22:00」 — 큰 먹색 700, 가운데 「–」는 400 gray400
    private func shiftRange(spacing: CGFloat) -> some View {
        HStack(spacing: spacing) {
            Text(state.shiftStart).pumText(.display).foregroundStyle(PumColor.textPrimary)
            Text("\u{2013}").pumText(.display, weight: .regular).foregroundStyle(PumTokens.ColorToken.gray400)
            Text(state.shiftEnd).pumText(.display).foregroundStyle(PumColor.textPrimary)
        }
        .lineLimit(1)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(state.shiftRangeSpoken))
    }
}

/// 열린 상태의 사업장 칩 — 공통 `PumWorkplaceChip`에 열린 상태가 없어 같은 모양에 파랑 테두리 · 위 꺾쇠만 다르게(공통 후보)
struct OpenWorkplaceChip: View {
    let workplace: SwitcherWorkplace?

    var body: some View {
        HStack(spacing: PumTokens.Space.s8) {
            Text(workplace?.initial ?? "")
                .pumText(.caption2, weight: .bold)
                .foregroundStyle(.white)
                .frame(width: PumLayout.storeTileSmall, height: PumLayout.storeTileSmall)
                .background(workplace?.tileColor ?? PumColor.accent,
                            in: RoundedRectangle(cornerRadius: PumLayout.storeTileSmall * PumLayout.storeTileRadiusRatio, style: .continuous))
            Text(workplace?.name ?? "").pumText(.callout).foregroundStyle(PumColor.textPrimary)
            Image(systemName: "chevron.up").font(.caption.weight(.semibold)).foregroundStyle(PumColor.textSecondary)
        }
        .padding(.leading, PumTokens.Space.s8)
        .padding(.trailing, PumTokens.Space.s12)
        .frame(minHeight: PumTokens.Size.tapMin)
        .background(PumColor.surfaceCard, in: Capsule())
        .overlay(Capsule().strokeBorder(PumColor.accent, lineWidth: WorkplaceSwitcherLocal.openRingWidth))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("사업장 선택, \(workplace?.name ?? ""), 펼쳐짐"))
    }
}

#Preview("1y") { WorkplaceSwitcherView() }
#Preview("1y · 큰 글자") { WorkplaceSwitcherView().dynamicTypeSize(.accessibility1) }
