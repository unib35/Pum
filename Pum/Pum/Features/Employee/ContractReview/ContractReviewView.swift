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

    /// 동의는 직원이 직접 체크한다 — 실제 진입은 체크 안 된 상태(미리 체크된 동의는 효력 시비 · 노무 검토).
    /// 원문 캡처는 체크한 뒤 모습이라 비교 캡처 · 프리뷰만 `startsAgreed: true`.
    @State private var agreed: Bool

    init(record: ContractReviewRecord = .sample, startsAgreed: Bool = false,
         onBack: @escaping () -> Void = {}, onSign: @escaping () -> Void = {},
         onViewFull: @escaping () -> Void = {}, onRequestChange: @escaping () -> Void = {}) {
        self.record = record
        self.onBack = onBack
        self.onSign = onSign
        self.onViewFull = onViewFull
        self.onRequestChange = onRequestChange
        _agreed = State(initialValue: startsAgreed)
    }

    /// 동의 문구 색 #3A4150 = 토큰 gray800(textPrimary보다 연함, 값 일치)
    private let consentColor = PumTokens.ColorToken.gray800

    var body: some View {
        VStack(spacing: 0) {
            PumNavHeader(title: "근로계약서", onBack: onBack)
                .padding(.horizontal, PumTokens.Size.screenPad)
            ScrollView {
                VStack(alignment: .leading, spacing: PumTokens.Space.s14) {
                    heading
                    termsCard
                    fullTextRow
                    consentRow
                }
                .padding(.horizontal, PumTokens.Size.screenPad)
                .padding(.vertical, PumTokens.Space.s14)
            }
        }
        .background(PumColor.bgApp)
        .safeAreaInset(edge: .bottom, spacing: 0) { actions }
    }

    // 2. 제목 · 배지 · 문서 종류 · 보낸 사람
    private var heading: some View {
        VStack(alignment: .leading, spacing: 0) { // 원문: 제목 · 문서 종류는 붙어 있고 부제만 6 아래
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .top, spacing: PumTokens.Space.s8) {
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
                .padding(.top, PumTokens.Space.s6)
        }
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
                    .padding(.horizontal, PumTokens.Space.s18)
                    .padding(.top, PumTokens.Space.s16) // 원문 카드 6 + 제목 10
                    .padding(.bottom, PumTokens.Space.s4)
                    .accessibilityAddTraits(.isHeader)
                let terms = record.terms
                ForEach(Array(terms.enumerated()), id: \.element.id) { i, t in
                    termRow(t, isLast: i == terms.count - 1)
                }
                Color.clear.frame(height: PumTokens.Space.s4) // 원문 아래 4
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
        .padding(.vertical, PumTokens.Space.s10) // 원문 11 — 가까운 토큰
        .padding(.horizontal, PumTokens.Space.s18)
        .overlay(alignment: .bottom) {
            if !isLast {
                Rectangle().fill(PumColor.borderHairline).frame(height: 1)
                    .padding(.horizontal, PumTokens.Space.s18) // 원문: 안쪽 18에서 시작
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
                .padding(.vertical, PumTokens.Space.s14)
                .padding(.horizontal, PumTokens.Space.s16)
                .frame(minHeight: PumTokens.Size.tapMin)
                .contentShape(Rectangle())
            }
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("\(record.fullTextTitle), \(record.fullTextDetail)"))
    }

    // 5. 동의 체크 — 공통 체크박스 행(PumCheckboxRow). 무엇에 동의하는지 문구 전체를 VoiceOver 라벨로
    private var consentRow: some View {
        PumCheckboxRow(title: record.consentText, isOn: agreed, textColor: consentColor) { agreed.toggle() } // 13px 400
            // 공통 체크박스 행의 위아래 10 · 최소 44가 줄을 키워서, 배치만 원문(위아래 0)에 맞추고 누름 영역은 그대로 둔다
            .padding(.vertical, -PumTokens.Space.s10)
    }

    // 6. 하단 고정
    private var actions: some View {
        VStack(spacing: PumTokens.Space.s10) {
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
        .padding(.bottom, PumTokens.Space.s10) // 원문 아래 44 − 홈 막대 34
        .background(PumColor.bgApp)
    }
}

#Preview("1z") { ContractReviewView(startsAgreed: true) }
#Preview("1z · 동의 전") { ContractReviewView() }
#Preview("1z · 큰 글자") { ContractReviewView(startsAgreed: true).dynamicTypeSize(.xxxLarge) }
