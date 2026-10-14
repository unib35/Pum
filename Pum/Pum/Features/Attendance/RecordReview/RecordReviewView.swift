// UI-IOS-1ae · REQ-044 · DEC-005 — 근무기록 확인 요청 받음(직원). 사장님이 급여 확정 전에 보낸 요청. 탭 바 없음.
// 「살펴볼 기록」이 남아 있어도 확인 완료를 막지 않는다(디자인에 비활성 표시 없음).
// 수정 요청 · 확인 완료 · 행 누름 · 더 보기는 클로저만(연결 후속).
import SwiftUI

struct RecordReviewView: View {
    var state: RecordReviewState = .sample
    var onBack: () -> Void = {}
    var onRequestEdit: () -> Void = {}
    var onConfirm: () -> Void = {}
    var onSelectRow: (ReviewRow) -> Void = { _ in }
    var onShowMore: () -> Void = {}

    // 화면 전용 상수 — 토큰에 없는 값(DEC-005)
    private enum Local {
        /// 날짜 칸 고정 폭(요일 + 숫자) — 1j와 같은 값
        static let dateColumnWidth: CGFloat = 40
        /// 사장님 메시지 인용 막대 폭 약 3
        static let quoteBarWidth: CGFloat = 3
        /// 요약 3칸이 한 줄에 안 들어가면 세로로 쌓을 때의 간격
        static let summaryStackSpacing: CGFloat = PumTokens.Space.s12
    }

    var body: some View {
        VStack(spacing: 0) {
            PumNavHeader(title: "근무기록 확인", onBack: onBack)
                .padding(.horizontal, PumTokens.Size.screenPad)
            ScrollView {
                VStack(alignment: .leading, spacing: PumTokens.Space.s14) {
                    heading
                    messageCard
                    summaryCard
                    recordsCard
                }
                .padding(.horizontal, PumTokens.Size.screenPad)
                .padding(.vertical, PumTokens.Space.s14)
            }
        }
        .background(PumColor.bgApp)
        .safeAreaInset(edge: .bottom, spacing: 0) { actions }
    }

