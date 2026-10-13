// UI-IOS-20l · REQ-007 · DEC-001 — 초대 수락 후 직원 앱: 앱 연결 전 기록은 「사업주 입력」으로 이어받음 · 다르면 이의 제기.
// 탭 바 없음(하위 화면). 값은 모두 서버 값, 동작은 클로저로만 알린다. 하단 버튼 없음.
import SwiftUI

struct InheritedRecordsView: View {
    @Environment(\.dynamicTypeSize) private var typeSize
    let state: InheritedRecordsState

    var onBack: () -> Void = {}
    /// 월 행 — 월 id
    var onOpenMonth: (String) -> Void = { _ in }
    /// 「10월 12일 부터」 카드
    var onOpenAppRecords: () -> Void = {}
    /// 「이의 제기」 — 기록 수정 요청과 같은 경로
    var onDispute: () -> Void = {}

    var body: some View {
        VStack(spacing: 0) {
            backRow
            ScrollView {
                VStack(alignment: .leading, spacing: PumTokens.Space.s14) {
                    header
                    if state.showsMonthCard { monthCard }
                    appRecordsCard
                    disputeCard
                }
                .padding(.horizontal, PumTokens.Size.screenPad)
                .padding(.vertical, PumTokens.Space.s12)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .background(PumColor.bgApp)
    }

    // MARK: 머리

    private var backRow: some View {
        HStack {
            Button(action: onBack) {
                HStack(spacing: PumTokens.Space.s4) {
                    Image(systemName: "chevron.left").pumText(.headline, weight: .semibold)
                    Text(InheritedRecordsState.backTitle).pumText(.headline, weight: .semibold)
                }
                .foregroundStyle(PumColor.textPrimary)
                .frame(minWidth: PumTokens.Size.tapMin, minHeight: PumTokens.Size.tapMin, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(InheritedRecordsState.backTitle))
            Spacer()
        }
        .padding(.horizontal, PumTokens.Size.screenPad)
        .padding(.top, PumTokens.Space.s8)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(state.workplaceName).pumText(.footnote, weight: .medium).foregroundStyle(PumColor.textSecondary)
            Text(state.title).pumText(.title2).foregroundStyle(PumColor.textPrimary)
                .padding(.top, PumTokens.Space.s4)
                .accessibilityAddTraits(.isHeader)
            Text(state.subtitle).pumText(.footnote).foregroundStyle(PumColor.textSecondary)
                .padding(.top, PumTokens.Space.s2) // 원문 위 3
        }
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, PumTokens.Space.s4)
    }

    // MARK: 카드

    private var monthCard: some View {
        PumCard {
            ForEach(Array(state.months.enumerated()), id: \.element.id) { i, month in
                if i > 0 { Divider().overlay(PumColor.borderHairline) }
                monthRow(month)
            }
        }
    }

    private func monthRow(_ month: InheritedMonth) -> some View {
        Button { onOpenMonth(month.id) } label: {
            // 행마다 따로 판정하면 큰 글자에서 행 모양이 섞인다 — 글자 크기 하나로 카드 전체를 같이 바꾼다
            Group {
                if typeSize >= .xxxLarge {
                    VStack(alignment: .leading, spacing: PumTokens.Space.s6) {
                        texts(title: month.title, detail: month.detail)
                        HStack(spacing: PumTokens.Space.s12) { ownerBadge; Spacer(minLength: 0); chevron }
                    }
                } else {
                    HStack(spacing: PumTokens.Space.s12) {
                        texts(title: month.title, detail: month.detail)
                        ownerBadge.fixedSize()
                        chevron
                    }
                }
            }
            .padding(.horizontal, PumTokens.Size.rowPadX)
            .padding(.vertical, PumTokens.Space.s12)
            .frame(maxWidth: .infinity, minHeight: PumTokens.Size.tapMin, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(month.readout))
        .accessibilityAddTraits(.isButton)
    }

    private var appRecordsCard: some View {
        PumCard {
            Button(action: onOpenAppRecords) {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: PumTokens.Space.s12) {
                        texts(title: state.appRecordsTitle, detail: InheritedRecordsState.appRecordsDetail)
                        PumBadge(text: InheritedRecordsState.appRecordsBadge, kind: .done).accessibilityHidden(true)
                    }
                    VStack(alignment: .leading, spacing: PumTokens.Space.s6) {
                        texts(title: state.appRecordsTitle, detail: InheritedRecordsState.appRecordsDetail)
                        PumBadge(text: InheritedRecordsState.appRecordsBadge, kind: .done).accessibilityHidden(true)
                    }
                }
                .padding(.horizontal, PumTokens.Size.rowPadX)
                .padding(.vertical, PumTokens.Space.s12) // 원문 padding 12 16
                .frame(maxWidth: .infinity, minHeight: PumTokens.Size.tapMin, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(state.appRecordsReadout))
            .accessibilityAddTraits(.isButton)
        }
    }

    private var disputeCard: some View {
        PumCard {
            // 원문: 설명은 줄바꿈하고 칩은 오른쪽에 둔다 — 큰 글자(접근성 크기)에서만 칩을 아래로
            Group {
                if typeSize.isAccessibilitySize {
                    VStack(alignment: .leading, spacing: PumTokens.Space.s8) {
                        texts(title: InheritedRecordsState.disputeTitle, detail: InheritedRecordsState.disputeDetail)
                        disputeChip
                    }
                } else {
                    HStack(spacing: PumTokens.Space.s12) {
                        texts(title: InheritedRecordsState.disputeTitle, detail: InheritedRecordsState.disputeDetail)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        disputeChip.fixedSize()
                    }
                }
            }
            .padding(.horizontal, PumTokens.Size.rowPadX)
            .padding(.vertical, PumTokens.Space.s12) // 원문 padding 12 16
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    /// 회색 칩 — 보이는 모양은 그대로, 누름 영역만 배경 뒤에서 44pt로 키운다(20g 「확인」 칩과 같은 값)
    private var disputeChip: some View {
        Button(action: onDispute) {
            Text(InheritedRecordsState.disputeButton)
                .pumText(.caption, weight: .bold)
                .foregroundStyle(PumColor.textPrimary)
                .padding(.horizontal, PumTokens.Space.s10)
                .padding(.vertical, PumTokens.Space.s6)
                .background(PumColor.surfaceFill,
                            in: RoundedRectangle(cornerRadius: PumTokens.Radius.sm, style: .continuous))
                // 누름 영역만 44 이상으로 키우고, 배치에는 원문 칩 크기만 쓴다(카드 높이가 늘지 않게)
                .padding(.vertical, PumTokens.Space.s12)
                .padding(.horizontal, PumTokens.Space.s4)
                .contentShape(Rectangle())
                .padding(.vertical, -PumTokens.Space.s12)
                .padding(.horizontal, -PumTokens.Space.s4)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(InheritedRecordsState.disputeButton))
    }

    // MARK: 조각

    private func texts(title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
            Text(title).pumText(.callout, weight: .semibold).foregroundStyle(PumColor.textPrimary)
            Text(detail).pumText(.caption).foregroundStyle(PumColor.textSecondary)
        }
        .multilineTextAlignment(.leading)
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// 회색 배지 — 원문 글자 #5B6170(gray700), 바탕 #EAECF1
    private var ownerBadge: some View {
        Text(InheritedRecordsState.ownerInputText)
            .pumText(.caption, weight: .semibold)
            .foregroundStyle(PumTokens.ColorToken.gray700)
            .padding(.horizontal, PumTokens.Space.s8)
            .padding(.vertical, PumTokens.Space.s4)
            .background(PumColor.surfaceFill,
                        in: RoundedRectangle(cornerRadius: PumTokens.Radius.sm, style: .continuous))
            .accessibilityHidden(true)
    }

    private var chevron: some View {
        Image(systemName: "chevron.right").pumText(.callout, weight: .semibold)
            .foregroundStyle(PumColor.textDisabled) // 원문 #B5BBC6
            .accessibilityHidden(true)
    }
}

#Preview("20l 지난 근무기록") { InheritedRecordsView(state: .sample) }
#Preview("20l · 큰 글자") { InheritedRecordsView(state: .sample).dynamicTypeSize(.xxxLarge) }
