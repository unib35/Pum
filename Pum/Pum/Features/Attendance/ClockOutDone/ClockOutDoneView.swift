// UI-IOS-1f · REQ-024 · REQ-026 · REQ-006 — 퇴근 완료: 근무기록 생성(예정 vs 실제)
// 퇴근 직후 결과 화면이라 탭 바 없음. 닫기(오른쪽 위) 또는 확인으로 나간다.
import SwiftUI

struct ClockOutDoneView: View {
    var record: ClockOutDoneRecord = .sample
    var onClose: () -> Void = {}

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                PumIconButton(systemImage: "xmark", label: "닫기", action: onClose)
            }
            .padding(.horizontal, PumTokens.Size.screenPad)
            ScrollView {
                // 원문: 머리 줄 · 제목 · 카드 · 안내 사이 16
                VStack(alignment: .leading, spacing: PumTokens.Space.s16) {
                    title
                    resultCard
                    notice
                }
                .padding(.horizontal, PumTokens.Size.screenPad)
                .padding(.top, PumTokens.Space.s16)
            }
        }
        .background(PumColor.bgApp)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            PumButton(title: "확인", kind: .dark, action: onClose)
                .padding(.horizontal, PumTokens.Size.screenPad)
                .padding(.vertical, PumTokens.Space.s12)
                .background(PumColor.bgApp)
        }
    }

    private var title: some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s6) {
            // 목업 14px 500 → callout(14) medium
            Text(record.subtitle).pumText(.callout, weight: .medium).foregroundStyle(PumColor.textSecondary)
            // 목업 26px 700 → title2(24): 28보다 가깝다(DEC-005)
            Text(record.headline).pumText(.title2).foregroundStyle(PumColor.textPrimary)
                .accessibilityAddTraits(.isHeader)
            // 목업 14px 400 → callout, 굵기만 regular
            Text("오늘 근무기록이 저장됐어요").pumText(.callout, weight: .regular).foregroundStyle(PumColor.textSecondary)
        }
        // 원문: 제목 묶음 padding 4 4 2
        .padding(.horizontal, PumTokens.Space.s4)
        .padding(.top, PumTokens.Space.s4)
        .padding(.bottom, PumTokens.Space.s2)
    }

    /// 원문: 카드 padding 18 · 타일–타임라인–행 묶음 사이 14 · 행 구분선은 카드 안쪽 폭(좌우 18 안)
    private var resultCard: some View {
        PumCard {
            VStack(spacing: PumTokens.Space.s14) {
                tiles
                ClockOutDoneTimelineView(record: record)
                VStack(spacing: 0) {
                    Rectangle().fill(PumColor.borderHairline).frame(height: 1)
                    line(padY: PumTokens.Space.s14, divider: true) {
                        Text("휴게시간").foregroundStyle(PumColor.textSecondary)
                    } value: { PumRowValue(text: record.breakText) }
                    line(padY: PumTokens.Space.s14, divider: true) {
                        Text("실제 체류").foregroundStyle(PumColor.textSecondary)
                    } value: { PumRowValue(text: record.stayText) }
                    line(padY: PumTokens.Space.s12, divider: true) {
                        Text("인정 근무").foregroundStyle(PumColor.textSecondary)
                    } value: { bold(record.recognizedText, PumColor.textPrimary) }
                    line(padY: PumTokens.Space.s12, divider: false) {
                        Text("\(Text("오늘 기본급").foregroundStyle(PumColor.textSecondary))\(Text(record.wageText).foregroundStyle(PumColor.textDisabled))")
                    } value: { bold(record.basePayText, PumColor.statusDone) } // 확정 금액 = 초록
                }
            }
            .padding(PumTokens.Space.s18)
        }
    }

    /// 원문 행: 위아래 padding(14 · 14 · 12 · 12) · 좌우 0 · 아래 구분선. PumRow는 좌우 16 · 위아래 12 고정이라 화면 전용 행을 둔다
    private func line<K: View, V: View>(padY: CGFloat, divider: Bool, @ViewBuilder key: () -> K, @ViewBuilder value: () -> V) -> some View {
        HStack(spacing: PumTokens.Space.s12) {
            key().pumText(.body, weight: .regular)
                .frame(maxWidth: .infinity, alignment: .leading)
            value()
        }
        .padding(.vertical, padY)
        .overlay(alignment: .bottom) {
            if divider { Rectangle().fill(PumColor.borderHairline).frame(height: 1) }
        }
        .accessibilityElement(children: .combine)
    }

    /// 좁거나 글자가 크면 세로로
    private var tiles: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: PumTokens.Space.s10) { plannedTile; actualTile }
            VStack(spacing: PumTokens.Space.s10) { plannedTile; actualTile }
        }
    }

    private var plannedTile: some View {
        tile("예정", record.plannedRange, labelColor: PumColor.textSecondary, valueColor: PumColor.textPrimary, fill: PumColor.surfaceFill, labelWeight: .medium)
    }

    private var actualTile: some View {
        tile("실제", record.actualRange, labelColor: PumColor.accent, valueColor: PumColor.accent, fill: PumColor.accentSoft, labelWeight: .semibold)
    }

    private func tile(_ label: String, _ value: String, labelColor: Color, valueColor: Color, fill: Color, labelWeight: Font.Weight) -> some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s4) {
            Text(label).pumText(.caption, weight: labelWeight).foregroundStyle(labelColor)
            // 목업 18px 700 → headline(17) bold
            Text(value).pumText(.headline, weight: .bold).foregroundStyle(valueColor).lineLimit(1).fixedSize()
        }
        .padding(.vertical, PumTokens.Space.s12)
        .padding(.horizontal, PumTokens.Space.s14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(fill, in: RoundedRectangle(cornerRadius: PumTokens.Radius.lg, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    private func bold(_ s: String, _ color: Color) -> some View {
        Text(s).pumText(.headline, weight: .bold).foregroundStyle(color)
    }

    @ViewBuilder private var notice: some View {
        if let text = record.confirmNotice { noticeBox(text) }
    }

    private func noticeBox(_ text: String) -> some View {
        HStack(alignment: .top, spacing: PumTokens.Space.s12) {
            // 화면 전용: 흰 바탕 배지(공통 PumBadge(.done)는 연초록 바탕)
            Text("확정").pumText(.caption, weight: .bold).foregroundStyle(PumColor.statusDone)
                .padding(.horizontal, PumTokens.Space.s10).padding(.vertical, PumTokens.Space.s4)
                .background(PumColor.surfaceCard, in: Capsule())
            Text(text).pumText(.footnote).foregroundStyle(PumTokens.ColorToken.green700)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, PumTokens.Space.s14)
        .padding(.horizontal, PumTokens.Space.s16)
        .background(PumColor.statusDoneSoft, in: RoundedRectangle(cornerRadius: PumTokens.Radius.md, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("확정. " + text))
    }
}

#Preview("1f") { ClockOutDoneView() }
#Preview("1f · 큰 글자") { ClockOutDoneView().dynamicTypeSize(.xxxLarge) }
