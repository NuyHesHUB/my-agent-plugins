# mr-template

Claude Code 스킬 플러그인. `origin`의 두 브랜치 차이를 계산해 운영 배포용 머지 리퀘스트(MR) 설명을 템플릿에 맞춰 생성한다.

> 수동으로 하던 `git fetch` → `git log` → `git diff` → 템플릿 작성 과정을 `/mr-template` 한 번으로 끝낸다.

## 설치

요구 사항

- Claude Code 2.1 이상
- git, 그리고 비교할 브랜치가 푸시된 `origin` 리모트

### 방법 1. 마켓플레이스에서 설치 (권장)

Claude Code 세션 안에서 한 줄로 끝난다. Claude Code 2.1.275 이상에서 동작한다.

```
/plugin install mr-template --marketplace NuyHesHUB/mr-template-skill
```

터미널에서 하거나 두 단계로 나누려면 다음과 같다.

```bash
claude plugin marketplace add NuyHesHUB/mr-template-skill
claude plugin install mr-template@nuyheshub
```

세션 안에서는 `/plugin marketplace add NuyHesHUB/mr-template-skill` 다음에 `/plugin install mr-template@nuyheshub`를 입력하면 된다. 설치 범위(user / project / local)는 설치 시 선택할 수 있다.

업데이트는 다음 명령으로 한다. 자동 업데이트는 `/plugin`의 Marketplaces 탭에서 켤 수 있다.

```bash
claude plugin marketplace update nuyheshub
claude plugin update mr-template@nuyheshub
```

### 방법 2. 클론 후 심볼릭 링크 (개발용)

저장소를 직접 고치면서 쓸 때는 스킬 폴더를 `~/.claude/skills`에 링크한다.

```bash
git clone https://github.com/NuyHesHUB/mr-template-skill.git ~/projects/code/mr-template-skill
ln -s ~/projects/code/mr-template-skill/skills/mr-template ~/.claude/skills/mr-template
```

한 컴퓨터에서 방법 1과 2를 동시에 쓰면 같은 스킬이 두 번 로드되니 하나만 쓴다.

## 이름 구조

설치 명령에 나오는 이름은 네 가지가 서로 다른 역할을 한다.

| 이름 | 값 | 정의 위치 | 쓰이는 곳 |
|---|---|---|---|
| 저장소 | `NuyHesHUB/mr-template-skill` | GitHub | 마켓플레이스 등록 시 `--marketplace` 또는 `marketplace add`의 인자 |
| 마켓플레이스 | `nuyheshub` | `.claude-plugin/marketplace.json`의 `name` | 설치 명령의 `@` 뒤. `mr-template@nuyheshub` |
| 플러그인 | `mr-template` | `.claude-plugin/plugin.json`의 `name` | 설치·업데이트·제거 단위 |
| 스킬 | `mr-template` | `skills/mr-template/` 폴더명 | 슬래시 명령 `/mr-template` |

마켓플레이스 이름은 올린 사람의 GitHub 계정이 아니라 이 카탈로그에 붙인 별칭이다. 지금은 계정과 같은 `nuyheshub`로 두었지만 `lazyhoodie`처럼 바꿔도 되고, 그러면 설치 명령은 `mr-template@lazyhoodie`가 된다. 올린 사람 정보는 `marketplace.json`의 `owner.name`에 따로 적는다. 마켓플레이스 하나에 플러그인을 여러 개 등록할 수 있으므로, 나중에 다른 플러그인을 추가해도 사용자는 같은 마켓플레이스에서 설치한다.

## 명령어 모음

