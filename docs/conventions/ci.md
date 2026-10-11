# CI — 검사 목록과 실행 절차

원칙: **실제로 있는 검사만** 돌린다. 없는 명령을 성공 처리하거나 `--if-present` 등으로 건너뛰지 않는다. 로컬과 CI는 같은 스크립트(`.claude/skills/finish-feature/scripts/verify.sh`)를 쓴다.

## 검사 목록

| 검사 | 명령 | PR CI | 로컬 | 상태 |
|---|---|---|---|---|
| 토큰 테스트 | `npm --prefix packages/design-tokens test` | ✅ Linux · Node 22 | ✅ | 사용 중 |
| 토큰 생성물 최신 | `npm --prefix packages/design-tokens run check` | ✅ Linux · Node 22 | ✅ | 사용 중 |
| 자동화 파일 | `verify.sh claude` (스크립트 문법 · `settings.json` · hook 출력) | ✅ Linux | ✅ | 사용 중 |
| iOS 빌드 · 단위 테스트 | `verify.sh ios` (`xcodebuild test -only-testing:PumTests`) | 수동만(`workflow_dispatch`, ios 체크) | ✅ **기준** | 로컬 필수 |
| iOS UI 테스트 | `verify.sh ios-ui` | 없음 | 선택 | 템플릿 테스트뿐 |
| Swift lint · format | — | 없음 | 없음 | **미설정** — swiftlint 0.x · swiftformat · swift-format이 설치돼 있지만 규칙 파일이 없다. 규칙을 정한 뒤 추가 |
| 타입 검사(TS) | — | 없음 | 없음 | 해당 없음 — TypeScript 코드가 아직 없음(토큰 생성기는 JS) |
| Android · Web · DB · 급여 엔진 | — | 없음 | 없음 | 코드 없음 |

## PR 전에 로컬에서

```sh
# 바뀐 영역만 (finish-feature가 영역을 알려준다)
sh .claude/skills/finish-feature/scripts/verify.sh tokens claude ios
```

- iOS는 **로컬 결과를 PR 본문에 붙인다**(PR 템플릿 「테스트」). CI가 iOS를 PR마다 돌리지 않으므로 이것이 기준이다.
- 시뮬레이터: 기본 `iPhone 17`. 다른 세션 · 에이전트가 테스트 중이면 같은 시뮬레이터를 쓰지 말고 `PUM_SIM="iPhone Air"`처럼 나눈다(동시에 쓰면 앱 실행 실패 · 검은 화면이 났다, 2026-10-12).
- 병렬 테스트는 끈다(`-parallel-testing-enabled NO`) — 켜면 시뮬레이터 복제 실패가 났다.

## 실행 기록

| 날짜 | 환경 | 명령 | 결과 | 시간 |
|---|---|---|---|---|
| 2026-10-12 | 로컬 macOS · Node 26.5 · Xcode 26.5 · iPhone Air(iOS 26.5) | `verify.sh tokens claude ios` | PASS 4 (tokens-test · tokens-check · claude · ios) | 9분 52초 (다른 세션 빌드와 동시 실행) |
| 2026-10-12 | GitHub Actions ubuntu-latest · Node 22 | PR #4 `tokens` · `automation` | PR 결과 참고 | — |
| — | GitHub Actions macos-latest | `ios` (수동) | **미실행** | — |

## 비용 · 사용량

- 이 저장소는 **public**이라 GitHub 표준 runner(Linux · macOS) 사용 시간은 무료다. private로 바꾸면 무료 한도에서 차감되고 macOS는 Linux보다 훨씬 비싸게 계산된다 — 그때 이 표를 다시 본다.
- PR마다 도는 작업: Linux 2개 · 각 5분 제한(보통 1분 미만 예상). 같은 브랜치에 새로 push하면 이전 실행은 취소된다(`concurrency`).
- iOS 작업은 수동 실행만. macOS runner에 Xcode 26.5가 없으면 **실패로 끝난다**(건너뛰지 않음). runner 이미지의 Xcode · 시뮬레이터 버전은 아직 확인하지 않았다.

## 실패했을 때

- 검사를 약하게 만들어 통과시키지 않는다(테스트 삭제 · 기대값 변경 · `continue-on-error` 금지). 원인을 고치거나, 고칠 수 없으면 PR에 「차단」으로 적는다.
- 토큰 생성물 불일치: `npm --prefix packages/design-tokens run build` 후 생성물을 커밋.
