#!/bin/sh
# finish-feature 검증: 바뀐 영역의 빌드 · 테스트를 실행한다.
# 사용: verify.sh <area>...   (check.sh가 출력한 areas 값)
#   ios      → iOS 단위 테스트(PumTests)     ios-ui → UI 테스트 포함 전체
#   tokens   → design-tokens 테스트 + 생성물 최신 확인
#   그 외    → 자동 검증 없음으로 보고
# 출력: 영역마다 "PASS|FAIL|SKIP <area> — <실행 명령>", 실패 시 로그 끝 30줄. 전체 로그는 $TMPDIR.
# 환경 변수: PUM_SIM (기본 "iPhone 17")
set -u
cd "$(git rev-parse --show-toplevel)" || exit 1
sim=${PUM_SIM:-iPhone 17}
logdir=${TMPDIR:-/tmp}/pum-verify; mkdir -p "$logdir"
fail=0

run() { # run <area> <명령...>
  area=$1; shift
  log="$logdir/$area.log"
  if "$@" >"$log" 2>&1; then echo "PASS $area — $*"
  else echo "FAIL $area — $*"; echo "     로그: $log"; tail -30 "$log" | sed 's/^/     /'; fail=1; fi
}

[ $# -eq 0 ] && { echo "사용: verify.sh <area>..."; exit 1; }
for a in "$@"; do
  case "$a" in
    ios)    run ios xcodebuild test -quiet -project Pum/Pum.xcodeproj -scheme Pum \
              -destination "platform=iOS Simulator,name=$sim" -parallel-testing-enabled NO -only-testing:PumTests ;;
    ios-ui) run ios-ui xcodebuild test -quiet -project Pum/Pum.xcodeproj -scheme Pum \
              -destination "platform=iOS Simulator,name=$sim" -parallel-testing-enabled NO ;;
    tokens) run tokens-test  npm --prefix packages/design-tokens test --silent
            run tokens-check npm --prefix packages/design-tokens run check --silent ;;
    payroll|db|android|web)
            echo "SKIP $a — 아직 테스트 명령 없음(docs/conventions/code.md 「테스트」 미정)" ;;
    docs|other|none)
            echo "SKIP $a — 자동 검증 없음" ;;
    *)      echo "SKIP $a — 알 수 없는 영역" ;;
  esac
done
exit $fail
