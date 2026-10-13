// UI-IOS-3a · REQ-041 · REQ-040 — 직원 소식: 요청은 위에 고정 → 공지(읽음 표시) → 알림. 필터로 섹션만 보기.
// 버튼 동작은 클로저로만(전송은 후속). 탭 바는 원문 5개 — 공통 PumTabBar에 이 화면에서 목록을 넘긴다.
import SwiftUI

struct NewsFeedView: View {
    var state: NewsFeedState = .sample
    var onAccept: (ExtraShiftRequest) -> Void = { _ in }
    var onDecline: (ExtraShiftRequest) -> Void = { _ in }
    var onOpenContract: (ContractSignRequest) -> Void = { _ in }
    var onOpenNotice: (NewsNotice) -> Void = { _ in }
    var onOpenWorkplaceSwitcher: () -> Void = {}
    // 15d 초대(거절 · 확인하기). 거절은 되돌릴 수 없어 확인 창이 필요할 수 있으나 원문이 없어 클로저만 둔다.
    var onDeclineInvite: (NewsInvite) -> Void = { _ in }
    var onOpenInvite: (NewsInvite) -> Void = { _ in }
    /// 처리 중인 초대 버튼(누른 버튼에만 표시). 서버 상태를 부모가 내려준다.
    var inviteAction: InviteAction? = nil

    /// 15d 초대 카드에서 처리 중인 버튼
    nonisolated enum InviteAction: Hashable, Sendable { case decline, open }

    @State private var filter: NewsFilter = .all
    @State private var tab = "news"
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// README 충돌 #9 — 확정 홈은 4개, 3a 원문은 5개. 공통 PumTabBar는 고치지 않고 여기서 5개를 만든다.
    private var tabs: [PumTabItem] {
        [
            .init(id: "home", title: "홈", systemImage: "house"),
            .init(id: "work", title: "근무", systemImage: "calendar"),
            .init(id: "news", title: "소식", systemImage: "bell", badge: state.tabBadge), // 원문 아이콘에 가까운 SF Symbol
            .init(id: "pay", title: "급여", systemImage: "wonsign.circle"),
            .init(id: "me", title: "내 정보", systemImage: "person"),
        ]
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: PumTokens.Space.s14) { // 원문 블록 사이 14
                header
                NewsFilterBar(selection: $filter, noticeCount: state.unreadNoticeCount, requestCount: state.requestCount)
                if state.shows(.request, under: filter), !state.requests.isEmpty || state.invite != nil { requestSection }
                if state.shows(.notice, under: filter), !state.notices.isEmpty { noticeSection }
                if state.shows(.alert, under: filter), !state.alerts.isEmpty { alertSection }
            }
            .padding(.horizontal, PumTokens.Size.screenPad)
            .padding(.bottom, PumTokens.Space.s24)
            .animation(PumMotion.respecting(reduceMotion, PumMotion.fast), value: filter)
        }
        .background(PumColor.bgApp)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            PumTabBar(items: tabs, selection: $tab)
        }
    }

    private var header: some View {
        ViewThatFits(in: .horizontal) {
            HStack {
                title
                Spacer(minLength: PumTokens.Space.s8)
                chip
            }
            VStack(alignment: .leading, spacing: PumTokens.Space.s12) {
                title
                chip
            }
        }
    }

    private var title: some View {
        Text("소식").pumText(.title1).foregroundStyle(PumColor.textPrimary)
            .accessibilityAddTraits(.isHeader)
    }

    /// 서버가 준 색 번호 — 범위 밖 · 음수도 순환(크래시 방지)
    private var storeColor: Color {
        let stores = PumAvatarPalette.stores
        return stores[((state.workplaceTileIndex % stores.count) + stores.count) % stores.count]
    }

    private var chip: some View {
        PumWorkplaceChip(name: state.workplaceName, initial: state.workplaceInitial,
                         tileColor: storeColor, action: onOpenWorkplaceSwitcher)
    }

    // MARK: 섹션

    private var requestSection: some View {
        VStack(spacing: PumTokens.Space.s8) {
            PumSectionHeader(title: "결정이 필요해요", attention: true)
            VStack(spacing: PumTokens.Space.s14) { // 원문: 요청 카드 사이 14
                if let invite = state.invite { // 15d: 결정 섹션 맨 위. 없으면 아무것도 그리지 않는다(3a 그대로)
                    InviteCard(invite: invite, action: inviteAction,
                               onDecline: { onDeclineInvite(invite) }, onOpen: { onOpenInvite(invite) })
                }
                ForEach(state.requests) { request in
                    switch request {
                    case .extraShift(let r): ExtraShiftCard(request: r, onAccept: { onAccept(r) }, onDecline: { onDecline(r) })
                    case .contractSign(let r): ContractSignCard(request: r) { onOpenContract(r) }
                    }
                }
            }
        }
        .padding(.top, PumTokens.Space.s2) // 원문 섹션 제목 위 2
    }

    private var noticeSection: some View {
        VStack(spacing: PumTokens.Space.s8) {
            PumSectionHeader(title: "공지")
            PumCard {
                ForEach(Array(state.notices.enumerated()), id: \.element.id) { index, notice in
                    if state.invite == nil {
                        NoticeRow(notice: notice, isLast: index == state.notices.count - 1) { onOpenNotice(notice) }
                    } else { // 15d: 날짜가 제목 줄 오른쪽
                        TrailingDateNoticeRow(notice: notice, isLast: index == state.notices.count - 1) { onOpenNotice(notice) }
                    }
                }
            }
        }
        .padding(.top, PumTokens.Space.s2)
    }

    private var alertSection: some View {
        VStack(spacing: PumTokens.Space.s8) {
            PumSectionHeader(title: "알림")
            PumCard {
                ForEach(Array(state.alerts.enumerated()), id: \.element.id) { index, alert in
                    if alert.source == nil {
                        AlertRow(alert: alert, isLast: index == state.alerts.count - 1)
                    } else { // 15d: 시각이 제목 줄 오른쪽 · 아래 사업장 이름
                        SourceAlertRow(alert: alert, isLast: index == state.alerts.count - 1)
                    }
                }
            }
        }
        .padding(.top, PumTokens.Space.s2)
    }
}

