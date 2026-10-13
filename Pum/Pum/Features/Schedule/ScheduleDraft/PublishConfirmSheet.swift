// UI-IOS-17c · REQ-050 — 게시 확인 시트(17a 위 · C9 바텀시트 안 내용)
// 바뀐 것 · 점검 결과 · 인건비는 서버(엔진) 값 그대로 — 화면에서 계산하거나 판정하지 않는다.
// 인력 부족(주의)은 게시를 막지 않는다. 막는지는 서버가 주는 isBlocking 하나로만 정한다.
// 게시는 되돌리기 어려운 처리라 처리 중 표시는 「게시」 버튼에만 둔다.
import SwiftUI

/// 바뀐 것 한 줄
nonisolated struct PublishChange: Identifiable, Equatable, Sendable {
    nonisolated enum Kind: String, Equatable, Sendable { case added = "추가", changed = "변경", removed = "삭제" }

    let id: Int
    let kind: Kind
    /// 「이종민 · 10월 7일 수」
    let title: String
    /// 「17:00 – 22:00」 · 「출근 09:00 → 10:00」 · 「휴무 승인」
    let detail: String

    /// 「추가, 이종민 · 10월 7일 수, 17:00 – 22:00」
    var accessibilityText: String { "\(kind.rawValue), \(title), \(detail)" }
}

/// 점검 한 줄 — 결과(통과 · 주의 · 실패)는 서버 값
nonisolated struct PublishCheck: Identifiable, Equatable, Sendable {
    nonisolated enum Result: String, Equatable, Sendable {
        case passed = "통과", warning = "주의", failed = "실패"
    }

    let id: Int
    let result: Result
    let title: String
    /// 회색 설명(주의 · 실패일 때)
    let detail: String?

    /// 「통과, 승인된 휴무와 겹침 없음」 · 「주의, 토 17–22 · 1명 부족, 게시 후 …」
    var accessibilityText: String {
        ([result.rawValue, title] + (detail.map { [$0] } ?? [])).joined(separator: ", ")
    }
}

nonisolated struct PublishConfirmSheetState: Equatable, Sendable {
    static let cancelTitle = "취소"
    static let publishTitle = "게시"
    static let publishingTitle = "게시 중"

    /// 「다음 주 스케줄 게시」
    let title: String
    /// 「10월 5일 – 11일 · 직원 6명 · 예상 인건비 2,184,000원」(서버)
    let summary: String
    /// 「바뀐 것 3건」(서버)
    let changesTitle: String
    let changes: [PublishChange]
    /// 「점검」
    let checksTitle: String
    let checks: [PublishCheck]
    /// 「게시 후 바꾸면 해당 직원이 수락해야 바뀌어요」
    let footnote: String
    /// 서버가 게시를 막을 때만 true(주 52시간 초과 같은 법정 위반이 실패로 올 때의 정책은 원문 없음 — 값만 둔다)
    let isBlocking: Bool
    /// 게시 처리 중(서버)
    let isPublishing: Bool

    var canPublish: Bool { !isBlocking && !isPublishing }
    var hasWarning: Bool { checks.contains { $0.result == .warning } }
}

nonisolated extension PublishConfirmSheetState {
    static let sample = PublishConfirmSheetState(
        title: "다음 주 스케줄 게시",
        summary: "10월 5일 \u{2013} 11일 \u{00B7} 직원 6명 \u{00B7} 예상 인건비 2,184,000원",
        changesTitle: "바뀐 것 3건",
        changes: [
            .init(id: 1, kind: .added, title: "이종민 \u{00B7} 10월 7일 수", detail: "17:00 \u{2013} 22:00"),
            .init(id: 2, kind: .changed, title: "최유나 \u{00B7} 10월 7일 수", detail: "출근 09:00 \u{2192} 10:00"),
            .init(id: 3, kind: .removed, title: "정다은 \u{00B7} 10월 10일 토", detail: "휴무 승인"),
        ],
        checksTitle: "점검",
        checks: [
            .init(id: 1, result: .passed, title: "승인된 휴무와 겹침 없음", detail: nil),
            .init(id: 2, result: .passed, title: "4시간 이상 근무에 휴게 포함", detail: nil),
            .init(id: 3, result: .passed, title: "주 52시간 이내", detail: nil),
            .init(id: 4, result: .warning, title: "토 17\u{2013}22 \u{00B7} 1명 부족", detail: "게시 후 추가 근무 요청으로 채울 수 있어요"),
        ],
        footnote: "게시 후 바꾸면 해당 직원이 수락해야 바뀌어요",
        isBlocking: false, isPublishing: false)
}

struct PublishConfirmSheet: View {
    private let state: PublishConfirmSheetState
    private let onCancel: () -> Void
    private let onConfirm: () -> Void
    @ScaledMetric(relativeTo: .body) private var circleSize: CGFloat = 24
    @Environment(\.dynamicTypeSize) private var typeSize

    init(state: PublishConfirmSheetState, onCancel: @escaping () -> Void = {}, onConfirm: @escaping () -> Void = {}) {
        self.state = state
        self.onCancel = onCancel
        self.onConfirm = onConfirm
    }

