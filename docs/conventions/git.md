# Git 규칙 — GitHub Flow

저장소: https://github.com/unib35/Pum (public) · 기본 브랜치 `main`

## 흐름

1. 작업마다 GitHub 이슈를 먼저 만든다. 이슈 번호가 브랜치 이름에 들어간다.
2. 최신 `main`에서 브랜치를 만든다.
   ```sh
   git switch main && git pull --ff-only
   git switch -c feat/12-clock-in-qr
   ```
3. 작은 단위로 커밋한다(아래 Conventional Commits).
4. 브랜치를 push하고 `main`으로 PR을 연다. PR 템플릿(`.github/pull_request_template.md`)을 채운다.
5. 검토 → 확인 항목 통과 → **Squash and merge** → 브랜치 삭제.
6. `main`은 언제나 배포 가능한 상태로 둔다. 기본은 PR을 거친다. 예외는 아래 「main 직접 push」.

### main 직접 push (1인 개발 기간 예외 · 2026-10-12 사용자 결정)

속도가 우선인 작은 작업은 브랜치 · PR 없이 `main`에 커밋하고 바로 push해도 된다. 조건:

- push 전에 `check.sh`(커밋 형식 · 비밀값)와 바뀐 영역의 `verify.sh`가 통과해야 한다. 실패하면 push하지 않는다. public 저장소라 push하면 바로 공개된다.
- 커밋 꼬리말에 이슈가 있으면 `Refs #N`을 적는다.
- `--force` 금지(위 「금지」 그대로).
- 디자인 변경 · 결제 · 운영 배포 · 권한 · 데이터 삭제가 들어간 변경, 여러 도메인에 걸친 큰 변경은 예외로 하지 않고 PR을 연다.
- 협업자가 생기거나 `main` 보호 설정을 켜면 이 예외는 없앤다.

## 브랜치 이름

| 종류 | 형식 | 예 |
|---|---|---|
| 기능 | `feat/<issue>-<slug>` | `feat/12-clock-in-qr` |
| 버그 수정 | `fix/<issue>-<slug>` | `fix/31-payslip-rounding` |

- `<issue>` = GitHub 이슈 번호(숫자만). `<slug>` = 영어 소문자·숫자·하이픈, 3–5단어.
- 문서·설정처럼 기능도 버그도 아닌 작업은 같은 형식으로 `docs/<issue>-<slug>`, `chore/<issue>-<slug>`를 쓴다. _(제안 — 확정 규칙은 feat · fix 두 가지)_
- 한 브랜치는 한 이슈만 다룬다.

## 커밋 메시지 — Conventional Commits 1.0

```
<type>(<scope>): <요약>

<본문: 무엇을 왜 바꿨는지>

<꼬리말: Refs #12 · BREAKING CHANGE: ... · Co-Authored-By: ...>
```

| type | 쓰는 때 |
|---|---|
| `feat` | 사용자에게 보이는 새 기능 |
| `fix` | 버그 수정 |
| `docs` | 문서만 |
| `refactor` | 동작이 같은 구조 변경 |
| `test` | 테스트 추가·수정 |
| `chore` | 빌드·설정·의존성 등 |
| `ci` | CI 설정 |
| `perf` | 성능 개선 |
| `style` | 포맷만(동작 변화 없음) |

- `<scope>`는 선택. 도메인 이름을 쓴다: `attendance`, `payroll`, `schedule`, `comms`, `org`, `account`, `design` 등.
- **요약 · 본문은 한국어로 쓴다.** `type`과 `scope`만 영어로 둔다. 요약은 72자 이내, 마침표 없음.
- 이슈 연결: 꼬리말에 `Refs #12`(관련) 또는 `Closes #12`(머지 시 닫힘).
- 호환이 깨지는 변경: `feat!:` 또는 꼬리말 `BREAKING CHANGE:`.
- AI가 함께 작성한 커밋은 꼬리말에 `Co-Authored-By:`를 남긴다.

