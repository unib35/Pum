// UI-IOS-1w · REQ-008 — 사장님 「사업장」 탭: 전체 사업장 통합 데이터
// 인건비 · 인원 · 건수 · D-7 · 막대 비율은 서버가 준 값을 그대로 보여 준다. 화면에서 계산하지 않는다
// (아래 비율 · 합은 막대 폭과 문구를 만들기 위한 것).
import SwiftUI

nonisolated struct OwnerWorkplaceBadge: Equatable, Sendable, Identifiable {
    var id: String { text }
    let text: String
    /// 확인 필요 = 경고(주황), 나머지는 중립(회색)
    let isAttention: Bool
    /// VoiceOver 한 문장용 「확인 필요 4건」
    let spoken: String
}

nonisolated struct OwnerWorkplaceEntry: Equatable, Sendable, Identifiable {
    let id: String
    let name: String
    let initial: String
    /// 사업장 색 번호(`OwnerWorkplaceTileColor`가 범위 밖도 방어)
    let colorIndex: Int
    let staffCount: Int
    let workingCount: Int
    /// 서버가 준 예상 인건비(원)와 그중 확정 금액(원)
    let expectedAmount: Int
    let confirmedAmount: Int
    /// 배지 건수(0이면 표시 안 함)
    let attentionCount: Int
    let editRequestCount: Int
    let substituteCount: Int
    let invitingCount: Int

    var amountText: String { PumFormat.amount(expectedAmount) }
    var staffText: String { "직원 \(staffCount)명 · 근무 중 \(workingCount)명" }
    var tileColor: Color { OwnerWorkplaceTileColor.color(at: colorIndex) }

    /// 확정 비율 0…1 (음수 · 0 · 확정 > 예상 방어)
    var confirmedFraction: Double {
        guard expectedAmount > 0 else { return 0 }
        return min(1, max(0, Double(confirmedAmount) / Double(expectedAmount)))
    }

    var badges: [OwnerWorkplaceBadge] {
        var list: [OwnerWorkplaceBadge] = []
        func add(_ label: String, _ n: Int, attention: Bool = false) {
            guard n > 0 else { return }
            list.append(.init(text: "\(label) \(n)", isAttention: attention, spoken: "\(label) \(n)건"))
        }
        add("확인 필요", attentionCount, attention: true)
        add("수정 요청", editRequestCount)
        add("대타", substituteCount)
        add("초대 중", invitingCount)
        return list
    }

    /// VoiceOver: 카드 한 문장
    var accessibilityText: String {
        var parts = [name, "직원 \(staffCount)명", "근무 중 \(workingCount)명", "예상 인건비 \(amountText)원"]
        parts += badges.map(\.spoken)
        return parts.joined(separator: ", ")
    }
}

/// 사업장 색 네모: 원문 1w는 파랑(#2F5BEA)과 연파랑(#6B8AF0). 연파랑은 토큰에 없어 가장 가까운 blue-300(충돌 #20)
nonisolated enum OwnerWorkplaceTileColor {
    static let colors: [Color] = [PumColor.accent, PumTokens.ColorToken.blue300]
    static func color(at index: Int) -> Color {
        colors[((index % colors.count) + colors.count) % colors.count]
    }
}

nonisolated struct OwnerWorkplacesRecord: Equatable, Sendable {
    var month: Int
    var entries: [OwnerWorkplaceEntry]
    /// 서버가 준 전체 합계 · 확정 금액(앞 구간) · 남은 예정 금액(뒤 구간)
    var totalAmount: Int
    var confirmedAmount: Int
    var scheduledAmount: Int
    var staffCount: Int
    var workingCount: Int
    var attentionCount: Int
    /// 급여 정산까지 남은 날(0 이하 = D-day)
    var payrollDaysLeft: Int

    var titleText: String { "\(month)월 전체 예상 인건비" }
    var totalText: String { PumFormat.amount(totalAmount) }
    var countText: String { "\(entries.count)곳 · 직원 \(staffCount)명" }
    var workingText: String { "\(workingCount)명" }
    var attentionText: String { "\(attentionCount)건" }
    var dDayText: String { payrollDaysLeft > 0 ? "D-\(payrollDaysLeft)" : "D-day" }

    /// 막대 두 구간 값(음수는 0으로 방어, 합이 0이면 비율 0)
    var barParts: [Int] { [max(0, confirmedAmount), max(0, scheduledAmount)] }
    var barTotal: Int { barParts.reduce(0, +) }
    func barFraction(_ index: Int) -> Double {
        barTotal > 0 ? Double(barParts[index]) / Double(barTotal) : 0
    }

    /// VoiceOver: 요약 카드 한 문장
    var summaryAccessibilityText: String {
        "\(titleText) \(totalText)원, \(entries.count)곳, 직원 \(staffCount)명, 지금 근무 중 \(workingCount)명, 확인 필요 \(attentionCount)건, 급여 정산 \(dDayText)"
    }
    var barAccessibilityText: String {
        "확정 \(PumFormat.amount(confirmedAmount))원, 남은 예정 \(PumFormat.amount(scheduledAmount))원"
    }

    static let sample = OwnerWorkplacesRecord(
        month: 10,
        entries: [
            .init(id: "s1", name: "종민김밥 본점", initial: "종", colorIndex: 0, staffCount: 4, workingCount: 2,
                  expectedAmount: 4_210_000, confirmedAmount: 2_525_000,
                  attentionCount: 4, editRequestCount: 1, substituteCount: 1, invitingCount: 0),
            .init(id: "s2", name: "종민김밥 장유점", initial: "장", colorIndex: 1, staffCount: 3, workingCount: 2,
                  expectedAmount: 3_120_000, confirmedAmount: 1_560_000,
                  attentionCount: 2, editRequestCount: 0, substituteCount: 0, invitingCount: 1),
        ],
        totalAmount: 7_330_000, confirmedAmount: 4_085_000, scheduledAmount: 3_245_000,
        staffCount: 7, workingCount: 4, attentionCount: 6, payrollDaysLeft: 7
    )
}
