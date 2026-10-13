// UI-IOS-1h · REQ-006 · REQ-022 · REQ-071 — 근무 상세(확정): 계산 근거를 보여 주는 읽기 화면
// 사업장 확인 기록이라 편집 버튼 없음 — 「수정 요청」만(REQ-006). 탭 바 없음(하위 화면).
import SwiftUI

struct WorkDetailView: View {
    var record: WorkDetailRecord = .sample
    var onBack: () -> Void = {}
    var onRequestEdit: () -> Void = {}
    /// 변경 이력 시각 칸 폭 — 원문 92 (DEC-005 화면 전용)
    @ScaledMetric(relativeTo: .footnote) private var stampWidth: CGFloat = 92

    var body: some View {
        VStack(spacing: 0) {
            PumNavHeader(title: "근무 상세", onBack: onBack)
                .padding(.horizontal, PumTokens.Size.screenPad)
            ScrollView {
                VStack(alignment: .leading, spacing: PumTokens.Space.s16) {
                    title
                    PumCard { WorkTimelineView(record: record).padding(PumTokens.Space.s18) }
                    info
                    history
                }
                .padding(.horizontal, PumTokens.Size.screenPad)
                .padding(.top, PumTokens.Space.s16) // 원문: 머리 줄 아래 16
                .padding(.bottom, PumTokens.Space.s12)
            }
        }
        .background(PumColor.bgApp)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            PumButton(title: "근무기록 수정 요청", kind: .outline, action: onRequestEdit)
                .padding(.horizontal, PumTokens.Size.screenPad)
                .padding(.vertical, PumTokens.Space.s12)
                .background(PumColor.bgApp)
        }
    }

    private var title: some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s4) {
            HStack(alignment: .firstTextBaseline) {
                // 목업 26px → title2(24): 28보다 가깝다(DEC-005)
                Text(record.dateTitle).pumText(.title2).foregroundStyle(PumColor.textPrimary)
                    .accessibilityAddTraits(.isHeader)
                Spacer(minLength: PumTokens.Space.s8)
                PumBadge(text: record.statusText, kind: .done)
            }
            // 목업 14px 400 → callout(14), 굵기만 regular
            Text(record.subtitle).pumText(.callout, weight: .regular).foregroundStyle(PumColor.textSecondary)
        }
    }

    /// 원문 행: 위아래 14 · 좌우 18(카드 안쪽) · 구분선은 그 폭 안. PumRow는 좌우 16 · 위아래 12 고정이라 화면 전용 행을 둔다
    private var info: some View {
        PumCard {
            VStack(spacing: 0) {
                infoRow("예정 근무", isLast: false) { Text(record.plannedRange).pumText(.body, weight: .semibold) }
                infoRow("실제 근무", isLast: false) { Text(record.actualRange).pumText(.body, weight: .semibold) }
                infoRow("휴게시간", isLast: false) { Text(record.breakText).pumText(.body, weight: .semibold) }
                infoRow("인정 근무", isLast: false) { boldValue(record.recognizedText, PumColor.textPrimary) }
                infoRow("해당 근무 기본급", isLast: true) { boldValue(record.basePayText, PumColor.statusDone) } // 확정 금액 = 초록
            }
            .padding(.horizontal, PumTokens.Space.s18)
        }
    }

    private func infoRow<V: View>(_ key: String, isLast: Bool, @ViewBuilder value: () -> V) -> some View {
        HStack(spacing: PumTokens.Space.s12) {
            Text(key).pumText(.body, weight: .regular).foregroundStyle(PumColor.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            value().foregroundStyle(PumColor.textPrimary)
        }
        .padding(.vertical, PumTokens.Space.s14)
        .overlay(alignment: .bottom) {
            if !isLast { Rectangle().fill(PumColor.borderHairline).frame(height: 1) }
        }
        .accessibilityElement(children: .combine)
    }

    private func boldValue(_ s: String, _ color: Color) -> some View {
        Text(s).pumText(.headline, weight: .bold).foregroundStyle(color)
    }

    /// 디자인 1h: 제목은 카드 안, 행은 「시각 · 내용」 한 줄(큰 글자에서 넘치면 두 줄)
    private var history: some View {
        PumCard {
            VStack(alignment: .leading, spacing: PumTokens.Space.s8) {
                Text("변경 이력").pumText(.footnote, weight: .bold).foregroundStyle(PumColor.textSecondary)
                    .padding(.bottom, PumTokens.Space.s2) // 제목 아래 10 = 8 + 2
                    .accessibilityAddTraits(.isHeader)
                ForEach(record.history) { h in
                    ViewThatFits(in: .horizontal) {
                        HStack(alignment: .firstTextBaseline, spacing: PumTokens.Space.s12) {
                            stamp(h.stamp)
                            Text(h.text).pumText(.footnote).foregroundStyle(PumColor.textPrimary)
                            Spacer(minLength: 0)
                        }
                        VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                            stamp(h.stamp)
                            Text(h.text).pumText(.footnote).foregroundStyle(PumColor.textPrimary)
                        }
                    }
                    .accessibilityElement(children: .combine)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, PumTokens.Space.s14)
            .padding(.horizontal, PumTokens.Space.s18)
        }
    }

    private func stamp(_ s: String) -> some View {
        Text(s).pumText(.footnote).foregroundStyle(PumColor.textTertiary).fixedSize()
            .frame(minWidth: stampWidth, alignment: .leading)
    }
}

#Preview("1h") { WorkDetailView() }
#Preview("1h · 큰 글자") { WorkDetailView().dynamicTypeSize(.xxxLarge) }
