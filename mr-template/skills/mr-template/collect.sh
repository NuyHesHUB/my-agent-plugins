#!/usr/bin/env bash
# mr-template 스킬의 수집 단계. SKILL.md의 !`...` 블록에서 호출된다.
# 사용: collect.sh [source] [target]   (기본값: develop main)
# 오류가 나도 exit 0 으로 끝내고 "ERROR:" 줄로 알린다. 판단은 SKILL.md 규칙이 한다.
set -u
SRC=${1:-develop}
TGT=${2:-main}

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "ERROR: 현재 경로가 git 저장소가 아니다: $PWD"
  exit 0
fi
if ! git remote get-url origin >/dev/null 2>&1; then
  echo "ERROR: origin 리모트가 없다"
  exit 0
fi

echo "SOURCE=$SRC"
echo "TARGET=$TGT"
echo

echo "=== 1. 원격 브랜치 최신화 ==="
if ! git fetch origin "$TGT" "$SRC" 2>&1; then
  echo "ERROR: fetch 실패. origin/$TGT, origin/$SRC 브랜치 이름을 확인한다."
  exit 0
fi
echo "fetch 완료"
echo

echo "=== 2. MR에 포함될 커밋 (오래된 순, 병합 커밋 제외) ==="
git log --reverse --no-merges --format='%h %s%n%b%n---' "origin/$TGT..origin/$SRC"
echo

echo "=== 3. 변경 파일 (merge base 기준, $SRC 쪽 변경만) ==="
git diff --stat "origin/$TGT...origin/$SRC"
echo

echo "=== 4. 템플릿 ==="
cat "$(dirname "$0")/MERGE_REQUEST_TEMPLATE.md"
