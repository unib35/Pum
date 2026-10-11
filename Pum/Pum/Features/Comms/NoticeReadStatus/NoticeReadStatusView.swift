// UI-IOS-3d · REQ-040 — 사장님 공지 확인 현황(확정). 탭 바 없음. 읽음 / 미확인 · 미확인 직원에게 다시 알림.
// 버튼은 클로저로만(onBack · onMore · onCall · onRemind · onOpenRecruitment). 재알림 처리 중 · 결과 디자인은 없어 만들지 않았다.
import SwiftUI

struct NoticeReadStatusView: View {
    var state: NoticeReadStatusState = .sample
    var onBack: () -> Void = {}
    var onMore: () -> Void = {}
    var onCall: (NoticeUnreadPerson) -> Void = { _ in }
    var onRemind: () -> Void = {}
    var onOpenRecruitment: () -> Void = {}

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric private var barHeight = PumTokens.Space.s8 // 원문 진행 막대 높이 약 8pt

    var body: some View {
        VStack(spacing: 0) {
            PumNavHeader(title: "공지", onBack: onBack) {
                PumIconButton(systemImage: "ellipsis", label: "더보기", action: onMore)
            }
            .padding(.horizontal, PumTokens.Size.screenPad)
            ScrollView {
                VStack(alignment: .leading, spacing: PumTokens.Space.s16) {
                    header
                    progressCard
                    if !state.unread.isEmpty { unreadSection }
                    if !state.read.isEmpty { readSection }
                    if let rec = state.recruitment { recruitmentCard(rec) }
                }
                .padding(.horizontal, PumTokens.Size.screenPad)
                .padding(.vertical, PumTokens.Space.s16)
            }
            if let title = state.remindTitle {
                PumButton(title: title, kind: .dark, action: onRemind)
                    .padding(.horizontal, PumTokens.Size.screenPad)
                    .padding(.top, PumTokens.Space.s8)
                    .padding(.bottom, PumTokens.Space.s12)
            }
        }
        .background(PumColor.bgApp)
    }

