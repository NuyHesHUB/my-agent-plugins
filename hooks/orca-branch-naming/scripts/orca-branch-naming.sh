#!/usr/bin/env bash
# orca-branch-naming.sh — Claude Code UserPromptSubmit hook
#
# Orca 워크트리의 첫 "실제 작업" 프롬프트에서 에이전트에게 브랜치를 `<type>/<slug>` 컨벤션으로
# 맞추라는 지시를 additionalContext 로 주입한다. 브랜치 이름의 성격에 따라 세 가지로 동작한다.
#
#   표시 이름 동기화   — Orca 표시 이름(`orca worktree set --display-name`)이 이미
#                       `<type>/<slug>` 형태인데 실제 git 브랜치는 아직 안 바뀐 경우.
#                       프롬프트 내용은 무시하고 표시 이름을 브랜치에 그대로 반영한다.
#   placeholder 모드  — Orca 랜덤 이름(razorfish 처럼 소문자 한 단어)이나 wip-* 임시 이름.
#                       프롬프트를 보고 유형과 slug 를 새로 짓는다.
#   named 모드        — 사용자가 일부러 지은 이름(하이픈·숫자·한글 포함 등).
#                       이름은 그대로 두고 유형 접두어만 붙인다. `fix-login` 처럼 유형으로
#                       시작하면 분류 없이 `fix/login` 으로 바꾼다.
#
# 이미 `/` 가 있는 브랜치, 메인 워크트리, 보호 브랜치, 원격에 push 된 브랜치는 건드리지 않는다.
#
# ORCA_BRANCH_NAMING = on (기본) | placeholder-only (지은 이름은 손대지 않음) | off
# 워크트리 단위 끄기: touch "$(git rev-parse --git-dir)/orca-branch-naming.skip"
set -u

payload=$(cat 2>/dev/null || true)

mode_setting="${ORCA_BRANCH_NAMING:-on}"
[ "$mode_setting" != "off" ] || exit 0

# Orca 가 관리하는 워크트리 터미널 안에서만
[ -n "${ORCA_WORKTREE_ID:-}" ] || exit 0

# git 워크트리여야 함 (폴더 기반 repo 제외)
git_dir=$(git rev-parse --git-dir 2>/dev/null) || exit 0
common_dir=$(git rev-parse --git-common-dir 2>/dev/null) || exit 0
git_dir_abs=$(cd "$git_dir" 2>/dev/null && pwd -P) || exit 0
common_dir_abs=$(cd "$common_dir" 2>/dev/null && pwd -P) || exit 0
# 메인 워크트리(git-dir == common-dir) 제외
[ "$git_dir_abs" != "$common_dir_abs" ] || exit 0

marker="$git_dir_abs/orca-branch-naming.skip"
[ ! -e "$marker" ] || exit 0

branch=$(git symbolic-ref --short -q HEAD 2>/dev/null) || exit 0
[ -n "$branch" ] || exit 0