    // 2. 제목 · 부제
    private var heading: some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s6) {
            // 28px 700 → title1, 원문대로 두 줄로 끊는다(줄바꿈 문자)
            Text(state.titleLines.joined(separator: "\n")).pumText(.title1).foregroundStyle(PumColor.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text(state.titleText))
                .accessibilityAddTraits(.isHeader)
            subtitle
        }
    }

    /// 14px: 앞뒤 보조색 400, 기한만 주황 700 → callout(14) 굵기 바꿈
    private var subtitle: some View {
        var prefix = AttributedString(state.subtitlePrefix)
        prefix.foregroundColor = PumColor.textSecondary
        var deadline = AttributedString(state.deadlineText)
        deadline.foregroundColor = PumColor.statusAttention
        deadline.font = PumFont.font(size: PumTokens.FontToken.callout.size, weight: .bold, relativeTo: .callout)
        var suffix = AttributedString(RecordReviewState.deadlineSuffix)
        suffix.foregroundColor = PumColor.textSecondary
        return Text(prefix + deadline + suffix)
            .pumText(.callout, weight: .regular)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(state.subtitleText))
    }

    // 3. 사장님 메시지 카드(인용)
    private var messageCard: some View {
        PumCard(radius: PumTokens.Radius.md) {
            // 원문: 안쪽 위아래 12 · 왼쪽 20 · 오른쪽 16, 인용 막대는 왼쪽 끝에서 위아래 12 띄움
            Text(state.ownerMessage).pumText(.footnote, weight: .regular) // 13px
                .foregroundStyle(PumTokens.ColorToken.gray800) // #3A4150
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, PumTokens.Space.s12)
                .padding(.leading, PumTokens.Space.s20)
                .padding(.trailing, PumTokens.Space.s16)
                .overlay(alignment: .leading) {
                    RoundedRectangle(cornerRadius: PumTokens.Space.s2, style: .continuous)
                        .fill(PumTokens.ColorToken.gray300) // 인용 막대: gray300 계열
                        .frame(width: Local.quoteBarWidth)
                        .padding(.vertical, PumTokens.Space.s12)
                        .accessibilityHidden(true)
                }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(state.messageAccessibilityText))
        }
    }

    // 4. 요약 카드
    private var summaryCard: some View {
        PumCard {
            VStack(spacing: 0) {
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .top, spacing: PumTokens.Space.s8) {
                        stat(RecordReviewState.daysLabel, state.daysText, color: PumColor.textPrimary, oneLine: true)
                        stat(RecordReviewState.recognizedLabel, state.recognizedText, color: PumColor.textPrimary, oneLine: true)
                        stat(RecordReviewState.payLabel, state.payText, color: PumColor.statusDone, oneLine: true)
                    }
                    VStack(alignment: .leading, spacing: Local.summaryStackSpacing) {
                        stat(RecordReviewState.daysLabel, state.daysText, color: PumColor.textPrimary, oneLine: false)
                        stat(RecordReviewState.recognizedLabel, state.recognizedText, color: PumColor.textPrimary, oneLine: false)
                        stat(RecordReviewState.payLabel, state.payText, color: PumColor.statusDone, oneLine: false)
                    }
                }
                Rectangle().fill(PumColor.borderHairline).frame(height: 1) // 원문: 안쪽 18에서 시작
                    .padding(.top, PumTokens.Space.s12)
                countsLine
                    .padding(.top, PumTokens.Space.s12)
            }
            .padding(.vertical, PumTokens.Space.s16)
            .padding(.horizontal, PumTokens.Space.s18)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(state.summaryAccessibilityText))
        }
    }

    private func stat(_ label: String, _ value: String, color: Color, oneLine: Bool) -> some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
            Text(label).pumText(.caption2, weight: .regular).foregroundStyle(PumColor.textSecondary) // 11px
            Text(value).pumText(.headline, weight: .bold).foregroundStyle(color) // 17px 700
                .lineLimit(oneLine ? 1 : nil)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var countsLine: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: PumTokens.Space.s8) {
                counts
                Spacer(minLength: PumTokens.Space.s8)
                attention
            }
            VStack(alignment: .leading, spacing: PumTokens.Space.s4) {
                counts
                attention
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var counts: some View {
        var lead = AttributedString(state.countLead); lead.foregroundColor = PumColor.textSecondary
        var normal = AttributedString(state.normalText); normal.foregroundColor = PumColor.textPrimary
        normal.font = PumFont.font(size: PumTokens.FontToken.caption.size, weight: .bold, relativeTo: .caption)
        return Text(lead + normal).pumText(.caption, weight: .regular) // 12px
    }

    @ViewBuilder private var attention: some View {
        if let text = state.attentionText {
            Text(text).pumText(.caption, weight: .semibold).foregroundStyle(PumColor.statusAttention) // 12px 600 주황
        }
    }

    // 5. 기록 카드
    private var recordsCard: some View {
        PumCard {
            ForEach(state.rows) { row in
                recordRow(row)
            }
            if let more = state.moreText {
                Button(action: onShowMore) {
                    Text(more).pumText(.footnote, weight: .regular).foregroundStyle(PumColor.textSecondary) // 13px
                        .frame(maxWidth: .infinity, minHeight: PumTokens.Size.tapMin)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func recordRow(_ row: ReviewRow) -> some View {
        Button { onSelectRow(row) } label: {
            HStack(spacing: PumTokens.Space.s12) {
                dateColumn(row)
                VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                    Text(row.titleText).pumText(.callout).foregroundStyle(PumColor.textPrimary) // 14px 600
                    Text(row.detailText).pumText(.caption, weight: .regular).foregroundStyle(PumColor.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                trailing(row)
            }
            .padding(.vertical, PumTokens.Size.rowPadY)
            .padding(.horizontal, PumTokens.Size.rowPadX)
            .frame(minHeight: PumTokens.Size.tapMin)
            // 살펴볼 행 바탕: 원문은 아주 연한 주황 — 가장 가까운 토큰 statusAttentionSoft(원문보다 약간 진함, DEC-005)
            .background(row.isAttention ? PumColor.statusAttentionSoft : .clear)
            .contentShape(Rectangle())
            .overlay(alignment: .bottom) {
                Rectangle().fill(PumColor.borderHairline).frame(height: 1) // 행 사이 hairline 전폭
            }
        }
        .buttonStyle(.plain)
        // 원문은 살펴볼 행에만 「확인 ›」 — 확정 행은 누를 곳이 없어 버튼으로 두지 않는다(QA)
        .allowsHitTesting(row.isAttention)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(row.accessibilityText))
        .accessibilityRemoveTraits(row.isAttention ? [] : .isButton)
    }

    private func dateColumn(_ row: ReviewRow) -> some View {
        VStack(spacing: PumTokens.Space.s2) {
            Text(row.weekday).pumText(.caption2, weight: .regular).foregroundStyle(PumColor.textSecondary) // 11px
            Text("\(row.day)").pumText(.headline, weight: .bold).foregroundStyle(PumColor.textPrimary) // 16px 700 → headline(17)
        }
        .frame(minWidth: Local.dateColumnWidth)
    }

    /// 오른쪽: 살펴볼 행 「확인 ›」 주황, 확정 행 「확정」 초록(글자만)
    @ViewBuilder private func trailing(_ row: ReviewRow) -> some View {
        if row.isAttention {
            HStack(spacing: PumTokens.Space.s2) {
                Text(row.trailingText)
                Image(systemName: "chevron.right").font(.caption2.weight(.semibold)).accessibilityHidden(true)
            }
            .pumText(.caption, weight: .semibold).foregroundStyle(PumColor.statusAttention)
        } else {
            Text(row.trailingText).pumText(.caption, weight: .semibold).foregroundStyle(PumColor.statusDone)
        }
    }

    // 6. 하단 고정 두 버튼 (비율 1 : 1.5 ≈ 원문 1 : 1.4, 큰 글자 대응은 공통 부품)
    private var actions: some View {
        PumButtonPair(negative: "수정 요청", positive: "이상 없어요 \u{00B7} 확인 완료", negativeKind: .outline,
                      onNegative: onRequestEdit, onPositive: onConfirm)
            .padding(.horizontal, PumTokens.Size.screenPad)
            .padding(.top, PumTokens.Space.s12)
            .padding(.bottom, PumTokens.Space.s10) // 원문 아래 44 − 홈 막대 34
            .background(PumColor.bgApp)
    }
}

#Preview("1ae") { RecordReviewView() }
#Preview("1ae · 큰 글자") { RecordReviewView().dynamicTypeSize(.xxxLarge) }
#Preview("1ae · 살펴볼 것 없음") {
    var s = RecordReviewState.sample
    s.attentionCount = 0
    s.normalCount = 17
    s.rows.removeFirst()
    return RecordReviewView(state: s)
}
