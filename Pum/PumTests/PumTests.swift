//
//  PumTests.swift
//  PumTests
//
//  Created by 이종민 on 10/11/26.
//

import Testing
import SwiftUI
@testable import Pum

struct TokenTests {
    @Test func 모서리는_토큰_값() {
        #expect(PumTokens.Radius.md == 12)
        #expect(PumTokens.Radius.lg == 14)
        #expect(PumTokens.Radius.xl == 16)
    }

    @Test func 크기() {
        #expect(PumTokens.Size.buttonH == 54)
        #expect(PumTokens.Size.buttonHSm == 44)
        #expect(PumTokens.Size.tapMin == 44)
    }

    @Test func 모션_시간() {
        #expect(PumTokens.Duration.press == 0.1)
        #expect(PumTokens.Duration.fast == 0.16)
        #expect(PumTokens.Duration.base == 0.24)
        #expect(PumTokens.Duration.sheet == 0.32)
        #expect(PumTokens.Duration.toastHold == 3)
    }

    @Test func 글자_11단계() {
        #expect(PumTextStyle.allCases.count == 11)
        #expect(PumTextStyle.body.token.size == 15)
        #expect(PumTextStyle.headline.token.weight == .semibold)
    }
}

struct FormatTests {
    @Test func 금액() {
        #expect(PumFormat.amount(1_188_000) == "1,188,000")
        #expect(PumFormat.amount(0) == "0")
        #expect(PumFormat.deduction(33_410) == "\u{2212}33,410")
    }

    @Test func 근무_시간() {
        #expect(PumFormat.duration(minutes: 303) == "5시간 03분")
        #expect(PumFormat.duration(minutes: 45) == "45분")
    }

    @Test func 시간_범위() {
        #expect(PumFormat.timeRange("17:00", "22:00") == "17:00 \u{2013} 22:00")
    }
}

struct BadgeTests {
    @Test func 상태_색은_의미대로() {
        #expect(PumBadge(text: "확정", kind: .done).colors.bg == PumColor.statusDoneSoft)
        #expect(PumBadge(text: "확인 필요", kind: .attention).colors.fg == PumColor.statusAttention)
        #expect(PumBadge(text: "진행", kind: .active).colors.bg == PumColor.accentSoft)
    }
}

@MainActor
struct AuthTests {
    @Test func 휴대폰_번호_형식() {
        #expect(MockAuthService.isValidKoreanMobile("010-1234-5678"))
        #expect(!MockAuthService.isValidKoreanMobile("02-123-4567"))
        #expect(!MockAuthService.isValidKoreanMobile("010 1234 5678"))
    }

    @Test func 인증번호_확인() async throws {
        let auth = MockAuthService()
        try await auth.requestCode(phone: "010-1234-5678")
        await #expect(throws: AuthError.invalidCode(remainingAttempts: 4)) {
            try await auth.verify(phone: "010-1234-5678", code: "111111")
        }
        let session = try await auth.verify(phone: "010-1234-5678", code: MockAuthService.testCode)
        #expect(await auth.currentSession() == session)
        await auth.signOut()
        #expect(await auth.currentSession() == nil)
    }
}

struct FontTests {
    @Test func 프리텐다드_5종_등록() {
        #expect(PumFont.register().isEmpty)
        for face in PumFont.faces {
            #expect(UIFont(name: face.postScriptName, size: 15) != nil, "\(face.postScriptName) 없음")
        }
    }

    @Test func 굵기별_글꼴_파일() {
        #expect(PumFont.postScriptName(for: .semibold) == "Pretendard-SemiBold")
        #expect(PumFont.postScriptName(for: .bold) == "Pretendard-Bold")
    }
}

struct OwnerComponentTests {
    @Test func 아바타_6색_순환() {
        #expect(PumAvatarPalette.people.count == 6)
        #expect(PumAvatarPalette.person(index: 6) == PumAvatarPalette.person(index: 0))
        #expect(PumAvatarPalette.person(index: -1) == PumAvatarPalette.person(index: 5))
    }

    @Test func 작은_버튼_색은_의미대로() {
        #expect(PumChipButton(title: "인정", kind: .accent) {}.colors.bg == PumColor.accentSoft)
        #expect(PumChipButton(title: "퇴근 확인", kind: .attention) {}.colors.fg == PumColor.statusAttention)
    }

    @Test func 사장님_탭_4개와_배지() {
        let tabs = PumTabItem.ownerTabs(workBadge: 4)
        #expect(tabs.map(\.title) == ["홈", "근무", "급여", "사업장"])
        #expect(tabs.first { $0.id == "work" }?.badge == 4)
        #expect(PumTabItem.employeeTabs.allSatisfy { $0.badge == 0 })
    }
}

struct AvatarInitialTests {
    @Test func 이름_첫_글자() {
        #expect(PumAvatar.initial(for: "김하늘") == "하")
        #expect(PumAvatar.initial(for: "박서준") == "서")
        #expect(PumAvatar.initial(for: "하") == "하")
        #expect(PumAvatar.initial(for: "남궁민수") == "남")
        #expect(PumAvatar.initial(for: "Alex") == "A")
    }
}