// MARK: - 필터 세그먼트

/// 공통 후보 — 회색 바탕 안에 흰 선택 칸이 있는 세그먼트(3a 원문). 지금은 이 화면 전용.
private struct NewsFilterBar: View {
    @Binding var selection: NewsFilter
    let noticeCount: Int
    let requestCount: Int

    var body: some View {
        HStack(spacing: 0) {
            ForEach(NewsFilter.allCases, id: \.self) { item in
                let selected = item == selection
                Button { selection = item } label: {
                    HStack(spacing: PumTokens.Space.s4) {
                        Text(item.title)
                            .pumText(.footnote, weight: selected ? .semibold : .medium)
                            .foregroundStyle(selected ? PumColor.textPrimary : PumColor.textSecondary)
                        if let count = count(item), count > 0 {
                            Text("\(count)").pumText(.footnote, weight: .bold).foregroundStyle(countColor(item))
                        }
                    }
                    // 원문 바 높이 약 35 = 칸 28 + 바깥 4 · 4. 누름 영역은 위아래로 8씩 넓혀 44(옆 칸과 겹치지 않게 세로만)
                    .frame(maxWidth: .infinity, minHeight: PumTokens.Size.tapMin - PumTokens.Space.s16)
                    .background {
                        if selected {
                            RoundedRectangle(cornerRadius: PumTokens.Radius.md, style: .continuous).fill(PumColor.surfaceCard)
                        }
                    }
                    .padding(.vertical, PumTokens.Space.s8)
                    .contentShape(Rectangle())
                    .padding(.vertical, -PumTokens.Space.s8)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text(label(item)))
                .accessibilityAddTraits(selected ? [.isSelected] : [])
            }
        }
        .padding(PumTokens.Space.s4)
        .background(PumColor.surfaceFill, in: RoundedRectangle(cornerRadius: PumTokens.Radius.lg, style: .continuous))
    }