# 이미 컨벤션 이름
case "$branch" in */*) exit 0 ;; esac

# 보호 브랜치
case "$branch" in
  main|master|develop|dev|development|staging|production|prod|release|trunk) exit 0 ;;
esac

# 원격에 push 된 브랜치는 제외
if git rev-parse --abbrev-ref --symbolic-full-name '@{u}' >/dev/null 2>&1; then exit 0; fi

# 프롬프트: 빈 값·슬래시 명령 제외
prompt=$(printf '%s' "$payload" | python3 -I -c 'import json,sys
try:
    d=json.load(sys.stdin); p=d.get("prompt") or ""
except Exception:
    p=""
sys.stdout.write(p.strip())' 2>/dev/null) || prompt=""
[ -n "$prompt" ] || exit 0
case "$prompt" in /*) exit 0 ;; esac

types='feat|fix|refactor|chore|test|docs|style|perf|ci|build'
orca_bin="${ORCA_CLI_COMMAND:-orca}"
set_cmd="$orca_bin worktree set --worktree active --display-name \"<새 브랜치명>\" --comment \"<작업 한 줄 요약(한국어)>\" --json"

common_tail=$(cat <<TAIL
사용자에게 한 줄로 \`브랜치: $branch → <새 브랜치명>\` 라고 알린 뒤 바로 본 작업을 진행합니다. 워크트리 디렉터리 이름은 바뀌지 않아도 정상입니다.

예외:
- 인사·감사·잡담처럼 어떤 작업도 암시하지 않을 때만 건너뜁니다. 분석·설명·정리·조사 같은 읽기 전용 탐색 요청도 "실제 작업"으로 보고 이름을 짓습니다(유형이 애매하면 chore를 기본값으로). "해당 폴더를 분석해봐" 같은 프롬프트는 건너뛰는 대상이 아닙니다.
- 그래도 건너뛰기로 판단했다면 말없이 바로 본 작업으로 들어가지 말고, 먼저 한 줄로 "애매해서 이름은 다음 프롬프트에서 정하겠습니다" 라고 밝히세요. 이 안내는 이름이 정해질 때까지 다음 프롬프트에서 다시 나옵니다.
- 사용자가 프롬프트에서 브랜치명을 직접 지정하면 그 이름을 씁니다(슬래시가 없으면 유형 접두어를 붙입니다).
- 사용자가 이름 변경을 원치 않는다고 하면 \`touch "$marker"\` 를 실행해 이 워크트리에서 안내를 끕니다.
TAIL
)

# ---- Orca 표시 이름이 이미 <type>/<slug> 컨벤션이면 그걸 우선한다 ----
# 워크트리 생성 후 `orca worktree set --display-name "feat/phase-3"` 처럼 표시 이름만 먼저
# 정해두고 실제 git 브랜치(랜덤 placeholder)는 아직 안 바꾼 경우. 이때는 프롬프트로 새 이름을
# 짓지 않고, 이미 정해둔 표시 이름을 그대로 브랜치에 동기화한다.
display_name=$("$orca_bin" worktree current --json 2>/dev/null | python3 -I -c 'import json,sys
try:
    d=json.load(sys.stdin)
    print(d.get("result",{}).get("worktree",{}).get("displayName") or "")
except Exception:
    print("")' 2>/dev/null) || display_name=""

display_typed_re="^(${types})/(.+)$"
if [ -n "$display_name" ] && [ "$display_name" != "$branch" ] && [[ "$display_name" =~ $display_typed_re ]]; then
  ctx=$(cat <<CTX
[Orca 워크트리 브랜치 자동 네이밍 — 표시 이름 동기화]
현재 워크트리는 Orca 표시 이름이 이미 \`$display_name\` (컨벤션 형식)으로 지정돼 있지만, 실제 git 브랜치는 아직 \`$branch\` 입니다. 프롬프트 내용과 무관하게 **표시 이름을 그대로 브랜치에 반영**하세요. 본 작업을 시작하기 전에 아래 명령을 실행합니다.
   git branch -m "$display_name"
$common_tail
CTX
)
  CTX="$ctx" python3 -I -c 'import json,os,sys
sys.stdout.write(json.dumps({"hookSpecificOutput":{"hookEventName":"UserPromptSubmit","additionalContext":os.environ["CTX"]}},ensure_ascii=False))'
  exit 0
fi

# ---- 브랜치 이름 성격 판정 ----
placeholder_re='^(wip([-_].*)?|[a-z]{3,})$'   # wip-*, 또는 Orca 랜덤 이름(소문자 한 단어)
typed_re="^(${types})[-_](.+)$"                # fix-login-form 처럼 유형으로 시작

if [[ "$branch" =~ $placeholder_re ]]; then
  mode=placeholder
else
  mode=named
  [ "$mode_setting" != "placeholder-only" ] || exit 0
fi

if [ "$mode" = placeholder ]; then
  ctx=$(cat <<CTX
[Orca 워크트리 브랜치 자동 네이밍 — 임시 이름]
현재 워크트리의 브랜치 \`$branch\` 는 Orca가 붙인 임시 이름입니다. 이번 프롬프트가 실제 작업 요청이면, 본 작업을 시작하기 전에 먼저 아래를 수행하세요.

1. 프롬프트를 읽고 작업 유형을 하나 고릅니다: ${types//|/ | }
2. 작업 내용을 영문 소문자 kebab-case 2~4단어(최대 32자)로 요약합니다. 예) login-form-validation, event-apply-mobile-layout
3. 새 브랜치명은 \`<type>/<slug>\` 입니다. 아래 두 명령을 실행합니다.
   git branch -m "<type>/<slug>"
   $set_cmd
4. $common_tail
CTX
)
elif [[ "$branch" =~ $typed_re ]]; then
  t="${BASH_REMATCH[1]}"; rest="${BASH_REMATCH[2]}"
  ctx=$(cat <<CTX
[Orca 워크트리 브랜치 자동 네이밍 — 유형 접두어 정규화]
현재 워크트리의 브랜치 \`$branch\` 는 사용자가 지은 이름이며 이미 작업 유형 \`$t\` 로 시작합니다. 분류 없이 컨벤션 형식으로만 바꾸세요. 본 작업을 시작하기 전에 아래 두 명령을 실행합니다.
   git branch -m "$t/$rest"
   $set_cmd
$common_tail
CTX
)
else
  ctx=$(cat <<CTX
[Orca 워크트리 브랜치 자동 네이밍 — 사용자 지정 이름]
현재 워크트리의 브랜치 \`$branch\` 는 사용자가 일부러 지은 이름입니다. **이름은 그대로 유지**하고 작업 유형 접두어만 붙이세요. 이번 프롬프트가 실제 작업 요청이면, 본 작업을 시작하기 전에 아래를 수행합니다.

1. 프롬프트(와 브랜치 이름)를 보고 작업 유형을 하나 고릅니다: ${types//|/ | }
2. 새 브랜치명은 \`<type>/$branch\` 입니다. 이름 부분은 바꾸거나 번역하지 않습니다. 아래 두 명령을 실행합니다.
   git branch -m "<type>/$branch"
   $set_cmd
3. $common_tail
CTX
)
fi

CTX="$ctx" python3 -I -c 'import json,os,sys
sys.stdout.write(json.dumps({"hookSpecificOutput":{"hookEventName":"UserPromptSubmit","additionalContext":os.environ["CTX"]}},ensure_ascii=False))'
exit 0
