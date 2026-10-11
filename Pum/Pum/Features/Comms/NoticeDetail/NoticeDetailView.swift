// UI-IOS-3b · REQ-040 — 직원 공지 상세(확정). 탭 바 없음. 공지는 읽으면 끝, 근무 모집은 별도 카드(공지에 수락 버튼 없음).
// 버튼은 클로저로만(onBack · onApply · onDecline). 읽음 처리는 화면이 보일 때 onRead(서버 연결은 후속). 처리 중 · 결과 디자인은 없어 만들지 않았다.
import SwiftUI

struct NoticeDetailView: View {
    var state: NoticeDetailState = .sample
    var onBack: () -> Void = {}
    var onApply: () -> Void = {}
    var onDecline: () -> Void = {}
    /// 화면이 보이면 읽음 처리(screen-index 3b 「읽음 처리」) — 읽음 시각은 서버 값으로 다시 받는다
    var onRead: () -> Void = {}

    @Environment(\.dynamicTypeSize) private var typeSize

    /// 본문 색 #3A4150 = 토큰 gray800(값 일치)
    private let bodyColor = PumTokens.ColorToken.gray800
    /// 본문 줄 간격: 원문 15px 글자에 줄 높이 약 25px → 기본 줄 높이(1.5) 위에 더하는 값. 토큰 밖이라 Space s2로 근사.
    private let bodyLineSpacing = PumTokens.Space.s2

    var body: some View {
        VStack(spacing: 0) {
            PumNavHeader(title: "공지", onBack: onBack)
                .padding(.horizontal, PumTokens.Size.screenPad)
            ScrollView {
                VStack(alignment: .leading, spacing: PumTokens.Space.s16) {
                    noticeCard
                    if let rec = state.recruitment {
                        requestSection(rec)
                    }
                }
                .padding(.horizontal, PumTokens.Size.screenPad)
                .padding(.vertical, PumTokens.Space.s16)
            }
        }
        .background(PumColor.bgApp)
        .onAppear(perform: onRead)
    }

    // 2. 본문 카드
    private var noticeCard: some View {
        PumCard {
            VStack(alignment: .leading, spacing: PumTokens.Space.s14) {
                badges
                Text(state.title)
                    .pumText(.title3) // 원문 22px 700 → 토큰 단계 20px(title3)·24px(title2) 중 줄바꿈 여유가 있는 title3
                    .foregroundStyle(PumColor.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
                author
                divider
                bodyText
                divider
                readStatus
            }
            .padding(PumTokens.Space.s20)
        }
    }

    private var badges: some View {
        HStack(spacing: PumTokens.Space.s6) {
            // 공통 후보: 11px 700 알약 배지(PumBadge는 12px 600). 공지 = 파랑, 대상 = 회색
            pill("공지", fg: PumColor.accent, bg: PumColor.accentSoftStrong, weight: .bold)
            pill(state.audienceLabel, fg: PumTokens.ColorToken.gray700, bg: PumColor.surfaceFill, weight: .semibold)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("공지, \(state.audienceLabel)"))
    }

    private func pill(_ text: String, fg: Color, bg: Color, weight: Font.Weight) -> some View {
        Text(text)
            .pumText(.caption2, weight: weight) // 11px
            .foregroundStyle(fg)
            .padding(.vertical, PumTokens.Space.s4)
            .padding(.horizontal, PumTokens.Space.s8)
            .background(bg, in: RoundedRectangle(cornerRadius: PumTokens.Radius.sm, style: .continuous))
    }

    private var author: some View {
        HStack(spacing: PumTokens.Space.s12) {
            // 먹색 원 + 흰 글자(팔레트 먹색 항목 = index 5). 원문 지름 32pt → 공통 아바타 36pt 근사
            PumAvatar(name: state.authorName, colorIndex: 5)
            VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                Text(state.authorName).pumText(.footnote, weight: .semibold).foregroundStyle(PumColor.textPrimary)
                Text(state.postedAtText).pumText(.caption).foregroundStyle(PumColor.textSecondary)
            }
            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("\(state.authorName), \(state.postedAtText)"))
    }

    private var divider: some View {
        Rectangle().fill(PumColor.borderHairline).frame(height: 1)
    }

