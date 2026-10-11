#!/bin/sh
# finish-feature 사전 검사(읽기 전용): 브랜치 이름 · 미커밋 변경 · 커밋 메시지 · 비밀값 · 바뀐 영역.
# 사용: check.sh [base]   (기본 base = origin/main)
# 출력: 줄마다 OK|WARN|FAIL, 마지막 줄 "areas: …"
# 종료 코드: 0 = FAIL 없음 · 1 = FAIL 있음
set -u
cd "$(git rev-parse --show-toplevel)" || exit 1
base=${1:-origin/main}
git fetch -q origin main 2>/dev/null || echo "WARN origin fetch 실패 — 로컬 $base 기준으로 검사"
fail=0
ok()   { echo "OK   $*"; }
warn() { echo "WARN $*"; }
bad()  { echo "FAIL $*"; fail=1; }

# 1. 브랜치
br=$(git rev-parse --abbrev-ref HEAD)
if [ "$br" = main ]; then bad "main 브랜치다 — 작업 브랜치에서 실행"
elif echo "$br" | grep -Eq '^(feat|fix)/[0-9]+-[a-z0-9]+(-[a-z0-9]+)*$'; then ok "브랜치 $br"
elif echo "$br" | grep -Eq '^(docs|chore)/[0-9]+-[a-z0-9]+(-[a-z0-9]+)*$'; then warn "브랜치 $br (docs/chore는 제안 형식)"
else bad "브랜치 이름 형식 아님: $br (feat|fix/<issue>-<slug>)"; fi
issue=$(echo "$br" | sed -nE 's#^[a-z]+/([0-9]+)-.*#\1#p')

# 2. 미커밋 변경
n=$(git status --porcelain | wc -l | tr -d ' ')
# push되는 것은 커밋뿐이라 PR을 막지 않는다. 이 작업의 파일이 빠졌는지만 확인하게 알린다.
[ "$n" -eq 0 ] && ok "작업 트리 깨끗함" || warn "커밋하지 않은 변경 ${n}개 — PR에 안 들어감. 이 작업 파일이 빠지지 않았는지 확인"

# 3. 커밋 메시지 (base..HEAD)
commits=$(git rev-list --no-merges "$base..HEAD" 2>/dev/null | wc -l | tr -d ' ')
if [ "$commits" -eq 0 ]; then bad "$base 이후 커밋 없음"
else
  msgs=$(git log --no-merges --format='%h%x09%s' "$base..HEAD" | while IFS="$(printf '\t')" read -r h s; do
    if ! echo "$s" | grep -Eq '^(feat|fix|docs|refactor|test|chore|ci|perf|style)(\([a-z0-9-]+\))?!?: .+'; then echo "FAIL 커밋 $h 형식 아님: $s"
    elif ! printf '%s' "$s" | perl -CS -ne 'exit(/\p{Hangul}/ ? 0 : 1)'; then echo "FAIL 커밋 $h 요약이 한국어 아님: $s"
    elif [ "$(printf '%s' "$s" | perl -CS -ne 'print length')" -gt 72 ]; then echo "FAIL 커밋 $h 요약 72자 초과"
    elif echo "$s" | grep -q '\.$'; then echo "FAIL 커밋 $h 요약 끝 마침표"
    fi
  done)
  if [ -n "$msgs" ]; then echo "$msgs"; fail=1; else ok "커밋 ${commits}개 형식 통과"; fi
  if [ -n "$issue" ] && ! git log --format=%B "$base..HEAD" | grep -Eq "(Refs|Closes|Fixes) #$issue\b"; then
    warn "커밋 꼬리말에 Refs/Closes #$issue 없음(PR 본문에 넣어도 됨)"
  fi
fi

# 4. 비밀값 — 추가된 줄만 검사. 값은 출력하지 않고 파일:패턴만 알린다.
hits=$(git diff "$base...HEAD" --unified=0 --no-color | perl -ne '
  if (/^\+\+\+ b\/(.*)/) { $f=$1; next }
  next unless /^\+/;
  for my $p ("gh[pousr]_[A-Za-z0-9]{20,}", "sk-[A-Za-z0-9_-]{20,}", "AKIA[0-9A-Z]{16}",
             "-----BEGIN [A-Z ]*PRIVATE KEY", "eyJ[A-Za-z0-9_-]{10,}\\.eyJ",
             "(?i)(password|passwd|secret|api_?key|service_role)[\"'\'' ]*[:=][\"'\'' ]*[^\"'\'' ]{8,}") {
    if (/$p/) { print "$f: $p\n"; last }
  }' | sort -u)
[ -z "$hits" ] && ok "비밀값 패턴 없음" || { bad "비밀값 의심(값은 숨김):"; echo "$hits" | sed 's/^/     /'; }
git diff --name-only "$base...HEAD" | grep -E '(^|/)\.env($|\.)' | grep -v '\.env\.example$' | sed 's/^/FAIL .env 파일 포함: /' | grep . && fail=1

# 5. 바뀐 영역 → verify.sh 인자
areas=$(git diff --name-only "$base...HEAD" | awk -F/ '
  /^\.claude\//                { a["claude"]=1; next }
  /^Pum\//                     { a["ios"]=1; next }
  /^packages\/design-tokens\// { a["tokens"]=1; next }
  /^packages\/payroll-engine\//{ a["payroll"]=1; next }
  /^supabase\//                { a["db"]=1; next }
  /^apps\/android\//           { a["android"]=1; next }
  /^apps\/web\//               { a["web"]=1; next }
  /^docs\/|\.md$/              { a["docs"]=1; next }
  { a["other"]=1 }
  END { for (k in a) printf "%s ", k }')
echo "areas: ${areas:-none}"
exit $fail