| 할 일 | 터미널 | 세션 안 |
|---|---|---|
| 한 번에 설치 (2.1.275 이상) | `claude plugin install mr-template --marketplace NuyHesHUB/mr-template-skill` | `/plugin install mr-template --marketplace NuyHesHUB/mr-template-skill` |
| 마켓플레이스 등록 | `claude plugin marketplace add NuyHesHUB/mr-template-skill` | `/plugin marketplace add NuyHesHUB/mr-template-skill` |
| 설치 | `claude plugin install mr-template@nuyheshub` | `/plugin install mr-template@nuyheshub` |
| 설치 목록 | `claude plugin list` | `/plugin` → Installed 탭 |
| 마켓플레이스 새로고침 | `claude plugin marketplace update nuyheshub` | `/plugin marketplace update nuyheshub` |
| 업데이트 | `claude plugin update mr-template@nuyheshub` | `/plugin` → Installed → Update now |
| 끄기 / 켜기 | `claude plugin disable mr-template@nuyheshub` / `claude plugin enable mr-template@nuyheshub` | `/plugin` → Installed |
| 제거 | `claude plugin uninstall mr-template@nuyheshub` | `/plugin` → Installed |
| 마켓플레이스 제거 | `claude plugin marketplace remove nuyheshub` | `/plugin` → Marketplaces |
| 구성 요소·토큰 비용 확인 | `claude plugin details mr-template@nuyheshub` | |
| 매니페스트 검사 (관리자) | 저장소 루트에서 `claude plugin validate .` | |
| 설치 없이 로컬 테스트 (관리자) | `claude --plugin-dir <저장소 경로>` | |

설치 범위는 `--scope user`(기본), `--scope project`, `--scope local`로 지정한다. 세션 안에서 설치하면 범위를 고르는 화면이 먼저 뜬다.

## 사용법

프로젝트 경로에서 Claude Code를 열고 입력한다.

```
/mr-template [source] [target]
```

| 입력 | 의미 |
|---|---|
| `/mr-template` | develop → main (기본값) |
| `/mr-template hotfix/login` | hotfix/login → main |
| `/mr-template develop staging` | develop → staging |

첫 인자가 source(병합할 브랜치), 둘째가 target(병합 대상)이다. MR 제목의 화살표 방향, GitLab의 "source → target" 표기와 같은 순서다.

플러그인으로 설치하면 정식 이름은 `/mr-template:mr-template`이고, 같은 이름의 다른 명령이 없으면 `/mr-template`로도 호출된다.

## 동작 과정

스킬을 호출하면 `collect.sh`가 현재 경로에서 먼저 실행되고, 그 출력이 Claude에 전달된다. 명령은 Claude가 아니라 Claude Code 하네스가 실행하므로 매번 같은 명령이 같은 옵션으로 돈다.

### 1. 원격 브랜치 최신화

```bash
git fetch origin <target> <source>
```

로컬 브랜치는 건드리지 않고 `origin/<target>`, `origin/<source>` 원격 추적 참조만 갱신한다.

### 2. MR에 포함될 커밋

```bash
git log --reverse --no-merges --format='%h %s%n%b%n---' origin/<target>..origin/<source>
```

점 2개(`A..B`)는 B에는 있고 A에는 없는 커밋, 즉 이번 MR로 병합될 커밋만 고른다. 오래된 순으로, 병합 커밋을 제외하고, 제목과 본문을 함께 출력한다.

### 3. 변경 파일

```bash
git diff --stat origin/<target>...origin/<source>
```

점 3개(`A...B`)는 두 브랜치의 공통 조상(merge base)과 B를 비교한다. source가 갈라진 이후 source 쪽 변경만 보여주고, 그사이 target에 들어간 변경은 섞이지 않는다. GitLab이 MR diff를 계산하는 방식과 같다.

### 4. 템플릿 출력

`MERGE_REQUEST_TEMPLATE.md` 내용을 그대로 출력한다.

### 5. MR 작성

Claude가 수집 결과를 바탕으로 `SKILL.md`의 작성 규칙에 따라 MR을 쓴다.

- 제목: `[Merge] <source> → <target> (YYYY-MM-DD)`
- 커밋을 템플릿의 고정 카테고리(Feature, UI / Layout & Asset, Backend API / Infra & Build, SEO / Metadata & Docs, Fix, Chore)로 분류하고, 해당 커밋이 없는 카테고리는 삭제
- 확인 사항은 커밋이나 변경 파일에 근거가 있는 항목만 체크박스 2~5개
- 주석 블록과 `<...>` 자리표시자 제거

## 출력 예시

제목 한 줄 다음에 MR 본문이 마크다운 코드블록 하나로 나온다. 코드블록 안의 내용을 GitLab MR 설명란에 그대로 붙여넣으면 된다.

````
[Merge] develop → main (2026-10-15)

