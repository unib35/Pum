# API 계약 — 최소 범위

실제 기능을 연결하는 데 필요한 것만 적는다. 서버는 Supabase(DEC-008). 테이블 · 타입의 기준은 DB 설계서, 상태 값은 아키텍처 설계서.

## 인증 (REQ-001 · REQ-011)

| 단계 | 앱 인터페이스 (`AuthService`) | Supabase | 상태 |
|---|---|---|---|
| 인증번호 요청 | `requestCode(phone:)` | Auth 전화번호 OTP 발송 | 인터페이스만. **SMS 발송 업체 미정(유료)** |
| 확인 | `verify(phone:code:) → PumSession` | OTP 확인 → access/refresh 토큰 | 인터페이스만 |
| 현재 세션 | `currentSession()` | 저장된 세션 · 자동 갱신 | 인터페이스만 |
| 로그아웃 | `signOut()` | 세션 폐기 | 인터페이스만 |

- 오류(`AuthError`): `invalidPhone` · `invalidCode(remainingAttempts:)` · `codeExpired` · `tooManyAttempts(retryAfter:)` · `network`. 화면 문구는 디자인(2b · 15e)을 따른다.
- 시도 제한: 5번 틀리면 1시간 잠금(21h와 같은 규칙 — 앱 OTP에도 같은 값을 쓸지는 미정).
- 지금 구현: `MockAuthService`(네트워크 없음, 인증번호 `000000`). 미리보기 · 테스트 · 로컬 실행용.
- 토큰은 기기 키체인에만 저장한다. 로그 · 화면에 출력하지 않는다.

## 데이터 (다음 단계)

| 기능 | 테이블(DB 설계서) | 접근 |
|---|---|---|
| 출퇴근 기록 | `attendance.attendance_events`, `attendance.work_records` | 앱 → Supabase(RLS: 본인 · 소속 사업장) |
| 급여 계산 | `payroll.*` + 엔진 | Edge Function(서버에서만 계산, Trace 저장) |

`supabase/` 초기화와 마이그레이션은 아직 하지 않았다(로컬 DB는 Docker 이미지 수 GB 필요 — 실행 전 확인).

## 샘플 데이터

`Pum/Pum/Core/SampleData.swift` — 디자인 예시 값(가짜 이름 · 금액). 실제 개인정보를 넣지 않는다.