    private func count(_ f: NewsFilter) -> Int? {
        switch f {
        case .notice: noticeCount
        case .request: requestCount
        default: nil
        }
    }

    private func countColor(_ f: NewsFilter) -> Color { f == .request ? PumColor.statusAttention : PumColor.accent }

    private func label(_ f: NewsFilter) -> String {
        switch f {
        case .notice: noticeCount > 0 ? "공지, 안 읽은 \(noticeCount)건" : "공지"
        case .request: requestCount > 0 ? "요청, \(requestCount)건" : "요청"
        default: f.title
        }
    }
}

// MARK: - 요청 카드

private struct ExtraShiftCard: View {
    let request: ExtraShiftRequest
    let onAccept: () -> Void
    let onDecline: () -> Void

    var body: some View {
        PumCard(attention: true) {
            VStack(alignment: .leading, spacing: PumTokens.Space.s8) {
                HStack {
                    PumBadge(text: "추가 근무 요청", kind: .attention)
                    Spacer(minLength: PumTokens.Space.s8)
                    Text(request.ago).pumText(.caption).foregroundStyle(PumColor.textSecondary)
                }
                VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                    Text(request.summary).pumText(.body, weight: .semibold).foregroundStyle(PumColor.textPrimary)
                    Text(request.detail).pumText(.caption).foregroundStyle(PumColor.textSecondary)
                }
                .accessibilityElement(children: .combine)
                // 원문 버튼 비율 약 1 : 1.4(왼쪽이 좁음) — 공통 PAIR(1 : 1.5)로 근사. 「어려워요」는 먹색 외곽선(원문)
                PumButtonPair(negative: "어려워요", positive: "근무 가능해요", negativeKind: .outline, size: .small, // 원문 버튼 높이 약 40 · 14px 600 → small(3b와 같음)
                              onNegative: onDecline, onPositive: onAccept)
                    .padding(.top, PumTokens.Space.s4)
            }
            .padding(.vertical, PumTokens.Space.s14) // 원문 padding 14 16
            .padding(.horizontal, PumTokens.Space.s16)
        }
    }
}

private struct ContractSignCard: View {
    let request: ContractSignRequest
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            PumCard(attention: true) {
                HStack(spacing: PumTokens.Space.s12) {
                    VStack(alignment: .leading, spacing: PumTokens.Space.s8) {
                        HStack(spacing: PumTokens.Space.s8) {
                            PumBadge(text: "계약 서명 요청", kind: .attention)
                            Text(request.ago).pumText(.caption).foregroundStyle(PumColor.textSecondary)
                        }
                        VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                            Text(request.title).pumText(.body, weight: .semibold).foregroundStyle(PumColor.textPrimary)
                            Text(request.detail).pumText(.caption).foregroundStyle(PumColor.textSecondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    Image(systemName: "chevron.right")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(PumColor.textDisabled)
                        .accessibilityHidden(true)
                }
                .padding(.vertical, PumTokens.Space.s14)
                .padding(.horizontal, PumTokens.Space.s16)
                .frame(minHeight: PumTokens.Size.tapMin)
            }
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityHint(Text("계약서를 열어요"))
    }
}

// MARK: - 초대 카드 (15d)

private struct InviteCard: View {
    let invite: NewsInvite
    let action: NewsFeedView.InviteAction?
    let onDecline: () -> Void
    let onOpen: () -> Void
    @Environment(\.dynamicTypeSize) private var typeSize
    @ScaledMetric private var tile = PumLayout.avatar + PumTokens.Space.s4 // 원문 타일 40

