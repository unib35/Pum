// UI-IOS-1z · REQ-060 · REQ-028 · DEC-005 — 근로계약서 확인(확정). 탭 바 없음.
// 서명 전까지는 기존 조건이 적용되고(REQ-060), 서명 전에도 출퇴근은 막지 않는다(REQ-028).
// 서명하기 · 전문 보기 · 조건 수정 요청은 클로저만(연결 후속).
import SwiftUI

struct ContractReviewView: View {
    var record: ContractReviewRecord = .sample
    var onBack: () -> Void = {}
    var onSign: () -> Void = {}
    var onViewFull: () -> Void = {}
    var onRequestChange: () -> Void = {}

    /// 원문은 체크된 상태로 시작
    @State private var agreed = true

    /// 목업 체크 네모 약 22 — 토큰에 없어 이름을 붙임(DEC-005), 큰 글자에서 글자와 함께 커진다
    @ScaledMetric(relativeTo: .footnote) private var checkBox: CGFloat = 22
    /// 동의 문구 색 #3A4150 = 토큰 gray800(textPrimary보다 연함, 값 일치)
    private let consentColor = PumTokens.ColorToken.gray800

    var body: some View {
        VStack(spacing: 0) {
            PumNavHeader(title: "근로계약서", onBack: onBack)
                .padding(.horizontal, PumTokens.Size.screenPad)
            ScrollView {
                VStack(alignment: .leading, spacing: PumTokens.Space.s12) {
                    heading
                    termsCard
                    fullTextRow
                    consentRow
                }
                .padding(.horizontal, PumTokens.Size.screenPad)
                .padding(.vertical, PumTokens.Space.s16)
            }
        }
        .background(PumColor.bgApp)
        .safeAreaInset(edge: .bottom, spacing: 0) { actions }
    }

    // 2. 제목 · 배지 · 문서 종류 · 보낸 사람
    private var heading: some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s10) { // 원문: 제목 · 문서 종류 · 부제 사이가 넉넉하다(캡처 실측)
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .center, spacing: PumTokens.Space.s8) {
                    docTitle
                    Spacer(minLength: 0)
                    badge
                }
                VStack(alignment: .leading, spacing: PumTokens.Space.s6) {
                    docTitle
                    badge
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text("\(record.docTitle), \(record.statusText)"))
            .accessibilityAddTraits(.isHeader)
            Text(record.kindText).pumText(.body, weight: .medium).foregroundStyle(PumColor.textSecondary) // 16px 500 → body(15)
            Text(record.subtitleText).pumText(.footnote).foregroundStyle(PumColor.textSecondary)
        }
        .padding(.horizontal, PumTokens.Space.s4)
    }

    private var docTitle: some View {
        Text(record.docTitle).pumText(.title2).foregroundStyle(PumColor.textPrimary) // 문서 제목 24px 700
    }

    private var badge: some View {
        PumBadge(text: record.statusText, kind: .attention) // #B04E0A · #FBEBDA = 경고
    }

    // 3. 계약 조건 카드
    private var termsCard: some View {
        PumCard {
            VStack(spacing: 0) {
                Text("계약 조건").pumText(.caption, weight: .bold).foregroundStyle(PumColor.textSecondary)
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

    /// 키–값 행: 넓으면 한 줄(키는 위쪽 정렬), 좁으면(큰 글자) 값이 아래로
    private func termRow(_ t: ContractTerm, isLast: Bool) -> some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .top, spacing: PumTokens.Space.s12) {
                key(t.label)
                Spacer(minLength: 0)
                valueBlock(t, trailing: true).fixedSize()
            }
            VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                key(t.label)
                valueBlock(t, trailing: false)
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

    /// 값(15px 600) + 같은 줄 덧붙임(12px 400, 기준선 맞춤) + 아래 보조 줄(12px 400)
    private func valueBlock(_ t: ContractTerm, trailing: Bool) -> some View {
        VStack(alignment: trailing ? .trailing : .leading, spacing: PumTokens.Space.s2) {
            HStack(alignment: .firstTextBaseline, spacing: 0) {
                Text(t.value).pumText(.body, weight: .semibold).foregroundStyle(PumColor.textPrimary)
                if let suffix = t.suffix {
                    Text(suffix).pumText(.caption).foregroundStyle(PumColor.textSecondary)
                }
            }
            if let sub = t.subline {
                Text(sub).pumText(.caption).foregroundStyle(PumColor.textSecondary)
            }
        }
        .multilineTextAlignment(trailing ? .trailing : .leading)
    }

    // 4. 계약서 전문 보기(이동 행)
    private var fullTextRow: some View {
        Button(action: onViewFull) {
            PumCard {
                HStack(spacing: PumTokens.Space.s12) {
                    VStack(alignment: .leading, spacing: PumTokens.Space.s2) {
                        Text(record.fullTextTitle).pumText(.callout).foregroundStyle(PumColor.textPrimary) // 14px 600
                        Text(record.fullTextDetail).pumText(.caption).foregroundStyle(PumColor.textSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    Image(systemName: "chevron.right")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(PumColor.textDisabled)
                        .accessibilityHidden(true)
                }
                .padding(PumTokens.Space.s16)
                .frame(minHeight: PumTokens.Size.tapMin)
                .contentShape(Rectangle())
            }
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("\(record.fullTextTitle), \(record.fullTextDetail)"))
    }

    // 5. 동의 체크 — 공통 체크박스가 없어 화면 전용(공통 변경 요청 후보)
    private var consentRow: some View {
        Button { agreed.toggle() } label: {
            HStack(alignment: .top, spacing: PumTokens.Space.s10) {
                checkMark
                Text(record.consentText).pumText(.footnote).foregroundStyle(consentColor) // 13px 400
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, PumTokens.Space.s4)
            .padding(.vertical, PumTokens.Space.s10)
            .frame(minHeight: PumTokens.Size.tapMin)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("동의"))
        .accessibilityValue(Text(agreed ? "선택됨" : "선택 안 됨"))
        .accessibilityHint(Text(record.consentText))
        .accessibilityAddTraits(.isToggle)
    }

    private var checkMark: some View {
        RoundedRectangle(cornerRadius: PumTokens.Radius.sm, style: .continuous)
            .fill(agreed ? PumColor.accent : PumColor.surfaceCard)
            .overlay {
                if agreed {
                    Image(systemName: "checkmark").font(.footnote.weight(.bold)).foregroundStyle(.white)
                } else { // 체크 안 된 모양은 원문에 없음 — 추정: 흰 바탕 + hairline 테두리
                    RoundedRectangle(cornerRadius: PumTokens.Radius.sm, style: .continuous)
                        .strokeBorder(PumColor.borderHairline, lineWidth: 1)
                }
            }
            .frame(width: checkBox, height: checkBox)
    }

    // 6. 하단 고정
    private var actions: some View {
        VStack(spacing: PumTokens.Space.s4) {
            PumButton(title: "서명하기", kind: .primary, action: onSign)
                .disabled(!ContractReviewRecord.canSign(agreed: agreed))
            // 글자 버튼: 15px 500 보조색, 밑줄 없음, 터치 44
            Button(action: onRequestChange) {
                Text("조건 수정 요청").pumText(.body, weight: .medium).foregroundStyle(PumColor.textSecondary)
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

#Preview("1z") { ContractReviewView() }
#Preview("1z · 큰 글자") { ContractReviewView().dynamicTypeSize(.xxxLarge) }
