# 인수인계서 — 풋살 팀 밸런서 → PC 웹 서비스 버전

> 작성일: 2026-10-07
> 원본 작업 브랜치: `claude/zealous-hypatia-137buj` (저장소 `simpleman202301-arch/demodemo`)
> ⚠️ 모든 결과물은 위 브랜치에만 있고 `main`에는 아직 없습니다. 새 작업은 **이 브랜치를 기준으로** 시작해야 합니다.

---

## 1. 새 작업의 목표

지금까지 개발한 Flutter 웹 앱을 **PC 브라우저에서 주소(URL)로 접속해 쓰는 웹 서비스**로 만든 별도 버전입니다.

예상 작업 범위 (새 세션에서 사용자와 컨펌하며 진행):
1. **배포(호스팅)**: 정적 웹 호스팅에 올려 고정 주소로 접속하게 합니다. 후보는 GitHub Pages, Netlify, Firebase Hosting, Cloudflare Pages입니다.
2. **자동 배포**: push할 때마다 자동으로 빌드하고 배포합니다. GitHub Actions를 사용합니다.
3. **PC 화면 최적화**: 넓은 화면 레이아웃, 키보드 단축키, 마우스 드래그 사용성을 다듬습니다. 범위는 사용자와 협의합니다.
4. 현재 버전은 그대로 두고, **별도 버전**으로 관리합니다. 별도 브랜치 또는 폴더를 쓸지는 사용자에게 확인합니다.

> 백엔드와 DB는 여전히 없습니다(요구사항 15). 여러 기기나 여러 사람이 데이터를 공유해야 하면 그때 Firebase 같은 대안을 **사용자에게 제안만** 하고, 승인 후 진행합니다.

## 2. 사용자와 일하는 방식 (반드시 지킬 것)

- 계획서를 먼저 쓰고, **한 단계씩 사용자 컨펌을 받으며** 진행합니다.
- 화면 디자인은 HTML 시안을 먼저 만들어 컨펌받은 뒤 구현합니다.
- 개발이 끝나면 **테스트 시나리오를 제출**하고, 사용자가 모두 컨펌하면 최종본으로 확정합니다.
- 소통은 한국어로 합니다. 질문은 선택지와 예시를 함께 제시합니다(예: 인원별 결과 표).
- PR은 사용자가 요청할 때만 만듭니다.

## 3. 현재까지 완료된 것

| 항목 | 위치 | 상태 |
|---|---|---|
| 개발계획서 v1.1 | `docs/DEVELOPMENT_PLAN.md` | 확정 |
| 화면 시안 (클릭 가능한 HTML) | `docs/design/mockup.html` | 확정 |
| Flutter 웹 앱 | `app/` | 개발 완료 |
| 테스트 시나리오 | `docs/TEST_SCENARIOS.md` | **사용자 컨펌 대기** |
| 실행 방법 | `README.md` | 작성됨 |

### 확정된 기능 요구사항 요약
- **선수 관리**
  - 등록, 이름 수정, 삭제 기능이 있고 같은 이름은 등록할 수 없습니다.
  - 능력치는 활동량, 스피드, 개인기, 협동력, 컨디션 5개 항목이고, 항목마다 레벨 1~3입니다. 새 선수는 모두 2로 시작합니다.
- **경기 날짜**
  - 날짜를 선택하고, 날짜마다 참석 체크와 편성을 따로 보관합니다.
- **팀 수와 인원**
  - 팀 수는 **2팀 또는 3팀** 중에서 사용자가 고릅니다.
  - 팀당 5~7명이고, 참석 인원을 팀끼리 최대 1명 차이로 고르게 나눕니다.
  - 7명 × 팀 수를 넘는 인원은 **교체대기**로 무작위로 뽑습니다.
  - 인원이 모자라면 "경기 불가"를 표시합니다. 2팀은 10명, 3팀은 15명 미만이면 불가입니다.
  - 팀 이름은 A팀, B팀, C팀입니다.
- **편성 방식**
  - 평준화: 스네이크 드래프트로 1차 배정한 뒤 선수를 맞바꿔 다듬습니다. 비용 = 팀 1인당 평균 총점 차이 × 10 + 항목별 1인당 평균 차이 합.
  - 전문화: 점수 순으로 A팀부터 채웁니다.
- **드래그 앤 드롭**
  - 팀마다 **빈 슬롯 2개**가 있고, 팀 정원은 처음 배정 인원 + 2입니다.
  - 빈 슬롯에 놓으면 그 팀으로 이동하고, 선수 위에 놓으면 맞바꾸고, 교체대기에는 제한 없이 놓을 수 있습니다.
  - 팀 인원이 5~7명을 벗어나면 경고를 표시하고 확정할 수 없습니다.
- **팀 확정**
  - `futsal_teams_YYYY-MM-DD.json` 파일을 내려받고 편집을 잠급니다. [수정] 버튼으로 잠금을 풉니다.
