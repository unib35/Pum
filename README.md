# 품(Pum) — 소규모 사업장 근무 · 급여

출퇴근 기록부터 급여 계산 · 명세서 · 지급 처리까지. 설계는 Claude Design 프로젝트 「근무 관리 급여 시스템」, 정리본은 [`docs/design/`](docs/design/README.md).

- 작업 규칙: [`AGENTS.md`](AGENTS.md) · 코드 규칙 [`docs/conventions/code.md`](docs/conventions/code.md) · Git [`docs/conventions/git.md`](docs/conventions/git.md)
- 요구사항 추적: [`docs/requirements/traceability.md`](docs/requirements/traceability.md)

## 지금 있는 것

| 영역 | 상태 |
|---|---|
| iOS 앱 (`Pum/`) | 디자인 토큰 · 공통 컴포넌트(C1 · C2 · C5 · C11 · C12) · 컴포넌트 갤러리 · 인증 인터페이스(가짜 구현) |
| 디자인 토큰 (`packages/design-tokens/`) | Claude Design `tokens/*.css` → iOS Swift · JSON 생성 |
| Android · Web · Supabase | 아직 없음 |

## 필요한 도구 (확인한 버전)

| 도구 | 버전 | 용도 |
|---|---|---|
| Xcode | 26.5 (Swift 6.3.2 컴파일러, 프로젝트 언어 모드 Swift 5) | iOS 빌드 · 테스트 |
| iOS 시뮬레이터 | iOS 26.5 · iPhone 17 | 최소 지원 iOS 26.5(프로젝트 기본값, 미확정) |
| Node.js | 26.5.0 (필요 ≥ 22) | 토큰 생성 · 테스트(외부 패키지 없음) |
| Supabase CLI | 2.109.1 | 서버(아직 미사용) |

## 명령

### 디자인 토큰

```sh
cd packages/design-tokens
npm run build   # src/*.css → dist/tokens.json, Pum/Pum/DesignSystem/Generated/PumTokens.swift
npm run check   # 생성물이 원본과 같은지 검사(다르면 실패)
npm test        # 파서 · 값 테스트
```

토큰을 바꾸려면 Claude Design의 `tokens/*.css`를 `src/`에 그대로 복사하고 `npm run build`. 생성물(`PumTokens.swift`, `dist/`)을 손으로 고치지 않는다.

### iOS

```sh
cd Pum
# 빌드
xcodebuild -project Pum.xcodeproj -scheme Pum -destination 'platform=iOS Simulator,name=iPhone 17' build
# 단위 테스트 (Swift Testing)
xcodebuild -project Pum.xcodeproj -scheme Pum -destination 'platform=iOS Simulator,name=iPhone 17' test -only-testing:PumTests
```

- 실행하면 컴포넌트 갤러리가 뜬다. 섹션으로 바로 가기: 실행 인자 `-PumGalleryAnchor C12` (C1 · C2 · C5 · F4 · C12 · C11).
- 디자인 비교 자료: [`docs/design/compare/`](docs/design/compare/README.md)

## 테마 · 글꼴 · 접근성

| 항목 | 기준 |
|---|---|
| 테마 | 라이트만. 디자인에 다크 모드 값이 없어 `.preferredColorScheme(.light)`로 고정(다크 모드는 디자인 결정 필요) |
| 글꼴 | Pretendard v1.3.9 정적 5종(Regular · Medium · SemiBold · Bold · ExtraBold)을 앱에 포함, 실행 시 등록. 라이선스 SIL OFL 1.1 (`Pum/Pum/Resources/Fonts/Pretendard-LICENSE.txt`) |
| 글자 크기 | 디자인 11단계를 iOS 텍스트 스타일에 묶어 동적 글자 크기를 따른다. 숫자는 고정폭(F4) |
| 터치 영역 | 최소 44pt(`--tap-min`) |
| 동작 줄이기 | M22 — 이동 · 크기 변화 대신 페이드, 스켈레톤 깜빡임 정지, 누름 축소 없음 |
| VoiceOver | 배지는 「상태: …」, 토스트는 안내 방송, 스켈레톤은 「불러오는 중」 |
| 로딩 · 빈 · 오류 | C12 · M8 · M32: 0.5초 넘으면 스켈레톤, 반짝임 없음 / 그림 없이 제목 · 이유 · 행동 하나 |
