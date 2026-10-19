# 코드 규칙 — 폴더 · 이름 · 토큰 · 오류 · 테스트

`AGENTS.md`의 세부 내용이다. 스택은 DEC-008(iOS Swift · Android Kotlin 네이티브, Web TypeScript, Supabase). **iOS Xcode 프로젝트만 있고(`Pum/`) 나머지는 아직 없다. 아래 구조는 처음 만들 때 따를 기준**이다. 실제와 달라지면 이 문서를 먼저 고친다.

## 폴더 구조

현재 iOS 프로젝트: `Pum/Pum.xcodeproj` · 번들 ID `kr.co.lee.Pum` · 최소 iOS 18(DEC-031) · iPhone · iPad · Swift 언어 모드 5.0 (Xcode 26.5, Swift 6.3 컴파일러). 최소 iOS는 DEC-031로 확정, 번들 ID는 미결정(생성 시 기본값).

```
apps/
  ios/                (예정) 현재 iOS는 저장소 루트의 `Pum/`에 있음 — 옮길지 미정
  android/            Gradle 프로젝트 (Jetpack Compose)
  web/                TypeScript 웹 (프레임워크 미정)
supabase/             Supabase CLI 표준 구조
  migrations/         SQL 마이그레이션 (DB 설계서 스키마 8개 기준)
  functions/          Edge Functions (TypeScript)
  seed.sql            로컬 · 테스트용 가짜 데이터만
packages/
  payroll-engine/     급여 계산 순수 함수 (S0–S9) + TC-01–TC-40 테스트
  design-tokens/      토큰 원본(JSON) → Swift · Kotlin · CSS 생성물
docs/                 설계 · 요구사항 · 규칙
```

- 앱 안의 기능 폴더는 **도메인 단위**로 나눈다: `attendance`(출퇴근 · 근무기록), `schedule`, `payroll`(마감 · 급여 · 명세서 · 지급), `comms`(공지 · 요청 · 알림), `org`(사업장 · 인증 · 권한), `account`, `personal`(개인 모드), `contract`. DB 설계서 스키마 이름과 맞춘다.
- 공통 UI 컴포넌트는 디자인 시스템 ID로 묶는다(C1 Button → `PumButton`).

## 이름

| 대상 | iOS (Swift) | Android (Kotlin) | Web (TS) | DB (SQL) |
|---|---|---|---|---|
| 타입 · 클래스 | `UpperCamelCase` | `UpperCamelCase` | `PascalCase` | — |
| 함수 · 변수 | `lowerCamelCase` | `lowerCamelCase` | `camelCase` | — |
| 파일 | 타입 이름과 같게 `ClockInView.swift` | `ClockInScreen.kt` | `kebab-case.ts`, 컴포넌트는 `PascalCase.tsx` | `YYYYMMDDHHMMSS_<설명>.sql` |
| 화면 | `…View` | `…Screen` (Composable) | `…Page` | — |
| 테이블 · 컬럼 | — | — | — | `snake_case`, 스키마.테이블 (DB 설계서 그대로) |
| 상수 · enum 값 | `lowerCamelCase` case | `UPPER_SNAKE` | `UPPER_SNAKE` | 상태 코드는 DB 설계서 값 그대로(`CONTRACT_PENDING` 등) |

- 화면 파일 머리에 디자인 ID를 적는다: `// UI-IOS-1at · REQ-105`.
- 도메인 용어는 설계서 영어 이름을 쓴다: WorkRecord, AttendanceEvent, WorkClosing, Payroll, Payment, Payslip, Employment, Membership, Business, Workplace. 한국어 화면 문구와 섞지 않는다.

## 디자인 토큰

- 원본: Claude Design `tokens/*.css` (etag는 `docs/design/README.md`). 저장소에는 `packages/design-tokens/`에 한 벌만 두고 플랫폼별 코드는 **생성**한다. 생성물을 손으로 고치지 않는다.
- 값은 토큰 이름으로만 쓴다(`PumColor.textPrimary`, `--text-primary`). 화면 코드에 `#171B26`, `14`, `240ms` 같은 숫자를 직접 쓰지 않는다.
- 모서리 · 연파랑은 DEC-005(토큰 값), Web 기준 화면은 DEC-006(1440×900).
- 모션은 M0–M38만, 동작 줄이기(M22) 대체를 함께 구현한다. 햅틱은 M21 매핑만.
- 글꼴은 Pretendard. 아이콘은 iOS = SF Symbols(F8), Android · Web은 미정.

## 오류 처리

- **출퇴근은 막지 않는다.** 네트워크 · 서버 · 점검 · 강제 업데이트 중에도 기기에 저장하고 나중에 전송한다(REQ-029, 6q · 6w · 21n).
- 화면 상태는 디자인 시스템 C12를 따른다: 로딩(0.5초 넘으면 스켈레톤, M32) · 빈 · 오류 · 오프라인 · 권한 · 세션 만료 · 점검. 불러오기 실패는 마지막 화면을 유지하고 다시 시도(M38), 오프라인(6q)과 구분한다.
- 사용자에게 보이는 문구는 디자인 · 개발 명세서 문구를 쓴다. 내부 오류 메시지 · 스택을 화면에 보이지 않는다.
- 오류를 삼키지 않는다. 잡으면 기록(로그 · 활동 기록)하거나 사용자에게 알린다.
- 로그에 개인정보 · 계좌번호 · 주민번호 · 토큰을 남기지 않는다. 이름 · 번호는 가린다.
- 돈이 움직이거나 되돌리기 어려운 동작은 확인 다이얼로그(C10)를 거친다.

## 데이터 · 보안

- 모든 사업장 데이터 테이블은 RLS(`business_id`)를 켠다. 서비스 롤 키는 서버(Edge Functions)에서만 쓴다.
- 계산 결과 · 확정 기록은 덮어쓰지 않고 새 버전으로 남긴다(정정 · 추가만 테이블).
- 운영 데이터는 이 저장소의 코드 · 스크립트로 직접 고치지 않는다. 마이그레이션은 로컬 → 스테이징 → 운영 순서, 운영 적용은 사용자 확인 후.

## 테스트

| 대상 | 최소 기준 | 도구 |
|---|---|---|
| 급여 엔진 | **TC-01–TC-40 전부 통과**(노무 검토 의존 TC는 표시하고 기대값 확정 전까지 보류 사유 기록) | TypeScript 테스트 러너(미정) |
| DB | 마이그레이션 적용 · RLS 정책(다른 사업장 데이터 안 보임) | Supabase CLI 로컬 DB |
| iOS | 도메인 로직 단위 테스트, 핵심 흐름 UI 테스트 | XCTest / Swift Testing |
| Android | 도메인 로직 단위 테스트, 핵심 흐름 UI 테스트 | JUnit · Compose UI Test |
| Web | 컴포넌트 · 흐름 테스트 | 미정 |

- 테스트 데이터는 가짜만 쓴다(실제 이름 · 번호 · 계좌 금지).
- 보고에는 실행한 명령과 결과를 그대로 붙인다. 못 돌렸으면 "미실행"과 이유.