- **불러오기**
  - JSON 파일을 열어 해당 날짜의 편성을 복원하고, 다시 편집할 수 있습니다.
  - 명단에 없는 선수는 파일에 저장된 능력치로 명단에 추가합니다.
- **출력**
  - A4 PDF를 내려받습니다. 한글 폰트를 내장했고, 팀별 능력치 표, 팀 합계, 교체대기가 들어갑니다.
  - [PDF 미리보기] 탭에서 같은 내용을 미리 봅니다.
- **공유**
  - 팀별 이름만 담은 PNG를 만들어(능력치와 점수 제외) 클립보드에 복사합니다.
  - 복사가 안 되면 Web Share를 시도하고, 그것도 안 되면 PNG 저장을 안내합니다.
- **AI 모델**
  - v2로 미뤘습니다. 알고리즘만으로 편성을 판단할 수 있기 때문입니다.

## 4. 코드 구조 (`app/`)

```
app/
├─ pubspec.yaml            # provider, shared_preferences, pdf, uuid, intl, web
├─ assets/fonts/           # NotoSansKR-Regular.ttf(앱 폰트), NotoSansKR-Bold.ttf(PDF/공유 이미지용, 필요할 때만 로드)
├─ web/index.html          # lang="ko", 제목
├─ lib/
│  ├─ main.dart            # Provider + MaterialApp(ko 로케일)
│  ├─ theme.dart           # 브랜드 색 #1F7A4D, 팀 색 A 파랑, B 빨강, C 주황, 교체대기 회색
│  ├─ models/player.dart   # Stat enum, Player(toJson/fromJson)
│  ├─ models/lineup.dart   # Team(capacity, emptySlots), Lineup(JSON schemaVersion 1), 상수(min 5, max 7, 빈 슬롯 2)
│  ├─ services/team_builder.dart  # planTeams(), buildTeams(), balanceCost() — 순수 로직
│  ├─ services/storage.dart       # localStorage: players.v1, lineup.v1.<날짜>
│  ├─ services/web_io.dart        # 파일 다운로드, 파일 선택, 클립보드 이미지 복사 (package:web, 웹 전용)
│  ├─ services/pdf_service.dart   # PDF 생성
│  ├─ services/share_image.dart   # dart:ui 캔버스로 공유 PNG 생성
│  ├─ services/fonts.dart         # 굵은 글꼴 지연 로드
│  ├─ state/app_state.dart        # ChangeNotifier: 선수, 편성, 이동, 확정, 불러오기
│  ├─ screens/home_screen.dart    # 상단 탭 3개 (경기 편성 / 선수 관리 / PDF 미리보기)
│  ├─ screens/match_screen.dart   # 도구 막대, 참석 체크, 팀 카드, 드래그, 공유 창
│  ├─ screens/players_screen.dart # 넓은 화면은 표, 좁은 화면은 카드
│  ├─ screens/pdf_preview_screen.dart
│  └─ util/format.dart            # "2026년 10월 11일 (일)"
└─ test/                   # team_builder_test.dart, app_state_test.dart (26개 테스트)
```

## 5. 빌드, 실행, 테스트

```bash
# Flutter 설치 (클라우드 컨테이너에는 기본으로 없음, 약 1분)
git clone --depth 1 -b stable https://github.com/flutter/flutter.git /opt/flutter
export PATH=/opt/flutter/bin:$PATH
flutter config --no-analytics --enable-web

cd app
flutter pub get
flutter analyze          # 경고 0개 상태
flutter test             # 26개 통과 상태
flutter build web --release --no-web-resources-cdn   # 결과: app/build/web (약 54MB, git에서 제외됨)
```

- 개발 당시 Flutter 3.47.6 / Dart 3.13.5를 사용했습니다.
- **`--no-web-resources-cdn` 옵션은 꼭 유지**하세요. 이 옵션이 없으면 CanvasKit을 `www.gstatic.com`에서 받는데, 클라우드 환경에서는 이 주소가 차단되어 앱이 뜨지 않습니다. 이 옵션을 쓰면 오프라인에서도 동작합니다.
- 배포할 때 `base href` 확인이 필요합니다. GitHub Pages처럼 하위 경로에 배포하면 `flutter build web --base-href /<repo>/`를 써야 합니다.

## 6. 개발 중 알게 된 함정 (중요)

1. **루트 `.gitignore`가 `lib/`를 무시합니다** (Python 템플릿). 그래서 `!app/lib/` 예외를 추가해 두었습니다. 새 폴더를 만들면 다시 확인하세요.
2. **헤드리스 Chromium의 로케일이 `en-US@posix`라서 앱이 시작되지 않습니다** ("Incorrect locale information provided"). 앱 버그가 아니라 환경 문제입니다. Playwright에서는 `newContext({ locale: 'ko-KR' })`로 실행하세요.
3. **Playwright로 브라우저를 자동 조작할 때 주의할 점**
   - Flutter 웹은 캔버스로 그려지므로, 시작한 뒤 `flt-semantics-placeholder`를 클릭해 접근성(semantics) 트리를 켜야 `getByRole('button', {name})`로 찾을 수 있습니다.
   - 한글 입력은 `keyboard.type`을 쓰면 글자가 빠집니다. 반드시 `locator.fill()`을 쓰세요.
   - 드래그는 `mouse.down` → 여러 번에 걸친 `mouse.move` → `mouse.up` 순서로 좌표 기반으로 합니다.
   - Playwright는 `/opt/node-tools/node_modules/playwright`에 있고, Chromium은 미리 설치되어 있습니다(`playwright install` 금지).
