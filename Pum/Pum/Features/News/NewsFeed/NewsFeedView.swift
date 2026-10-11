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
            VStack(alignment: .leading, spacing: PumTokens.Space.s20) {
                header
                NewsFilterBar(selection: $filter, noticeCount: state.unreadNoticeCount, requestCount: state.requestCount)
                if state.shows(.request, under: filter), !state.requests.isEmpty { requestSection }
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
        .padding(.top, PumTokens.Space.s8)
    }

    private var title: some View {
        Text("소식").pumText(.title1).foregroundStyle(PumColor.textPrimary)
            .accessibilityAddTraits(.isHeader)
    }

    private var chip: some View {
        PumWorkplaceChip(name: state.workplaceName, initial: state.workplaceInitial, action: onOpenWorkplaceSwitcher)
    }

    // MARK: 섹션

    private var requestSection: some View {
        VStack(spacing: PumTokens.Space.s8) {
            PumSectionHeader(title: "결정이 필요해요", attention: true)
            ForEach(state.requests) { request in
                switch request {
                case .extraShift(let r): ExtraShiftCard(request: r, onAccept: { onAccept(r) }, onDecline: { onDecline(r) })
                case .contractSign(let r): ContractSignCard(request: r) { onOpenContract(r) }
                }
            }
        }
    }

    private var noticeSection: some View {
        VStack(spacing: PumTokens.Space.s8) {
            PumSectionHeader(title: "공지")
            PumCard {
                ForEach(Array(state.notices.enumerated()), id: \.element.id) { index, notice in
                    NoticeRow(notice: notice, isLast: index == state.notices.count - 1) { onOpenNotice(notice) }
                }
            }
        }
    }

    private var alertSection: some View {
        VStack(spacing: PumTokens.Space.s8) {
            PumSectionHeader(title: "알림")
            PumCard {
                ForEach(Array(state.alerts.enumerated()), id: \.element.id) { index, alert in
                    AlertRow(alert: alert, isLast: index == state.alerts.count - 1)
                }
            }
        }
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
                    .frame(maxWidth: .infinity, minHeight: PumTokens.Size.tapMin - PumTokens.Space.s8)
                    .background {
                        if selected {
                            RoundedRectangle(cornerRadius: PumTokens.Radius.md, style: .continuous).fill(PumColor.surfaceCard)
                        }
                    }
                    .contentShape(Rectangle())
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
                PumButtonPair(negative: "어려워요", positive: "근무 가능해요", negativeKind: .outline,
                              onNegative: onDecline, onPositive: onAccept)
                    .padding(.top, PumTokens.Space.s4)
            }
            .padding(PumTokens.Space.s16)
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
                .padding(PumTokens.Space.s16)
                .frame(minHeight: PumTokens.Size.tapMin)
            }
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityHint(Text("계약서를 열어요"))
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
                VStack(alignment: .leading, spacing: PumTokens.Space.s4) {
                    Text(notice.title)
                        .pumText(.body, weight: notice.isRead ? .semibold : .bold)
                        .foregroundStyle(notice.isRead ? PumTokens.ColorToken.gray700 : PumColor.textPrimary)
                    if let body = notice.body {
                        Text(body).pumText(.footnote).foregroundStyle(PumTokens.ColorToken.gray800)
                            .lineLimit(2)
                    }
                    meta
                }
                .frame(maxWidth: .infinity, alignment: .leading)
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
        .accessibilityLabel(Text(accessibilityText))
        .accessibilityHint(Text("공지를 열어요"))
    }

    private var meta: some View {
        let base = "\(notice.author) · \(notice.date)"
        return Group {
            if let link = notice.linkLabel {
                Text(base + " · ").foregroundStyle(PumColor.textSecondary)
                    + Text(link).fontWeight(.semibold).foregroundStyle(PumColor.accent)
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

#Preview("소식 3a") { NewsFeedView() }
#Preview("소식 빈 상태") { NewsFeedView(state: .empty(workplaceName: "종민김밥 본점", workplaceInitial: "종")) }
