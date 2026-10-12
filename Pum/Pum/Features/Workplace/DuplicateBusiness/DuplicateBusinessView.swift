// UI-IOS-5d · REQ-012 — 사업자번호 중복 감지: 기존 사업장 참여 요청 / 다른 지점 / 분쟁(확정). 탭 바 없음.
// 미인증 사업장에 직원 · 기록이 있을 때의 문구와 처리 중 표시 디자인은 없다(만들지 않음 — 문장 숨김, 행 흐림).
import SwiftUI

struct DuplicateBusinessView: View {
    var state: DuplicateBusinessState = .sample
    var onBack: () -> Void = {}
    /// 각 선택은 한 번만. 끝나면 done(성공 여부) — 실패(false)일 때만 풀린다. 연결 전 기본값은 미전송(false).
    var onRequestJoin: (_ done: @escaping (Bool) -> Void) -> Void = { $0(false) }
    var onNewBranch: (_ done: @escaping (Bool) -> Void) -> Void = { $0(false) }
    var onDispute: (_ done: @escaping (Bool) -> Void) -> Void = { $0(false) }

    @State private var lock = DuplicateChoiceLock()
    /// 사업장 네모 약 48(15f와 같은 값) — 공통 후보
    @ScaledMetric(relativeTo: .headline) private var workplaceTile: CGFloat = 48

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: PumTokens.Space.s16) {
                topBar
                heading
                card
                choices
            }
            .padding(.horizontal, PumTokens.Size.screenPad)
            .padding(.top, PumTokens.Space.s8)
            .padding(.bottom, PumTokens.Space.s16)
        }
        .background(PumColor.bgApp)
    }

    private var topBar: some View {
        HStack(alignment: .center, spacing: PumTokens.Space.s8) {
            PumIconButton(systemImage: "chevron.left", label: "뒤로", action: onBack)
            Spacer(minLength: PumTokens.Space.s8)
            Text("사업장 인증 2 / 3").pumText(.footnote).foregroundStyle(PumColor.textSecondary)
                .multilineTextAlignment(.trailing)
        }
        .padding(.bottom, PumTokens.Space.s4)
    }

    private var heading: some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s8) {
            Text("이 사업자번호로\n이미 등록된 사업장이 있어요")
                .pumText(.title2).foregroundStyle(PumColor.textPrimary)
                .accessibilityAddTraits(.isHeader)
            Text(state.introText).pumText(.footnote).foregroundStyle(PumColor.textSecondary)
        }
    }

    // 기존 사업장 카드 + (내 미인증 사업장 삭제 안내)
    private var card: some View {
        PumCard {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: PumTokens.Space.s12) {
                    Text(state.initial).pumText(.headline, weight: .bold).foregroundStyle(.white)
                        .frame(width: workplaceTile, height: workplaceTile)
                        .background(state.tileColor, in: RoundedRectangle(cornerRadius: PumTokens.Radius.md, style: .continuous))
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                        ViewThatFits(in: .horizontal) {
                            HStack(spacing: PumTokens.Space.s8) { name; badge }
                            VStack(alignment: .leading, spacing: PumTokens.Space.s4) { name; badge }
                        }
                        Text(state.existingSubtitle).pumText(.caption).foregroundStyle(PumColor.textSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(PumTokens.Space.s16)
                .accessibilityElement(children: .combine)
                if state.showsDeleteNote {
                    Rectangle().fill(PumColor.borderHairline).frame(height: 1)
                        .padding(.horizontal, PumTokens.Space.s16)
                    deleteNote
                        .padding(PumTokens.Space.s16)
                }
            }
        }
    }

    private var name: some View {
        Text(state.existingName).pumText(.body, weight: .bold).foregroundStyle(PumColor.textPrimary) // 16px 700 → body(15)
    }

    private var badge: some View { PumBadge(text: "\u{2713} 인증됨", kind: .done) }

    /// 따옴표 안 사업장 이름만 굵게(12px 700)
    private var deleteNote: some View {
        (Text("내가 만든 ")
         + Text("\"\(state.myName)\"").fontWeight(.bold)
         + Text("은 직원 \(state.myStaffCount)명 · 기록 없음이라 삭제돼요."))
            .pumText(.caption).foregroundStyle(PumColor.textSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    // 선택 행 3개
    private var choices: some View {
        PumCard {
            choiceRow(.requestJoin, "기존 사업장에 관리자로 참여 요청", state.joinSubtitle, danger: false, isLast: false, action: onRequestJoin)
            choiceRow(.newBranch, "다른 지점이에요", "같은 사업자의 새 사업장으로 등록 · 지점명 구분", danger: false, isLast: false, action: onNewBranch)
            // 빨강은 위험 표시 — VoiceOver는 제목 문구로 충분하다
            choiceRow(.dispute, "내 사업장인데 누군가 먼저 등록했어요", "대표자 본인확인 후 고객센터가 확인해요", danger: true, isLast: true, action: onDispute)
        }
        .disabled(lock.isLocked) // 처리 중 표시 디자인이 없어 행을 흐리게만
    }

    private func choiceRow(_ c: DuplicateBusinessChoice, _ title: String, _ subtitle: String, danger: Bool, isLast: Bool,
                           action: @escaping (@escaping (Bool) -> Void) -> Void) -> some View {
        Button {
            guard lock.begin(c) else { return }
            action { ok in lock.finish(success: ok) }
        } label: {
            HStack(spacing: PumTokens.Space.s12) {
                VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                    Text(title).pumText(.body, weight: .semibold) // 15px 600
                        .foregroundStyle(danger ? PumColor.statusDanger : PumColor.textPrimary)
                    Text(subtitle).pumText(.caption).foregroundStyle(PumColor.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: "chevron.right").font(.footnote.weight(.semibold))
                    .foregroundStyle(PumColor.textTertiary).accessibilityHidden(true)
            }
            .padding(.vertical, PumTokens.Size.rowPadY)
            .padding(.horizontal, PumTokens.Size.rowPadX)
            .frame(minHeight: PumTokens.Size.tapMin)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .overlay(alignment: .bottom) {
            if !isLast { Rectangle().fill(PumColor.borderHairline).frame(height: 1) } // 원문: 카드 끝까지
        }
    }
}

#Preview("5d") { DuplicateBusinessView(state: .sample) }
#Preview("5d · 큰 글자") { DuplicateBusinessView(state: .sample).dynamicTypeSize(.xxxLarge) }