    /// 본문은 한 Text로 이어 붙인다 — 줄 사이 간격이 날짜 줄에도 똑같이 들어가고, 문단 사이는 원문처럼 빈 줄 하나
    private var bodyText: some View {
        let paragraphs = state.paragraphs.compactMap { p in
            p.lines.map(lineText).reduce(nil as Text?) { acc, t in acc.map { $0 + Text("\n") + t } ?? t }
        }
        let joined = paragraphs.reduce(nil as Text?) { acc, t in acc.map { $0 + Text("\n\n") + t } ?? t } ?? Text("")
        return joined
            .pumText(.body, weight: .regular) // 15px
            .lineSpacing(bodyLineSpacing)
            .foregroundStyle(bodyColor)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityLabel(Text(state.bodyAccessibilityText))
    }

    private func lineText(_ line: NoticeBodyLine) -> Text {
        let strong = line.strong.map { Text($0).fontWeight(.bold) } ?? Text("")
        return strong + Text(line.text)
    }

    private var readStatus: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .firstTextBaseline) {
                Text(state.readStatusText).pumText(.caption).foregroundStyle(PumColor.textSecondary)
                Spacer(minLength: PumTokens.Space.s8)
                mine
            }
            VStack(alignment: .leading, spacing: PumTokens.Space.s4) {
                Text(state.readStatusText).pumText(.caption).foregroundStyle(PumColor.textSecondary)
                mine
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("\(state.readStatusText), \(state.myReadText.replacingOccurrences(of: " · ", with: ", "))"))
    }

    private var mine: some View {
        Text(state.myReadText).pumText(.caption, weight: .semibold).foregroundStyle(PumColor.statusDone) // #2F7D5B = statusDone
    }

    // 3~5. 연결된 요청
    private func requestSection(_ rec: NoticeRecruitment) -> some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s8) {
            PumSectionHeader(title: "이 공지와 연결된 요청")
            recruitCard(rec)
            Text("공지는 읽기만 하면 돼요. 근무 신청은 별도 요청으로 처리되어 수락 시 스케줄에 추가돼요.")
                .pumText(.caption).foregroundStyle(PumColor.textSecondary)
                .padding(.horizontal, PumTokens.Space.s4)
                .padding(.top, PumTokens.Space.s8) // 원문: 카드와 안내 사이 약 16
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func recruitCard(_ rec: NoticeRecruitment) -> some View {
        PumCard(attention: true) {
            VStack(alignment: .leading, spacing: PumTokens.Space.s6) {
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .center) {
                        recruitBadge
                        Spacer(minLength: PumTokens.Space.s8)
                        count(rec)
                    }
                    VStack(alignment: .leading, spacing: PumTokens.Space.s4) {
                        recruitBadge
                        count(rec)
                    }
                }
                Text(rec.dateTimeText).pumText(.body, weight: .semibold).foregroundStyle(PumColor.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                Text(rec.detailText).pumText(.caption).foregroundStyle(PumColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                buttons
                    .padding(.top, PumTokens.Space.s6)
            }
            .padding(PumTokens.Space.s16)
        }
        .accessibilityElement(children: .contain)
    }

    // 공통 후보: 주황 11px 700 배지(PumBadge.attention은 12px 600)
    private var recruitBadge: some View {
        pill("근무 모집", fg: PumColor.statusAttention, bg: PumColor.statusAttentionSoft, weight: .bold)
    }

    private func count(_ rec: NoticeRecruitment) -> some View {
        Text(rec.countText).pumText(.caption).foregroundStyle(PumColor.textSecondary)
    }

    /// 어려워요(왼쪽 좁음) · 근무 신청 — 공통 PAIR 비율 1 : 1.5. 접근성 글자 크기에서는 세로로 쌓는다.
    @ViewBuilder private var buttons: some View {
        if typeSize.isAccessibilitySize {
            VStack(spacing: PumTokens.Space.s8) {
                PumButton(title: "근무 신청", kind: .primary, size: .small, action: onApply)
                PumButton(title: "어려워요", kind: .outline, size: .small, action: onDecline)
            }
        } else {
            PumButtonPair(negative: "어려워요", positive: "근무 신청", negativeKind: .outline, size: .small,
                          onNegative: onDecline, onPositive: onApply)
        }
    }
}

#Preview("3b") { NoticeDetailView() }
#Preview("3b · 큰 글자") { NoticeDetailView().dynamicTypeSize(.xxxLarge) }
#Preview("3b · 모집 없음") {
    NoticeDetailView(state: { var s = NoticeDetailState.sample; s.recruitment = nil; return s }())
}