    var body: some View {
        PumCard(attention: true) {
            VStack(alignment: .leading, spacing: PumTokens.Space.s10) {
              VStack(alignment: .leading, spacing: PumTokens.Space.s10) {
                HStack {
                    PumBadge(text: "직원 초대", kind: .attention)
                    Spacer(minLength: PumTokens.Space.s8)
                    Text(invite.ago).pumText(.caption).foregroundStyle(PumColor.textSecondary)
                }
                HStack(spacing: PumTokens.Space.s12) {
                    Text(invite.workplaceInitial)
                        .pumText(.callout, weight: .bold)
                        .foregroundStyle(.white)
                        .frame(width: tile, height: tile)
                        .background(PumColor.accent, in: RoundedRectangle(cornerRadius: tile * PumLayout.storeTileRadiusRatio, style: .continuous))
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                        Text(invite.title).pumText(.body, weight: .semibold).foregroundStyle(PumColor.textPrimary)
                        Text(invite.detail).pumText(.caption).foregroundStyle(PumColor.textSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
              }
              .accessibilityElement(children: .ignore)
              .accessibilityLabel(Text("직원 초대, \(invite.ago), \(invite.title), \(invite.detail)"))
                buttons
            }
            .padding(.vertical, PumTokens.Space.s14)
            .padding(.horizontal, PumTokens.Space.s16)
        }
        .accessibilityElement(children: .contain)
    }

    /// 글자가 커지면(접근성 크기) 버튼을 위아래로 쌓는다.
    /// 처리 중엔 두 버튼 다 누를 수 없지만, 처리 중 모양은 누른 버튼에만(다른 버튼은 모양 그대로).
    @ViewBuilder private var buttons: some View {
        if typeSize.isAccessibilitySize {
            VStack(spacing: PumTokens.Space.s8) {
                PumButton(title: "확인하기", size: .small, isLoading: action == .open, action: onOpen).allowsHitTesting(action == nil)
                PumButton(title: "거절", kind: .outline, size: .small, isLoading: action == .decline, action: onDecline).allowsHitTesting(action == nil)
            }
        } else {
            InviteButtonRow(spacing: PumTokens.Space.s8) { // 원문 비율 약 2 : 3
                PumButton(title: "거절", kind: .outline, size: .small, isLoading: action == .decline, action: onDecline)
                    .allowsHitTesting(action == nil)
                PumButton(title: "확인하기", size: .small, isLoading: action == .open, action: onOpen)
                    .allowsHitTesting(action == nil)
            }
        }
    }
}

/// 버튼 두 개를 받은 폭 그대로 2 : 3으로 나눈다(우선순위로 다투면 한쪽이 찌그러짐)
private struct InviteButtonRow: Layout {
    var spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 0
        let height = subviews.map { $0.sizeThatFits(ProposedViewSize(width: width / 2, height: nil)).height }.max() ?? 0
        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        guard subviews.count == 2 else { return }
        let usable = max(bounds.width - spacing, 0)
        let first = usable * 2 / 5
        subviews[0].place(at: bounds.origin, proposal: ProposedViewSize(width: first, height: bounds.height))
        subviews[1].place(at: CGPoint(x: bounds.minX + first + spacing, y: bounds.minY),
                          proposal: ProposedViewSize(width: usable - first, height: bounds.height))
    }
}

// MARK: - 공지 · 알림 행

private struct NoticeRow: View {
    let notice: NewsNotice
    let isLast: Bool
    let action: () -> Void
    @ScaledMetric private var dot = PumLayout.notificationDot - 1

    var body: some View {
        Button(action: action) {
            HStack(alignment: .firstTextBaseline, spacing: PumTokens.Space.s12) {
                // 안읽음 = 파란 점. 읽음은 같은 폭을 비워 제목 줄을 맞춘다(원문)
                Circle().fill(notice.isRead ? .clear : PumColor.accent)
                    .frame(width: dot, height: dot)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: PumTokens.Space.s4) { // 원문 제목–본문 3 → 4
                    Text(notice.title)
                        .pumText(.body, weight: notice.isRead ? .semibold : .bold)
                        .foregroundStyle(notice.isRead ? PumTokens.ColorToken.gray700 : PumColor.textPrimary)
                    if let body = notice.body {
                        Text(body).pumText(.footnote).foregroundStyle(PumTokens.ColorToken.gray800)
                            .lineLimit(2)
                    }
                    meta.padding(.top, notice.body == nil ? 0 : PumTokens.Space.s2) // 원문 본문 있을 때 위 6
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.vertical, PumTokens.Space.s14) // 원문 padding 14 16
            .padding(.horizontal, PumTokens.Size.rowPadX)
            .frame(minHeight: PumTokens.Size.tapMin)
            .contentShape(Rectangle())
            .overlay(alignment: .bottom) {
                if !isLast { Rectangle().fill(PumColor.borderHairline).frame(height: 1) } // 원문: 카드 폭 전체 구분선
            }
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(accessibilityText))
        .accessibilityHint(Text("공지를 열어요"))
    }

