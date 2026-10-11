# AGENTS.md — 품(Pum) 공통 작업 규칙

소규모 사업장 근무·급여 서비스. 이 파일이 모든 AI 도구의 기본 규칙 원본이다. 세부 규칙은 링크한 문서에 있다.

## 기준 문서 (충돌 시 위가 우선)

1. 사용자 결정 — `docs/design/decisions.md` (DEC-nnn)
2. 디자인 원문 — Claude Design 프로젝트 「근무 관리 급여 시스템」, 정리본 `docs/design/README.md`
3. 화면 — `docs/design/screen-index.md` (UI-IOS-1a 형식)
4. 요구사항 — `docs/requirements/traceability.md` (REQ-nnn)
5. 이 저장소 규칙 — `docs/conventions/code.md`, `docs/conventions/git.md`

## 기술 스택 (DEC-008)

| 영역 | 스택 | 위치 |
|---|---|---|
| iOS | Swift · SwiftUI (네이티브) | `Pum/` (Xcode 프로젝트 `Pum.xcodeproj`) |
| Android | Kotlin · Jetpack Compose (네이티브) | `apps/android/` |
| Web (PC·태블릿) | TypeScript — 프레임워크 미정 | `apps/web/` |
| 서버 · DB | Supabase (PostgreSQL · RLS · Auth · Edge Functions/TypeScript) | `supabase/` |
| 급여 계산 엔진 | TypeScript 순수 함수, 서버에서 실행 | `packages/payroll-engine/` |
| 디자인 토큰 | 원본 하나에서 Swift · Kotlin · CSS 생성 | `packages/design-tokens/` |

폴더 · 이름 규칙: `docs/conventions/code.md`.

## 반드시

- **디자인은 그대로 만든다.** 화면은 screen-index의 확정 안을 따르고, 색 · 간격 · 모서리 · 글자 · 모션은 디자인 토큰과 M0–M38 값만 쓴다(하드코딩 금지). 디자인과 다르게 만들어야 하면 멈추고 묻는다.
- **돈은 정수(원), 시간은 Asia/Seoul.** 금액에 부동소수점을 쓰지 않는다. 급여 계산은 엔진 한 곳에서만 하고 계산 근거(Trace)를 남긴다.
- **출퇴근 기록은 어떤 오류에서도 막지 않는다.** 오프라인 · 점검 · 강제 업데이트 중에도 기기에 저장 후 전송한다(REQ-029).
- **작업 단위는 이슈 하나.** 코드 · 커밋에 관련 REQ · UI ID를 적는다.
- **완료 보고 전에 검증한다.** 실제로 실행한 빌드 · 테스트 명령과 결과를 적고, 실행하지 않았으면 "미실행"이라고 쓴다.
- 결과 보고 순서: 수행 / 검증 / 차단 / 내가 할 일 / 다음 단계.

## 금지

- 승인 없는 디자인 변경(UI 재설계 · 문구 변경 · 토큰 밖 값)
- 요청과 무관한 리팩터링 · 이름 변경 · 포맷 일괄 변경
- 운영 데이터 수정 · 운영 배포 · 결제 · 권한 확대 — 사용자 확인 필수
- 비밀값 노출 — 키 · 토큰 · 비밀번호를 코드 · 로그 · 커밋 · 이슈에 쓰지 않는다. 변수 이름만 `.env.example`
- 법정 수당을 피하도록 유도하는 추천 · 문구(REQ-051)
- 검증 없는 "완료" 보고, 읽지 않은 자료를 읽었다고 하기
- `git push --force`, `git reset --hard`, 남의 미커밋 변경 삭제

## Git

GitHub Flow. 브랜치 `feat/<issue>-<slug>` · `fix/<issue>-<slug>`, Conventional Commits, **커밋 요약 · 본문은 한국어**. 상세: `docs/conventions/git.md`.

## 미결정 (정해지기 전에 임의로 정하지 않는다)

웹 프레임워크 · 최소 OS 버전(현재 Xcode 값 iOS 26.5) · 번들 ID(현재 `kr.co.lee.Pum`) · iOS 폴더를 `apps/ios/`로 옮길지 · 노무 검토 항목(개발 명세서 부록 B) · Android 사장님 기능(Q9) · README 충돌 표의 미결정 항목.
