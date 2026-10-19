# MVP 출시 준비

계획: [README.md](README.md) 단계 5. 앱 이름 「품」, 분류 비즈니스, iPhone 세로 고정, 최소 iOS 18.

## 코드 · 설정에서 한 것

| 항목 | 값 | 위치 |
|---|---|---|
| 표시 이름 | 품 | Xcode `INFOPLIST_KEY_CFBundleDisplayName` |
| 분류 | 비즈니스 | `INFOPLIST_KEY_LSApplicationCategoryType` |
| 화면 방향 | iPhone 세로만(디자인이 세로 기준) | `INFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone` |
| 암호화 신고 | 표준 암호화 외 없음(`ITSAppUsesNonExemptEncryption = NO`) | Xcode 설정 |
| 개인정보 매니페스트 | 추적 없음 · 수집 없음 · UserDefaults(CA92.1, 앱 자체 설정 읽기) | `Pum/Pum/Resources/PrivacyInfo.xcprivacy` |
| 개발용 화면 | 출시 빌드에 없음(`#if DEBUG`) | `ContentView` · `DevLauncher` |

## App Store 「앱 개인정보」 답(초안)

- 데이터 수집: **수집하지 않음**. 모든 기록은 기기와 사용자 본인의 iCloud(개인 데이터베이스)에만 저장되고 개발자 서버로 보내지 않는다(DEC-030).
- 추적: 없음. 광고 · 분석 SDK 없음.

## 개인정보 처리방침(초안 — 공개 URL 필요)

> 품(이하 「앱」)은 사업주가 직원 근무와 월급을 기록 · 계산하는 앱입니다.
>
> 1. 처리하는 정보: 사업장 이름 · 급여일, 직원 이름 · 휴대폰 번호(선택) · 입사일 · 근로조건 · 근무 기록 · 계약서 사진(선택), 계산된 급여명세서.
> 2. 저장 위치: 이 정보는 사용자의 기기와 사용자 본인의 iCloud 계정(Apple CloudKit 개인 데이터베이스)에만 저장됩니다. 개발자는 이 정보를 받거나 볼 수 없습니다.
> 3. 제3자 제공: 없습니다. 사용자가 명세서 PDF를 직접 공유할 때만 사용자가 고른 앱(카카오톡 · 메일 등)으로 전달됩니다.
> 4. 보관 · 삭제: 앱에서 직원 · 사업장을 지우거나 앱을 삭제하면 기기에서 지워집니다. iCloud 사본은 iPhone 설정 › Apple 계정 › iCloud › 저장 공간 관리에서 지울 수 있습니다.
> 5. 직원 정보: 사업주는 직원 정보를 앱에 입력하기 전에 근로자에게 처리 목적을 알려야 합니다(개인정보 보호법).
> 6. 문의: (연락처 이메일)

## 사용자가 할 일

1. 번들 ID 확정(지금 `kr.co.lee.Pum`, 미결정) — App Store Connect에 앱을 만들기 전에.
2. iCloud 컨테이너 만들기 + Xcode에서 iCloud(CloudKit) · Background Modes(Remote notifications) 추가([data-model.md](data-model.md)). 출시 전 CloudKit 스키마를 Production으로 배포.
3. 앱 아이콘 1024×1024(디자인 원문에 아이콘이 없어 비워 둠) — 기본 · 다크 · 틴트.
4. 개인정보 처리방침을 공개 URL에 올리고 연락처를 채우기.
5. 출시 전 노무사 확인: [payroll-rules.md](payroll-rules.md) 「노무 검토 필요」 항목.
6. App Store 스크린샷 · 설명 · 키워드, TestFlight 업로드(Archive → Distribute).