    private var meta: some View {
        let base = "\(notice.author) · \(notice.date)"
        return Group {
            if let link = notice.linkLabel {
                Text("\(Text(base + " · ").foregroundStyle(PumColor.textSecondary))\(Text(link).fontWeight(.semibold).foregroundStyle(PumColor.accent))")
            } else {
                Text(base + (notice.isRead ? " · 읽음" : "")).foregroundStyle(PumColor.textSecondary)
            }
        }
        .pumText(.caption)
    }

    private var accessibilityText: String {
        var parts = [notice.isRead ? "읽은 공지" : "안 읽은 공지", notice.title]
        if let body = notice.body { parts.append(body) }
        parts.append("\(notice.author), \(notice.date)")
        if let link = notice.linkLabel { parts.append(link) }
        if notice.isRead { parts.append("읽음") }
        return parts.joined(separator: ", ")
    }
}

private struct AlertRow: View {
    let alert: NewsAlert
    let isLast: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
            Text(alert.message).pumText(.callout, weight: .medium)
                .foregroundStyle(alert.isMuted ? PumTokens.ColorToken.gray700 : PumColor.textPrimary)
            Text(alert.time).pumText(.caption).foregroundStyle(PumColor.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, PumTokens.Size.rowPadY)
        .padding(.horizontal, PumTokens.Size.rowPadX)
        .overlay(alignment: .bottom) {
            if !isLast { Rectangle().fill(PumColor.borderHairline).frame(height: 1) }
        }
        .accessibilityElement(children: .combine)
    }
}

/// 15d 공지 행 — 제목 오른쪽에 날짜, 아래 「사업장 · 읽음」
private struct TrailingDateNoticeRow: View {
    let notice: NewsNotice
    let isLast: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                HStack(alignment: .firstTextBaseline, spacing: PumTokens.Space.s8) {
                    Text(notice.title).pumText(.callout, weight: .semibold).foregroundStyle(PumColor.textPrimary)
                    Spacer(minLength: PumTokens.Space.s8)
                    Text(notice.date).pumText(.caption).foregroundStyle(PumTokens.ColorToken.gray500)
                }
                Text(notice.author + (notice.isRead ? " · 읽음" : "")).pumText(.caption).foregroundStyle(PumColor.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
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
        .accessibilityLabel(Text("\(notice.isRead ? "읽은 공지" : "안 읽은 공지"), \(notice.title), \(notice.author), \(notice.date)"))
        .accessibilityHint(Text("공지를 열어요"))
    }
}

/// 15d 알림 행 — 제목 오른쪽에 시각, 아래 사업장 이름
private struct SourceAlertRow: View {
    let alert: NewsAlert
    let isLast: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
            HStack(alignment: .firstTextBaseline, spacing: PumTokens.Space.s8) {
                Text(alert.message).pumText(.callout, weight: .semibold).foregroundStyle(PumColor.textPrimary)
                Spacer(minLength: PumTokens.Space.s8)
                Text(alert.time).pumText(.caption).foregroundStyle(PumTokens.ColorToken.gray500)
            }
            if let source = alert.source {
                Text(source).pumText(.caption).foregroundStyle(PumColor.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, PumTokens.Size.rowPadY)
        .padding(.horizontal, PumTokens.Size.rowPadX)
        .overlay(alignment: .bottom) {
            if !isLast { Rectangle().fill(PumColor.borderHairline).frame(height: 1) }
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview("소식 3a") { NewsFeedView() }
#Preview("소식 빈 상태") { NewsFeedView(state: .empty(workplaceName: "종민김밥 본점", workplaceInitial: "종")) }
#Preview("소식 15d 초대") { NewsFeedView(state: .withInvite) }