4. **능력치 버튼**은 `Semantics(label: '<이름> <항목> <레벨>', excludeSemantics: true)`로 되어 있습니다. 테스트에서 `exact: true`로 찾을 수 있습니다.
5. **휴대폰에서는 `LongPressDraggable`(250ms), PC에서는 `Draggable`**을 씁니다. `defaultTargetPlatform`으로 구분합니다.
6. **이모지는 쓰지 마세요.** 한글 폰트에 이모지가 없어서, 오프라인이면 글자가 깨집니다. 아이콘은 Material Icons를 쓰세요.
7. 한글 폰트 파일은 Google Fonts의 정적 TTF입니다(각 약 6MB). pdf 패키지는 OTF(CFF)와 가변 폰트를 지원하지 않으니 교체할 때 주의하세요.

## 7. 남은 일과 결정 대기 사항

> **2026-10-07 갱신:** PC 버전은 사용자 결정에 따라 호스팅 없이 **로컬 PC에서 HTML/JS로 실행하는 버전**(`footsalteam_web/`)으로 완료했습니다. 아래 "로컬 PC 버전 완료 기록"을 보세요.

- [ ] `docs/TEST_SCENARIOS.md` (Flutter 버전) 사용자 컨펌 (👀 항목은 사용자가 직접 확인)
- [x] ~~호스팅 선택~~ → 사용자 결정: DB, WAS, 웹 서버 없이 로컬 PC에서 실행. 호스팅하지 않음
- [x] 별도 버전 관리 방식 → 새 폴더 `footsalteam_web/` (브랜치 `claude/eager-goldberg-o530vn`)
- [x] PC 최적화 범위 → 넓은 화면 배치, 키보드 단축키, 이름 검색, 명단 내보내기/가져오기
- [ ] (선택) 알려진 제한 개선: 휴대폰에서 드래그할 때 자동 스크롤
- [ ] (v2) AI 검토 기능. 도입하면 API 키를 숨길 서버리스 프록시가 필요합니다.

## 7-1. 로컬 PC 버전 완료 기록 (v1.0 최종본, 2026-10-07)

| 항목 | 위치 | 상태 |
|---|---|---|
| 앱 (순수 HTML/CSS/JS, `index.html` 더블클릭 실행) | `footsalteam_web/` | **최종본 확정** |
| 사용자 설명서 (화면용, 앱에서 [사용설명서]/F1로 열기) | `footsalteam_web/manual.html` | 완료 |
| 사용자 설명서 PDF (A4 31쪽) | `footsalteam_web/manual/futsal_user_manual.pdf` | 완료 |
| 테스트 시나리오 | `docs/LOCAL_WEB_TEST_SCENARIOS.md` | 최종 확정 |
| 단위 테스트 / 브라우저 자동 점검 / 설명서 생성 | `footsalteam_web/test/` | 16개 / 70여 항목 통과 |

- 제작자 표시: **박재욱 (FcSEBRO)** — 앱 화면 아래, 단축키 창, 설명서 표지와 모든 쪽 바닥글
- 작업 브랜치: `claude/eager-goldberg-o530vn` (원본 브랜치 기준으로 시작). `main`에는 아직 병합되지 않았습니다.
- JSON 편성표 형식(schemaVersion 1)은 Flutter 버전과 호환됩니다.
- 배포: `footsalteam_web` 폴더에서 `test/`를 뺀 나머지를 zip으로 묶어 전달합니다.
- 화면이나 설명서 내용을 바꾸면 `footsalteam_web/test/build_manual.js`로 화면 사진과 PDF를 다시 만듭니다(`--pdf-only`는 PDF만).
- 함정: `file://`에서 동작해야 하므로 ES 모듈, fetch, 외부 CDN을 쓰지 마세요. 이모지 대신 SVG 아이콘을 씁니다.
- 남은 선택 과제: 실제 Windows PC에서 👀 항목 최종 확인, (원하면) `main` 병합 PR, v2 AI 검토 기능

## 8. 새 세션 시작용 프롬프트 (복사해서 사용)

```
simpleman202301-arch/demodemo 저장소의 claude/zealous-hypatia-137buj 브랜치에 있는
풋살 팀 밸런서(Flutter Web)를 PC에서 웹페이지로 서비스하는 별도 버전으로 만들려고 해.
먼저 docs/HANDOVER.md, docs/DEVELOPMENT_PLAN.md, docs/TEST_SCENARIOS.md를 읽고,
이 버전의 개발계획서를 작성해서 나와 하나씩 컨펌하며 진행해 줘.
```