예:
```
feat(attendance): QR + 위치로 출근 판정

QR은 사업장 확인, 위치는 근처인지 확인. 정확도 100m 초과는 판정 보류.
요구사항 REQ-022, 화면 UI-IOS-10t · 10u · 21m.

Closes #12
```

## 금지

- `git push --force` / `--force-with-lease`를 공유 브랜치(`main`)에 하지 않는다. 개인 작업 브랜치에서 꼭 필요하면 PR에 이유를 적는다.
- `git reset --hard`, `git clean -fd` 등으로 다른 사람(또는 아직 커밋하지 않은) 변경을 지우지 않는다.
- 비밀값을 커밋하지 않는다. `.env`는 `.gitignore`에 있고, 필요한 변수 이름만 `.env.example`에 적는다.
- 실수로 비밀값을 커밋했다면: **커밋을 지우는 것보다 먼저 그 값을 폐기·재발급**한다. 이 저장소는 public이라 push된 순간 노출된 것으로 본다. 이력 정리는 그다음, 사용자 확인 후.

## 보호 설정

### 지원 여부 (2026-10-11 확인)

| 항목 | 결과 | 근거 |
|---|---|---|
| 계정 · 저장소 | 개인 계정 `unib35`, **public** 저장소 | `gh repo view` |
| 현재 보호 | 없음 — `main` 보호 규칙 없음, ruleset 0개 | `gh api .../branches/main/protection` → 404 "Branch not protected", `.../rulesets` → `[]` |
| 보호 브랜치 사용 가능 여부 | **사용 가능으로 판단** | GitHub 문서: Free는 public 저장소에 "full feature set". 미지원 저장소는 이 API가 403(업그레이드 안내)을 돌려주는데, 이 저장소는 404(미설정)를 돌려줬다. |
| private로 바꾸면 | Free 개인 계정의 private 저장소는 보호 브랜치 · 필수 리뷰어 · CODEOWNERS가 Pro 기능으로 분류됨 | GitHub 플랜 문서 |
| 1인 저장소의 필수 승인 | PR 작성자는 자기 PR을 승인할 수 없다. 「Require approvals 1」을 켜면 혼자서는 머지할 수 없고, 관리자 우회(bypass)를 허용해야 한다. | GitHub 보호 브랜치 문서(승인은 다른 사람이어야 함) |

### 권장 설정 (적용은 사용자 확인 후)

`main` 브랜치에:
- Require a pull request before merging — 켬, **필수 승인 수 0**(1인 저장소이므로)
- Block force pushes — 켬
- Restrict deletions — 켬
- Require linear history — 켬(Squash merge와 맞춤)
- Require status checks — CI를 만든 뒤 켬
- 저장소 설정: Squash merge만 허용, 「Automatically delete head branches」 켬

이 설정은 저장소 권한 변경이라 **사용자 확인 후** 적용한다.

### 수동 검토 절차 (필수 승인을 쓸 수 없는 동안)

1. PR을 열고 최소 한 번은 **다른 시점에** 변경 파일 전체를 다시 본다(작성 직후 바로 머지하지 않는다).
2. PR 템플릿의 확인 항목을 모두 체크한다. 체크하지 못한 항목은 이유를 적는다.
3. 실행한 테스트 명령과 결과를 PR 본문에 붙인다. 실행하지 않았으면 "미실행"이라고 적는다.
4. 비밀값 검사: `git diff main...HEAD`에서 키 · 토큰 · 비밀번호 · 실제 개인정보가 없는지 확인한다.
5. 결제 · 운영 배포 · 권한 변경 · 데이터 삭제가 들어간 PR은 머지 전에 한 번 더 확인하고, PR에 "고위험" 라벨을 붙인다.
6. AI 도구로 리뷰했다면(예: Claude Code `/code-review`) 결과 요약을 PR 댓글로 남긴다. AI 리뷰는 사람 확인을 대신하지 않는다.
