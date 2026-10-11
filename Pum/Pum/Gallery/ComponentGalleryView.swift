// 개발용 컴포넌트 갤러리 — 디자인 시스템(디자인 시스템.dc.html)과 나란히 비교하기 위한 화면
import SwiftUI

struct ComponentGalleryView: View {
    @State private var isConfirming = false
    @State private var isLoadingHome = true
    @State private var toast: String?

    /// 개발용: `-PumGalleryAnchor C12` 로 실행하면 그 섹션으로 이동(비교 캡처용)
    private let anchor = UserDefaults.standard.string(forKey: "PumGalleryAnchor")

    var body: some View {
        ScrollViewReader { proxy in
        ScrollView {
            VStack(alignment: .leading, spacing: PumTokens.Space.s24) {
                Text("컴포넌트").pumText(.title1).foregroundStyle(PumColor.textPrimary)

                section("C1 Button") {
                    PumButton(title: "출근하기") {}
                    PumButton(title: "저장", kind: .dark) {}
                    PumButton(title: "스케줄 전체", kind: .outline) {}
                    PumButton(title: "거절", kind: .dangerOutline) {}
                    PumButton(title: "급여 확정하기 · 미처리 2건 남음") {}.disabled(true)
                    PumButton(title: "나중에 할게요", kind: .text) {}
                    PumButtonPair(negative: "거절", positive: "승인 · 22:30으로 확정", onNegative: {}, onPositive: {})
                    HStack(spacing: PumTokens.Space.s8) {
                        PumButton(title: "수정", kind: .outline, size: .small) {}.fixedSize()
                        PumButton(title: "15:00 기록", kind: .dark, size: .small) {}.fixedSize()
                        PumButton(title: "인정", size: .small) {}.fixedSize()
                    }
                    PumButton(title: "확정하기", isLoading: isConfirming, loadingTitle: "확정하는 중") {
                        isConfirming = true
                        Task { try? await Task.sleep(for: .seconds(2)); isConfirming = false }
                    }
                }

                section("C2 Status Badge") {
                    HStack(spacing: PumTokens.Space.s6) {
                        PumBadge(text: "예정", kind: .waiting)
                        PumBadge(text: "근무 중", kind: .active)
                        PumBadge(text: "확정", kind: .done)
                    }
                    HStack(spacing: PumTokens.Space.s6) {
                        PumBadge(text: "확인 필요", kind: .attention)
                        PumBadge(text: "거절", kind: .problem)
                        PumBadge(text: "취소", kind: .closed)
                    }
                }

                section("C5 Card · Row · Section") {
                    PumSectionHeader(title: "10월 3일 근무")
                    PumCard {
                        PumRow("예정", value: PumFormat.timeRange(SampleData.scheduledStart, SampleData.scheduledEnd))
                        PumRow("실제", value: PumFormat.timeRange(SampleData.actualStart, SampleData.actualEnd))
                        PumRow("인정", value: PumFormat.duration(minutes: SampleData.recognizedMinutes))
                        PumRow(title: "계산 근거", showsChevron: true, isLast: true) { EmptyView() }
                    }
                    PumSectionHeader(title: "결정이 필요해요", attention: true)
                    PumCard(attention: true) {
                        PumRow(title: "퇴근 미확정", subtitle: "10월 2일 · 예정 22:00", isLast: true) {
                            PumBadge(text: "확인 필요", kind: .attention)
                        }
                    }
                }

                section("F4 Numbers") {
                    PumCard {
                        PumRow("10월 급여", value: PumFormat.amount(SampleData.octoberPay) + "원")
                        PumRow("공제", value: PumFormat.deduction(SampleData.deduction) + "원", isLast: true)
                    }
                }

                section("C12 System States · M8 · M32") {
                    PumCard {
                        PumLoadingContainer(isLoading: isLoadingHome) {
                            PumRow("오늘 근무", value: PumFormat.timeRange("17:00", "22:00"), isLast: true)
                        } placeholder: {
                            VStack(alignment: .leading, spacing: PumTokens.Space.s8) {
                                PumSkeletonBlock(width: 120)
                                PumSkeletonBlock(width: 200)
                            }
                            .padding(PumTokens.Space.s16)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    PumButton(title: isLoadingHome ? "불러오기 끝내기" : "다시 불러오기", kind: .outline, size: .small) {
                        isLoadingHome.toggle()
                    }
                    PumCard {
                        PumStateView(title: PumStateCopy.empty.title, reason: PumStateCopy.empty.reason,
                                     actionTitle: "출근 QR 찍기") {}
                            .padding(PumTokens.Space.s16)
                    }
                    PumCard {
                        PumStateView(title: PumStateCopy.loadFailed.title, reason: PumStateCopy.loadFailed.reason,
                                     actionTitle: PumStateCopy.loadFailed.action) {}
                            .padding(PumTokens.Space.s16)
                    }
                }

                section("C6 · C7 · SMALL") {
                    HStack {
                        PumWorkplaceChip(name: "종민김밥 본점", initial: "종", tileColor: PumColor.surfaceInverse, role: "사장님") {}
                        Spacer()
                    }
                    HStack(spacing: PumTokens.Space.s8) {
                        ForEach(0..<6, id: \.self) { i in PumAvatar(name: ["종", "하", "유", "서", "우", "박"][i], colorIndex: i) }
                        PumCountTile(count: 4)
                    }
                    HStack(spacing: PumTokens.Space.s8) {
                        PumChipButton(title: "인정", kind: .accent) {}
                        PumChipButton(title: "처리", kind: .neutral) {}
                        PumChipButton(title: "퇴근 확인", kind: .attention) {}
                    }
                    PumTabBar(items: PumTabItem.ownerTabs(workBadge: 4), selection: .constant("home"))
                }

                section("C11 Toast") {
                    PumToast(message: "출근했어요 · 16:58", systemImage: "checkmark")
                    PumToast(message: "수정 요청을 보냈어요", actionTitle: "실행 취소") {}
                    PumToast(message: "오프라인 · 연결되면 전송돼요", systemImage: "wifi.slash", iconColor: PumTokens.ColorToken.amber200)
                    PumButton(title: "토스트 띄우기", kind: .outline, size: .small) { toast = "수정 요청을 보냈어요" }
                }
            }
            .padding(PumTokens.Size.screenPad)
        }
        .background(PumColor.bgApp)
        .onAppear { if let anchor { proxy.scrollTo(anchor, anchor: .top) } }
        }
        .pumToast($toast)
    }

    private func section<C: View>(_ title: String, @ViewBuilder _ content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: PumTokens.Space.s10) {
            Text(title).pumText(.caption2).foregroundStyle(PumColor.textTertiary)
            content()
        }
        .id(String(title.split(separator: " ").first ?? ""))
    }
}

#Preview("라이트") { ComponentGalleryView() }
#Preview("큰 글자") { ComponentGalleryView().dynamicTypeSize(.accessibility2) }
