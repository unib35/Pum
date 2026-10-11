// UI-IOS-1o · REQ-002 · REQ-060 · DEC-005 — 직원 온보딩: 초대 수락(확정). 탭 바 없음.
// 수락하면 소속이 생기고 근로계약서는 이후 앱에서 확인(REQ-060). 수락 · 나중에는 클로저만(연결 후속).
import SwiftUI

struct InviteAcceptView: View {
    var record: InviteAcceptRecord = .sample
    var onAccept: () -> Void = {}
    var onLater: () -> Void = {}

    /// 목업 앱 표시 네모 약 28 — 토큰에 없어 이름을 붙임(DEC-005)
    private let brandMark: CGFloat = 28
    /// 목업 사업장 색 네모 약 48 — 토큰에 없어 이름을 붙임(DEC-005)
    private let workplaceTile: CGFloat = 48
    /// 안내 문구는 카드보다 약 4 안쪽 — space-4
    private let noteInset = PumTokens.Space.s4

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: PumTokens.Space.s20) {
                brand
                heading
                card
                Text("수락하면 이 사업장의 직원으로 등록돼요. 근로조건이 바뀌면 알림으로 알려드리고, 근로계약서는 이후 앱에서 확인할 수 있어요.")
                    .pumText(.footnote).foregroundStyle(PumColor.textSecondary)
                    .padding(.horizontal, noteInset)
            }
            .padding(.horizontal, PumTokens.Size.screenPad)
            .padding(.vertical, PumTokens.Space.s16)
        }
        .background(PumColor.bgApp)
        .safeAreaInset(edge: .bottom, spacing: 0) { actions }
    }

    // 1. 앱 표시
    private var brand: some View {
        HStack(spacing: PumTokens.Space.s8) {
            Text("품").pumText(.callout, weight: .heavy).foregroundStyle(.white) // 14px 800
                .frame(width: brandMark, height: brandMark)
                .background(PumColor.surfaceInverse, in: RoundedRectangle(cornerRadius: PumTokens.Radius.sm, style: .continuous))
            Text("근무·급여").pumText(.footnote, weight: .semibold).foregroundStyle(PumColor.textSecondary) // 13px 600
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("품, 근무·급여"))
    }

    // 2. 큰 제목: 사업장 이름만 파랑. 한 Text라 큰 글자에서 자연스럽게 줄바꿈.
    private var heading: some View {
        var lead = AttributedString(record.titleLead); lead.foregroundColor = PumColor.textPrimary
        var name = AttributedString(record.workplaceName); name.foregroundColor = PumColor.accent
        var tail = AttributedString(record.titleTail); tail.foregroundColor = PumColor.textPrimary
        return Text(lead + name + tail)
            .pumText(.title1) // 목업 28px 700 = title1
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(record.titleText))
            .accessibilityAddTraits(.isHeader)
    }

    // 3. 흰 카드
    private var card: some View {
        PumCard {
            VStack(spacing: 0) {
                HStack(spacing: PumTokens.Space.s12) {
                    Text(record.initial).pumText(.headline, weight: .bold).foregroundStyle(.white) // 17px 700
                        .frame(width: workplaceTile, height: workplaceTile)
                        .background(record.tileColor, in: RoundedRectangle(cornerRadius: PumTokens.Radius.md, style: .continuous))
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                        Text(record.workplaceName).pumText(.body, weight: .bold).foregroundStyle(PumColor.textPrimary) // 16px 700 → body(15)
                        Text(record.subtitleText).pumText(.caption).foregroundStyle(PumColor.textSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(PumTokens.Space.s16)
                .accessibilityElement(children: .combine)
                Rectangle().fill(PumColor.borderHairline).frame(height: 1) // 전체 폭
                Text("제안된 근로조건").pumText(.caption, weight: .bold).foregroundStyle(PumColor.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, PumTokens.Size.rowPadX)
                    .padding(.top, PumTokens.Space.s12)
                    .padding(.bottom, PumTokens.Space.s4)
                    .accessibilityAddTraits(.isHeader)
                let terms = record.visibleTerms
                ForEach(Array(terms.enumerated()), id: \.element.id) { i, t in
                    termRow(t, isLast: i == terms.count - 1)
                }
            }
        }
    }

    /// 키–값 행: 넓으면 한 줄, 좁으면(큰 글자) 값이 아래로
    private func termRow(_ t: InviteTerm, isLast: Bool) -> some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: PumTokens.Space.s12) {
                key(t.label)
                Spacer(minLength: 0)
                value(t.value).fixedSize()
            }
            VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                key(t.label)
                value(t.value)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, PumTokens.Size.rowPadY)
        .padding(.horizontal, PumTokens.Size.rowPadX)
        .frame(minHeight: PumTokens.Size.tapMin)
        .overlay(alignment: .bottom) {
            if !isLast {
                Rectangle().fill(PumColor.borderHairline).frame(height: 1)
                    .padding(.horizontal, PumTokens.Size.rowPadX)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(t.accessibilityText))
    }

    private func key(_ s: String) -> some View {
        Text(s).pumText(.body, weight: .regular).foregroundStyle(PumColor.textSecondary) // 15px 400
    }

    private func value(_ s: String) -> some View {
        Text(s).pumText(.body, weight: .semibold).foregroundStyle(PumColor.textPrimary) // 15px 600
    }

    // 5. 하단 고정
    private var actions: some View {
        VStack(spacing: PumTokens.Space.s4) {
            PumButton(title: "초대 수락하기", kind: .primary, action: onAccept)
            // 글자 버튼: 15px 500 보조색, 밑줄 없음, 터치 44
            Button(action: onLater) {
                Text("나중에 할게요").pumText(.body, weight: .medium).foregroundStyle(PumColor.textSecondary)
                    .frame(maxWidth: .infinity, minHeight: PumTokens.Size.tapMin)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, PumTokens.Size.screenPad)
        .padding(.top, PumTokens.Space.s12)
        .padding(.bottom, PumTokens.Space.s4)
        .background(PumColor.bgApp)
    }
}

#Preview("1o") { InviteAcceptView() }
#Preview("1o · 큰 글자") { InviteAcceptView().dynamicTypeSize(.xxxLarge) }
