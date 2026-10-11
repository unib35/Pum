// UI-IOS-1h · REQ-006 · REQ-022 · REQ-071 — 근무 상세(확정): 계산 근거를 보여 주는 읽기 화면
// 사업장 확인 기록이라 편집 버튼 없음 — 「수정 요청」만(REQ-006). 탭 바 없음(하위 화면).
import SwiftUI

struct WorkDetailView: View {
    var record: WorkDetailRecord = .sample
    var onBack: () -> Void = {}
    var onRequestEdit: () -> Void = {}

    var body: some View {
        VStack(spacing: 0) {
            PumNavHeader(title: "근무 상세", onBack: onBack)
                .padding(.horizontal, PumTokens.Size.screenPad)
            ScrollView {
                VStack(alignment: .leading, spacing: PumTokens.Space.s12) {
                    title
                    PumCard { WorkTimelineView(record: record).padding(PumTokens.Space.s16) }
                    info
                    history
                }
                .padding(.horizontal, PumTokens.Size.screenPad)
                .padding(.vertical, PumTokens.Space.s12)
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

    private var info: some View {
        PumCard {
            PumRow("예정 근무", value: record.plannedRange)
            PumRow("실제 근무", value: record.actualRange)
            PumRow("휴게시간", value: record.breakText)
            PumRow(title: "인정 근무", isKey: true) { boldValue(record.recognizedText, PumColor.textPrimary) }
            PumRow(title: "해당 근무 기본급", isKey: true, isLast: true) { boldValue(record.basePayText, PumColor.statusDone) } // 확정 금액 = 초록
        }
    }

    private func boldValue(_ s: String, _ color: Color) -> some View {
        Text(s).pumText(.headline, weight: .bold).foregroundStyle(color)
    }

    private var history: some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s8) {
            PumSectionHeader(title: "변경 이력")
            PumCard {
                VStack(alignment: .leading, spacing: PumTokens.Space.s10) {
                    ForEach(record.history) { h in
                        VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                            Text(h.stamp).pumText(.footnote).foregroundStyle(PumColor.textTertiary)
                            Text(h.text).pumText(.footnote).foregroundStyle(PumColor.textPrimary)
                        }
                        .accessibilityElement(children: .combine)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(PumTokens.Space.s16)
            }
        }
    }
}

#Preview("1h") { WorkDetailView() }
#Preview("1h · 큰 글자") { WorkDetailView().dynamicTypeSize(.xxxLarge) }
