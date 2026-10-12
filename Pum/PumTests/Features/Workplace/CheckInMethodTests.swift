// UI-IOS-10l · REQ-020 · REQ-021 — 출근 확인 방식: 원문 값 · 방식 · 반경 선택 · 저장 · 한 번만 저장 · 음성 안내문
import Testing
@testable import Pum

struct CheckInMethodTests {
    @Test func 캡처_상태는_원문_값() {
        let s = CheckInMethodState.sample
        #expect(s.options.map(\.title) == ["QR + 위치", "위치만", "QR만", "관리자 확인", "공용기기"])
        #expect(s.options[0].badge == CheckInBadge(text: "추천", tone: .recommended))
        #expect(s.options[4].badge == CheckInBadge(text: "기기가 있을 때", tone: .neutral))
        #expect(s.options[2].detail == "위치 권한 없이 · 사진 QR로도 출근될 수 있어요")
        #expect(s.radiusChoices == [50, 100, 200])
        #expect(s.policy == CheckInPolicy(method: .qrAndLocation, radiusMeters: 100))
        #expect(s.address == "양화로 12" && s.fallbackValue == "사장님에게 확인 요청" && s.qrValue == "PDF · 이미지 저장")
        #expect(CheckInMethodState.notice == "근무 중에는 위치를 수집하지 않아요 · 출퇴근 순간 1회")
    }

    @Test func 위치를_쓰는_방식은_둘() {
        #expect(CheckInMethodKind.qrAndLocation.usesLocation)
        #expect(CheckInMethodKind.locationOnly.usesLocation)
        #expect(!CheckInMethodKind.qrOnly.usesLocation)
        #expect(!CheckInMethodKind.adminConfirm.usesLocation)
        #expect(!CheckInMethodKind.sharedDevice.usesLocation)
    }

    @Test func 방식_선택_서버가_막은_것은_바꾸지_않는다() {
        var d = CheckInMethodDraft(CheckInMethodState.sample.policy)
        var shared = CheckInMethodState.sample.options[4]
        shared.isAvailable = false
        d.select(shared)
        #expect(d.method == .qrAndLocation)
        shared.isAvailable = true
        d.select(shared)
        #expect(d.method == .sharedDevice)
    }

    @Test func 반경은_서버_선택지만_받는다() {
        var d = CheckInMethodDraft(CheckInMethodState.sample.policy)
        d.selectRadius(75, in: .sample)
        #expect(d.radiusMeters == 100)
        d.selectRadius(200, in: .sample)
        #expect(d.radiusMeters == 200)
    }

    @Test func 바뀐_게_없으면_저장_못_함() {
        var d = CheckInMethodDraft(CheckInMethodState.sample.policy)
        #expect(!d.canSave(for: .sample))
        d.selectRadius(50, in: .sample)
        #expect(d.canSave(for: .sample))
        d.selectRadius(100, in: .sample)
        #expect(!d.canSave(for: .sample))
    }

    @Test func 저장하는_값은_방식과_반경() {
        var d = CheckInMethodDraft(CheckInMethodState.sample.policy)
        d.select(CheckInMethodState.sample.options[1])
        d.selectRadius(200, in: .sample)
        #expect(d.policy == CheckInPolicy(method: .locationOnly, radiusMeters: 200))
    }

    @Test func 저장은_처리_중에만_한_번() {
        var lock = CheckInMethodLock()
        let first = lock.begin()
        let second = lock.begin()
        #expect(first && !second)
        lock.finish(success: true)
        #expect(!lock.isSaving) // 성공 뒤에도 풀린다
        lock.finish(success: false)
        #expect(!lock.isSaving)
        let again = lock.begin()
        #expect(again)
    }

    @Test func 음성_안내문() {
        let s = CheckInMethodState.sample
        #expect(s.optionAccessibility(s.options[0], isOn: true)
                == "QR + 위치, 추천, 매장 QR로 사업장 확인 + 반경 안인지 확인, 선택됨, 5개 중 1번째")
        #expect(s.optionAccessibility(s.options[1], isOn: false)
                == "위치만, 반경 안에서 출근 버튼 · 사장님이 함께 일하는 매장, 5개 중 2번째")
        #expect(CheckInMethodState.radiusAccessibility(100, isOn: true) == "허용 반경, 100m, 선택됨")
        #expect(CheckInMethodState.radiusAccessibility(50, isOn: false) == "허용 반경, 50m, 선택 안 됨")
    }
}