    var body: some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s16) {
            VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                Text(state.title).pumText(.title3).foregroundStyle(PumColor.textPrimary) // 20px 700
                    .accessibilityAddTraits(.isHeader)
                Text(state.summary).pumText(.footnote).foregroundStyle(PumColor.textSecondary) // 13px 400
            }
            changesCard
            checksCard
            buttons
            Text(state.footnote).pumText(.caption).foregroundStyle(PumColor.textSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, PumTokens.Size.screenPad)
        .padding(.bottom, PumTokens.Space.s16)
    }

    // MARK: 바뀐 것

    private var changesCard: some View {
        PumCard {
            cardTitle(state.changesTitle)
            ForEach(state.changes) { change in
                Rectangle().fill(PumColor.borderHairline).frame(height: 1)
                changeRow(change)
            }
        }
    }

    private func cardTitle(_ text: String) -> some View {
        Text(text).pumText(.body, weight: .bold).foregroundStyle(PumColor.textPrimary) // 15px 700
            .padding(.horizontal, PumTokens.Space.s16)
            .padding(.top, PumTokens.Space.s16)
            .padding(.bottom, PumTokens.Space.s12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityAddTraits(.isHeader)
    }

    private func changeRow(_ change: PublishChange) -> some View {
        let text = VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
            Text(change.title).pumText(.callout).foregroundStyle(PumColor.textPrimary)       // 14px 600
            Text(change.detail).pumText(.caption).foregroundStyle(PumColor.textSecondary)    // 12px 400
        }
        return ViewThatFits(in: .horizontal) {
            HStack(spacing: PumTokens.Space.s12) {
                PumBadge(text: change.kind.rawValue, kind: .waiting)
                text.frame(maxWidth: .infinity, alignment: .leading)
            }
            VStack(alignment: .leading, spacing: PumTokens.Space.s8) {
                PumBadge(text: change.kind.rawValue, kind: .waiting)
                text
            }
        }
        .padding(.horizontal, PumTokens.Space.s16)
        .padding(.vertical, PumTokens.Space.s12)
        .frame(maxWidth: .infinity, minHeight: PumTokens.Size.tapMin, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(change.accessibilityText))
    }

    // MARK: 점검

    private var checksCard: some View {
        PumCard {
            cardTitle(state.checksTitle)
            ForEach(state.checks) { check in
                Rectangle().fill(PumColor.borderHairline).frame(height: 1)
                checkRow(check)
            }
        }
    }

    private func checkRow(_ check: PublishCheck) -> some View {
        HStack(spacing: PumTokens.Space.s12) {
            checkCircle(check.result)
            VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                Text(check.title).pumText(.callout).foregroundStyle(PumColor.textPrimary)
                if let detail = check.detail {
                    Text(detail).pumText(.caption).foregroundStyle(PumColor.textSecondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, PumTokens.Space.s16)
        .padding(.vertical, PumTokens.Space.s12)
        .frame(maxWidth: .infinity, minHeight: PumTokens.Size.tapMin, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(check.accessibilityText))
    }

    /// 통과 = 회색 원 + 먹색 체크, 주의 = 연주황 원 + 「!」, 실패 = 연빨강 원 + 「!」(색만으로 구분하지 않고 글자 · 읽기 문구도 함께)
    @ViewBuilder private func checkCircle(_ result: PublishCheck.Result) -> some View {
        switch result {
        case .passed:
            Image(systemName: "checkmark")
                .font(.system(size: circleSize * 0.45, weight: .semibold))
                .foregroundStyle(PumColor.textPrimary)
                .frame(width: circleSize, height: circleSize)
                .background(PumColor.surfaceFill, in: Circle())
        case .warning:
            Text("!").pumText(.body, weight: .heavy).foregroundStyle(PumColor.statusAttention)
                .frame(width: circleSize, height: circleSize)
                .background(PumColor.statusAttentionSoft, in: Circle())
        case .failed:
            Text("!").pumText(.body, weight: .heavy).foregroundStyle(PumColor.statusDanger)
                .frame(width: circleSize, height: circleSize)
                .background(PumColor.statusDangerSoft, in: Circle())
        }
    }

    // MARK: 버튼 — 취소 : 게시 = 받은 폭 2 : 3

    @ViewBuilder private var buttons: some View {
        if typeSize.isAccessibilitySize {
            VStack(spacing: PumTokens.Space.s8) { publishButton; cancelButton }
        } else {
            DraftRatioPairLayout(ratio: 1.5, spacing: PumTokens.Space.s8) { cancelButton; publishButton }
        }
    }

    private var cancelButton: some View {
        PumButton(title: PublishConfirmSheetState.cancelTitle, kind: .outline, action: onCancel)
    }

    private var publishButton: some View {
        PumButton(title: PublishConfirmSheetState.publishTitle, isLoading: state.isPublishing,
                  loadingTitle: PublishConfirmSheetState.publishingTitle, action: onConfirm)
            .disabled(state.isBlocking)
    }
}

#Preview("17c 시트") { PublishConfirmSheet(state: .sample).background(PumColor.bgApp) }