    // 2. 배지 · 시각 · 제목
    private var header: some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s10) {
            HStack(spacing: PumTokens.Space.s8) {
                // 공통 후보: 11px 700 알약 배지(PumBadge는 12px 600) — 3b와 같은 값
                Text("공지")
                    .pumText(.caption2, weight: .bold)
                    .foregroundStyle(PumColor.accent)
                    .padding(.vertical, PumTokens.Space.s4)
                    .padding(.horizontal, PumTokens.Space.s8)
                    .background(PumColor.accentSoftStrong, in: RoundedRectangle(cornerRadius: PumTokens.Radius.sm, style: .continuous))
                Text(state.metaText).pumText(.caption).foregroundStyle(PumColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Text(state.title)
                .pumText(.title3) // 원문 22px 700 → 토큰 단계 20px(title3) — 3b와 같은 근사
                .foregroundStyle(PumColor.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, PumTokens.Space.s4)
    }

    // 3. 확인 현황 카드
    private var progressCard: some View {
        PumCard {
            VStack(spacing: PumTokens.Space.s12) {
                HStack(alignment: .firstTextBaseline) {
                    Text("확인 현황").pumText(.callout, weight: .bold).foregroundStyle(PumColor.textPrimary)
                    Spacer(minLength: PumTokens.Space.s8)
                    HStack(alignment: .firstTextBaseline, spacing: 0) { // 원문: 「3」과 「/ 5」 사이는 띄어쓰기 하나
                        Text("\(state.readCount)").pumText(.title2).foregroundStyle(PumColor.textPrimary) // 원문 큰 숫자 → title2 24px 근사
                        Text(" / \(state.totalCount)").pumText(.footnote, weight: .medium).foregroundStyle(PumColor.textSecondary)
                    }
                }
                bar
            }
            .padding(PumTokens.Space.s20)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("확인 현황, \(state.progressAccessibilityText)"))
    }

    private var bar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(PumColor.surfaceFill)
                Capsule().fill(PumColor.statusDone)
                    .frame(width: geo.size.width * state.progress)
                    .animation(PumMotion.respecting(reduceMotion, PumMotion.progress), value: state.progress) // M22
            }
        }
        .frame(height: barHeight)
    }

    // 4. 미확인
    private var unreadSection: some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s8) {
            PumSectionHeader(title: state.unreadHeaderText, attention: true)
            PumCard {
                ForEach(Array(state.unread.enumerated()), id: \.element.id) { i, p in
                    if i > 0 { divider }
                    unreadRow(p)
                }
            }
        }
    }

    private func unreadRow(_ p: NoticeUnreadPerson) -> some View {
        HStack(spacing: PumTokens.Space.s12) {
            PumAvatar(name: p.name, colorIndex: p.colorIndex)
            VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                Text(p.name).pumText(.body, weight: .semibold).foregroundStyle(PumColor.textPrimary)
                Text(p.detailText).pumText(.caption).foregroundStyle(PumColor.textSecondary)
            }
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text("\(p.name), \(p.detailText.replacingOccurrences(of: " · ", with: ", "))"))
            Spacer(minLength: PumTokens.Space.s8)
            if p.canCall {
                // 공통 후보: 원형 회색 아이콘 버튼(PumIconButton은 흰 바탕). 보이는 크기 36pt(아바타와 같은 값), 터치는 44pt.
                Button { onCall(p) } label: {
                    Image(systemName: "phone")
                        .font(.system(size: PumLayout.navIcon - PumTokens.Space.s2, weight: .medium))
                        .foregroundStyle(PumColor.textPrimary)
                        .frame(width: PumLayout.avatar, height: PumLayout.avatar)
                        .background(PumColor.surfaceFill, in: Circle())
                        .frame(width: PumTokens.Size.tapMin, height: PumTokens.Size.tapMin)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text("\(p.name)에게 전화"))
            }
        }
        .padding(.horizontal, PumTokens.Size.rowPadX)
        .padding(.vertical, PumTokens.Space.s12)
    }

    // 5. 확인
    private var readSection: some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s8) {
            PumSectionHeader(title: state.readHeaderText)
            PumCard {
                ForEach(Array(state.read.enumerated()), id: \.element.id) { i, p in
                    if i > 0 { divider }
                    readRow(p)
                }
            }
        }
    }

    private func readRow(_ p: NoticeReadPerson) -> some View {
        HStack(spacing: PumTokens.Space.s12) {
            PumAvatar(name: p.name, colorIndex: p.colorIndex, size: PumLayout.avatar - PumTokens.Space.s2) // 원문 약 32pt → 34 근사
            Text(p.name).pumText(.callout, weight: .medium).foregroundStyle(PumColor.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: PumTokens.Space.s8)
            Text(p.readAtText).pumText(.caption, weight: .semibold).foregroundStyle(PumColor.statusDone)
        }
        .padding(.horizontal, PumTokens.Size.rowPadX)
        .padding(.vertical, PumTokens.Size.rowPadY)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("\(p.name), \(p.readAtText) 확인"))
    }

    // 6. 연결된 근무 모집
    private func recruitmentCard(_ r: NoticeLinkedRecruitment) -> some View {
        Button(action: onOpenRecruitment) {
            PumCard {
                HStack(spacing: PumTokens.Space.s8) {
                    VStack(alignment: .leading, spacing: PumTokens.Space.s4) {
                        Text("연결된 근무 모집").pumText(.footnote, weight: .bold).foregroundStyle(PumColor.textSecondary)
                        (Text(r.prefixText).foregroundStyle(PumColor.textPrimary)
                            + Text(r.confirmedText).foregroundStyle(PumColor.statusDone)
                            + Text(r.suffixText).foregroundStyle(PumColor.textPrimary))
                            .pumText(.callout)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: PumTokens.Space.s8)
                    Image(systemName: "chevron.right").font(.callout.weight(.semibold)).foregroundStyle(PumColor.textTertiary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(PumTokens.Space.s16)
                .frame(minHeight: PumTokens.Size.tapMin)
            }
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(r.accessibilityText))
        .accessibilityAddTraits(.isButton)
    }

    private var divider: some View {
        Rectangle().fill(PumColor.borderHairline).frame(height: 1)
    }
}

#Preview("3d") { NoticeReadStatusView() }
#Preview("3d · 큰 글자") { NoticeReadStatusView().dynamicTypeSize(.xxxLarge) }
#Preview("3d · 모집 없음") {
    NoticeReadStatusView(state: { var s = NoticeReadStatusState.sample; s.recruitment = nil; return s }())
}
#Preview("3d · 미확인 없음") {
    NoticeReadStatusView(state: { var s = NoticeReadStatusState.sample; s.unread = []; s.readCount = 5; return s }())
}
