// UI-IOS-8a · REQ-028 · REQ-070 — 사장님 10월 근무 마감: 문제 있는 기록만 모아서. 탭 바 없음.
// 처리 필요가 0건일 때만 마감(REQ-070). 마감은 한 번만 — 처리 중에는 잠기고, 실패일 때만 풀린다.
// 색: 초록 = 정상 · 주황 = 처리 필요 · 빨강 = 퇴근 미기록. 체크 완료 = 회색 원 + 먹색 체크.
import SwiftUI

struct WorkClosingView: View {
    var state: WorkClosingState = .sample
    var onBack: () -> Void = {}
    var onOpenCategory: (WorkClosingCategory) -> Void = { _ in }
    var onOpenEmployeeConfirm: () -> Void = {}
    var onReviewProblems: () -> Void = {}
    /// 마감 실행. 결과를 done(성공 여부)로 알린다. 연결 전 기본값은 실패(done(false)).
    var onClose: (_ done: @escaping (Bool) -> Void) -> Void = { done in done(false) }

    @State private var lock = WorkClosingLock()
    private var isClosing: Bool { lock.isClosing }
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .body) private var barHeight = PumTokens.Space.s8
    @ScaledMetric(relativeTo: .body) private var badgeSize = PumLayout.avatar - PumTokens.Space.s12 // 원문 상태 원 약 24pt(7a 체크 원과 같은 값)

    var body: some View {
        VStack(spacing: 0) {
            PumNavHeader(title: "근무 마감", onBack: onBack) { EmptyView() }
                .padding(.horizontal, PumTokens.Size.screenPad)
            ScrollView {
                VStack(alignment: .leading, spacing: PumTokens.Space.s12) {
                    titleBlock
                    summaryCard
                    Group { // 마감하는 동안은 다른 화면으로 가지 않게
                        categoryCard
                        confirmRequestCard
                    }
                    .disabled(isClosing)
                }
                .padding(.horizontal, PumTokens.Size.screenPad)
                .padding(.vertical, PumTokens.Space.s12)
            }
            bottomButtons
        }
        .background(PumColor.bgApp)
    }

    // MARK: 제목

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s4) {
            Text(state.subtitle).pumText(.footnote, weight: .medium).foregroundStyle(PumColor.textSecondary)
            Text(state.title).pumText(.title2).foregroundStyle(PumColor.textPrimary) // 원문 24px 700
                .accessibilityAddTraits(.isHeader)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, PumTokens.Space.s4)
    }

    // MARK: 요약 카드

    private var summaryCard: some View {
        PumCard {
            VStack(alignment: .leading, spacing: PumTokens.Space.s12) {
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .top, spacing: PumTokens.Space.s12) {
                        stat("직원", state.employeeText)
                        stat("근무기록", state.recordText)
                        stat("총 근무", state.totalWorkText)
                    }
                    VStack(alignment: .leading, spacing: PumTokens.Space.s8) {
                        stat("직원", state.employeeText)
                        stat("근무기록", state.recordText)
                        stat("총 근무", state.totalWorkText)
                    }
                }
                bar
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(Text(state.barAccessibilityText))
                ViewThatFits(in: .horizontal) {
                    HStack {
                        Text(state.normalText).foregroundStyle(PumColor.statusDone)
                        Spacer(minLength: PumTokens.Space.s8)
                        Text(state.problemText).foregroundStyle(PumColor.statusAttention)
                    }
                    VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                        Text(state.normalText).foregroundStyle(PumColor.statusDone)
                        Text(state.problemText).foregroundStyle(PumColor.statusAttention)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .pumText(.caption, weight: .semibold) // 원문 12px 600
                .accessibilityHidden(true) // 막대 라벨이 같은 내용을 읽는다
            }
            .padding(PumTokens.Space.s16)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func stat(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
            Text(label).pumText(.caption2, weight: .regular).foregroundStyle(PumColor.textSecondary) // 원문 11px
            Text(value).pumText(.headline, weight: .bold).foregroundStyle(PumColor.textPrimary) // 원문 18px 700 → 17px 근사
                .lineLimit(1).minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    /// 서버가 준 정상 · 처리 필요 건수를 폭 비율로 그리기만 한다
    private var bar: some View {
        GeometryReader { geo in
            HStack(spacing: 0) {
                Rectangle().fill(PumColor.statusDone)
                    .frame(width: geo.size.width * barFraction)
                Rectangle().fill(PumColor.statusAttention)
            }
            .clipShape(Capsule())
            .animation(PumMotion.respecting(reduceMotion, PumMotion.progress), value: barFraction) // M22
        }
        .frame(height: barHeight)
    }

    private var barFraction: CGFloat {
        let total = state.normalCount + state.problemCount
        return total > 0 ? CGFloat(state.normalCount) / CGFloat(total) : 1
    }

    // MARK: 유형 카드

    private var categoryCard: some View {
        PumCard {
            normalRow
            ForEach(WorkClosingCategory.allCases, id: \.self) { kind in
                divider
                categoryRow(kind)
            }
        }
    }

    private var normalRow: some View {
        HStack(spacing: PumTokens.Space.s12) {
            // 5a와 같은 값 — 공통 후보: 회색 원 + 먹색 체크
            Circle().fill(PumColor.surfaceFill).frame(width: badgeSize, height: badgeSize)
                .overlay { Image(systemName: "checkmark").font(.footnote.weight(.bold)).foregroundStyle(PumColor.textPrimary) }
                .accessibilityHidden(true)
            Text("정상 기록").pumText(.body, weight: .medium).foregroundStyle(PumColor.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("\(state.normalCount)건").pumText(.headline, weight: .bold).foregroundStyle(PumColor.statusDone)
        }
        .padding(.horizontal, PumTokens.Size.rowPadX)
        .padding(.vertical, PumTokens.Space.s10)
        .frame(minHeight: PumTokens.Size.tapMin)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("정상 기록, \(state.normalCount)건"))
    }

    private func categoryRow(_ kind: WorkClosingCategory) -> some View {
        let isDanger = kind == .missingClockOut
        let tint = isDanger ? PumColor.statusDanger : PumColor.statusAttention
        let soft = isDanger ? PumColor.statusDangerSoft : PumColor.statusAttentionSoft
        let n = state.count(of: kind)
        return Button { onOpenCategory(kind) } label: {
            HStack(spacing: PumTokens.Space.s12) {
                // 공통 후보: 「!」 원(5a와 같은 값, 연주황 · 연빨강 바탕)
                Text("!").pumText(.footnote, weight: .heavy).foregroundStyle(tint)
                    .frame(width: badgeSize, height: badgeSize)
                    .background(soft, in: Circle())
                    .accessibilityHidden(true)
                Text(kind.title).pumText(.body, weight: .semibold).foregroundStyle(PumColor.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("\(n)건").pumText(.headline, weight: .bold).foregroundStyle(tint)
                Image(systemName: "chevron.right").font(.footnote.weight(.semibold))
                    .foregroundStyle(PumColor.textTertiary).accessibilityHidden(true)
            }
            .padding(.horizontal, PumTokens.Size.rowPadX)
            .padding(.vertical, PumTokens.Space.s10)
            .frame(minHeight: PumTokens.Size.tapMin)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("\(kind.spokenTitle), \(n)건, 처리 필요"))
        .accessibilityAddTraits(.isButton)
    }

    private var divider: some View {
        Rectangle().fill(PumColor.borderHairline).frame(height: 1) // 카드 끝까지
    }

    // MARK: 직원 확인 요청

    private var confirmRequestCard: some View {
        PumCard {
            Button(action: onOpenEmployeeConfirm) {
                HStack(spacing: PumTokens.Space.s12) {
                    VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                        Text("직원 확인 요청").pumText(.callout, weight: .semibold).foregroundStyle(PumColor.textPrimary)
                        Text(state.confirmRequestSubtitle).pumText(.caption, weight: .regular).foregroundStyle(PumColor.textSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    Image(systemName: "chevron.right").font(.footnote.weight(.semibold))
                        .foregroundStyle(PumColor.textTertiary).accessibilityHidden(true)
                }
                .padding(.horizontal, PumTokens.Size.rowPadX)
                .padding(.vertical, PumTokens.Space.s12)
                .frame(minHeight: PumTokens.Size.tapMin)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text("직원 확인 요청, \(state.confirmRequestTotal)명 중 \(state.confirmedEmployeeCount)명 이상 없음, 선택 단계"))
            .accessibilityAddTraits(.isButton)
        }
    }

    // MARK: 하단 버튼

    private var bottomButtons: some View {
        VStack(spacing: PumTokens.Space.s8) {
            PumButton(title: state.reviewTitle, kind: .primary, action: onReviewProblems)
                .disabled(isClosing)
            PumButton(title: state.closeTitle, kind: .primary, isLoading: isClosing, loadingTitle: "마감하는 중", action: close)
                .disabled(!state.canClose || isClosing)
                .accessibilityLabel(Text(state.closeAccessibilityLabel))
        }
        .padding(.horizontal, PumTokens.Size.screenPad)
        .padding(.top, PumTokens.Space.s8)
        .padding(.bottom, PumTokens.Space.s12)
    }

    /// 한 번만 — 누르는 즉시 잠그고, 실패일 때만 푼다
    private func close() {
        guard lock.begin(canClose: state.canClose) else { return }
        onClose { success in lock.finish(success: success) }
    }
}

#Preview("8a") { WorkClosingView(state: .sample) }
#Preview("8a · 큰 글자") { WorkClosingView(state: .sample).dynamicTypeSize(.xxxLarge) }
#Preview("8a · 마감 가능") {
    var s = WorkClosingState.sample
    s.problemCount = 0; s.normalCount = 76; s.needsCheckCount = 0; s.missingClockOutCount = 0; s.editRequestCount = 0
    return WorkClosingView(state: s)
}