```markdown
## 개요

- `develop` 브랜치의 신규 기능, 버그 수정 사항을 `main` (운영) 브랜치로 반영합니다.

## 주요 변경 사항

### Feature

- **회원 가입 폼**: 학교 / 일반 소속 유형에 따라 입력 필드를 분기 처리

### Fix

- **모바일 레이아웃**: 행사 신청 화면의 패딩 보정

## 확인 사항

- [ ] 운영에서 학교 소속으로 가입 시 학교명이 정상 저장되는지 확인
- [ ] 모바일에서 행사 신청 화면 좌우 여백 확인
```
````

## 오류 상황

`collect.sh`는 문제가 있으면 `ERROR:` 줄을 출력하고, Claude는 템플릿을 만들지 않고 그 내용을 그대로 보여준다.

| 상황 | 메시지 |
|---|---|
| git 저장소가 아닌 경로에서 실행 | `ERROR: 현재 경로가 git 저장소가 아니다` |
| `origin` 리모트 없음 | `ERROR: origin 리모트가 없다` |
| 브랜치 이름이 틀리거나 origin에 없음 | `ERROR: fetch 실패. origin/<target>, origin/<source> 브랜치 이름을 확인한다.` |
| 두 브랜치 사이에 커밋이 없음 | "병합할 커밋이 없다"고만 알림 |

## 수동 확인

Claude 없이 수집 결과만 보고 싶으면 스킬 폴더의 스크립트를 직접 실행한다. 아래는 방법 2로 클론한 경우의 경로다.

```bash
bash ~/projects/code/mr-template-skill/skills/mr-template/collect.sh                 # develop → main
bash ~/projects/code/mr-template-skill/skills/mr-template/collect.sh hotfix/login    # hotfix/login → main
bash ~/projects/code/mr-template-skill/skills/mr-template/collect.sh develop staging # develop → staging
```

## 수정 방법

| 바꾸고 싶은 것 | 수정할 곳 |
|---|---|
| MR 본문 양식, 카테고리 이름 | `skills/mr-template/MERGE_REQUEST_TEMPLATE.md`. `SKILL.md` 작성 규칙 5번의 카테고리 목록도 함께 맞춘다 |
| 기본 브랜치(develop, main) | `skills/mr-template/collect.sh` 상단의 `SRC=${1:-develop}`, `TGT=${2:-main}` |
| 커밋 분류·요약 방식, 출력 형식 | `skills/mr-template/SKILL.md`의 작성 규칙 |
| git 명령 옵션 | `skills/mr-template/collect.sh` |

## 배포 (관리자용)

수정한 내용을 마켓플레이스 사용자에게 내보내는 절차다.

1. `.claude-plugin/plugin.json`과 `.claude-plugin/marketplace.json`의 `version`을 올린다. 사용자는 버전이 바뀌어야 새 코드를 받는다.
2. 저장소 루트에서 `claude plugin validate .`로 매니페스트를 검사한다.
3. 커밋하고 푸시한다.

로컬에서 설치 없이 플러그인 그대로 테스트하려면 `claude --plugin-dir <저장소 경로>`로 세션을 연다.

## 파일 구성

```
mr-template-skill/
├── .claude-plugin/
│   ├── marketplace.json       # 마켓플레이스 정의 (이 저장소가 마켓플레이스 역할)
│   └── plugin.json            # 플러그인 메타데이터
├── skills/
│   └── mr-template/
│       ├── SKILL.md           # 스킬 정의. 수집 결과를 받아 MR을 작성하는 규칙
│       ├── collect.sh         # 수집 스크립트. fetch / log / diff / 템플릿 출력
│       └── MERGE_REQUEST_TEMPLATE.md
├── README.md
└── LICENSE
```

스킬 경로는 `${CLAUDE_SKILL_DIR}`로 참조하므로 마켓플레이스 설치, 심볼릭 링크, 프로젝트 스킬 어느 위치에서도 동작한다.

## 권한

`SKILL.md`의 `allowed-tools`에 `collect.sh` 실행만 허용되어 있어 호출 시 권한 프롬프트가 뜨지 않는다. 스크립트는 `git fetch`, `git log`, `git diff`, `cat`만 실행하며 로컬 브랜치나 작업 트리를 변경하지 않는다.

## 라이선스

[MIT](LICENSE)
