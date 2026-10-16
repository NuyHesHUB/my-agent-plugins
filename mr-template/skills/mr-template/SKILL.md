---
name: mr-template
description: origin의 두 브랜치(기본 develop → main) 차이를 계산해 운영 배포 MR 설명을 템플릿에 맞춰 생성한다. "/mr-template", "MR 템플릿 만들어줘", "운영 머지 리퀘스트 설명 작성해줘" 요청 시 사용.
argument-hint: [source] [target]
allowed-tools: Bash(bash ${CLAUDE_SKILL_DIR}/collect.sh:*)
---

# source → target MR 설명 생성

브랜치는 인자로 받는다. `/mr-template [source] [target]` 형식이고 생략하면 `develop` → `main`이다.

- `/mr-template` : develop → main
- `/mr-template hotfix/login` : hotfix/login → main
- `/mr-template develop staging` : develop → staging

아래 "수집 결과"는 호출 시점에 현재 프로젝트 경로에서 이 스킬 폴더의 `collect.sh`가 자동 실행한 출력이다. 스크립트는 순서대로 다음을 수행한다.

1. `git fetch origin <target> <source>` : 원격 추적 참조만 갱신
2. `git log --reverse --no-merges --format='%h %s%n%b%n---' origin/<target>..origin/<source>` : MR에 포함될 커밋
3. `git diff --stat origin/<target>...origin/<source>` : merge base 기준 source 쪽 변경 파일
4. 템플릿 파일 출력

같은 명령을 다시 실행하지 말고 이 결과를 그대로 사용한다.

## 수집 결과 (자동 실행)

```
!`bash ${CLAUDE_SKILL_DIR}/collect.sh $ARGUMENTS`
```

## 작성 규칙

1. **중단 조건**: 수집 결과에 `ERROR:` 줄이 있으면 그 내용을 그대로 보여주고 중단한다. 2번 커밋 목록이 비어 있으면 "origin/<target>과 origin/<source> 사이에 병합할 커밋이 없다"고만 알리고 템플릿을 만들지 않는다.
2. **브랜치 이름**: 수집 결과 첫 두 줄의 `SOURCE=`, `TARGET=` 값을 쓴다. 템플릿에 적힌 develop, main은 예시이므로 실제 값으로 바꾼다.
3. **제목**: `[Merge] <source> → <target> (YYYY-MM-DD)` 형식, 날짜는 오늘 날짜.
4. **개요**: 템플릿 문장 형태를 유지해 불릿 1개, 1~2줄로 쓴다. `<변경 성격>` 자리는 커밋 전체를 보고 신규 기능 / 리팩토링 / 버그 수정 / 환경 설정 등 중 해당하는 것으로 채우고, 여럿이면 쉼표로 나열한다. `(운영)` 표기는 target이 `main`일 때만 붙인다.
5. **주요 변경 사항**: 커밋을 템플릿의 고정 카테고리(Feature, UI / Layout & Asset, Backend API / Infra & Build, SEO / Metadata & Docs, Fix, Chore)로 분류한다. 해당 커밋이 없는 카테고리는 `###` 제목까지 통째로 삭제한다.
   - 항목 형식은 `**핵심 키워드**: 변경 내용 요약` 한 줄. 세부 항목이 여러 개면 하위 불릿으로 분리한다.
   - 커밋 제목을 그대로 옮기지 말고 3번 변경 파일 목록을 함께 보고 사용자 관점의 변경으로 요약한다. 여러 커밋이 같은 작업이면 하나의 항목으로 합친다.
   - 커밋 해시는 적지 않는다.
6. **확인 사항**: 배포 후 실제로 검증이 필요한 항목만 체크박스 2~5개로 쓴다. 커밋이나 변경 파일에 근거가 있는 항목만 적고, 근거 없는 일반론은 넣지 않는다.
7. **선택 섹션**: Breaking Changes, 환경 변수 / 배포 참고, 관련 이슈는 커밋이나 변경 파일에 근거(마이그레이션, `.env`·설정 파일 변경, 이슈 번호 등)가 있을 때만 `## 확인 사항` 뒤에 추가한다.
8. **정리**: 템플릿의 HTML 주석 블록과 `<...>` 자리표시자는 모두 제거한다.
9. **출력 형식**: 머리말 없이 제목 한 줄을 가장 먼저 쓰고, 이어서 MR 본문 전체를 마크다운 코드블록 하나로 감싸 GitLab에 바로 붙여넣을 수 있게 한다. 코드블록 밖에는 분류가 애매했던 커밋이 있을 때 한 줄 메모만 허용하고, 그 외 설명은 덧붙이지 않는다.
