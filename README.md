# 풋살 팀 밸런서

풋살 경기 전 참석 선수의 능력치를 바탕으로 2팀 또는 3팀을 균형 있게(평준화) 또는 수준별로(전문화) 편성하는 웹 앱입니다. Flutter Web으로 만들었고 서버나 DB는 없습니다.

- 개발계획서: [docs/DEVELOPMENT_PLAN.md](docs/DEVELOPMENT_PLAN.md)
- 화면 시안: [docs/design/mockup.html](docs/design/mockup.html)
- 테스트 시나리오: [docs/TEST_SCENARIOS.md](docs/TEST_SCENARIOS.md)
- 명단 백업/복원 사용법: [docs/MANUAL_BACKUP.md](docs/MANUAL_BACKUP.md)
- 인수인계서 (PC 웹 서비스 버전): [docs/HANDOVER.md](docs/HANDOVER.md)
- 앱 소스: [app/](app/)

## 실행 방법

Flutter SDK(3.x 이상)가 필요합니다.

```bash
cd app
flutter pub get
flutter run -d chrome            # 개발 모드로 실행
flutter test                     # 단위 테스트
flutter build web --release --no-web-resources-cdn   # 배포용 빌드 → app/build/web
```

`app/build/web` 폴더를 아무 정적 웹 서버(GitHub Pages, Netlify 등)에 올리면 됩니다. `--no-web-resources-cdn` 옵션으로 화면 엔진을 함께 묶어서, 외부 CDN 없이도 동작합니다.

## 아이폰에서 사용하기

1. 배포 주소 **https://simpleman202301-arch.github.io/demodemo/** 를 Safari로 엽니다. 배포 방법은 아래를 참고하세요.
2. 공유 버튼 → **홈 화면에 추가**를 누르면 축구공 아이콘의 앱처럼 쓸 수 있습니다.
3. 선수는 **길게 눌러** 끌어서 옮깁니다. 화면 위나 아래 끝으로 가져가면 자동으로 스크롤됩니다.
4. 팀 확정, 출력, 공유를 누르면 아이폰 공유 시트가 열립니다. 여기서 "파일에 저장", 프린트, 카카오톡 전송, "이미지 저장"을 고를 수 있습니다.

## 배포 (GitHub Pages)

`.github/workflows/deploy-pages.yml`가 `main` 브랜치에 push될 때마다 테스트, 빌드, 배포를 자동으로 합니다.

처음 한 번만 해 줄 일:
1. 저장소 **Settings → Pages → Build and deployment → Source**를 **GitHub Actions**로 바꿉니다.
2. 작업 브랜치를 `main`에 합칩니다(PR 머지). 그러면 몇 분 뒤 위 주소로 접속할 수 있습니다.

## 데이터 보관
- 선수 명단과 날짜별 편성은 브라우저 저장소(localStorage)에 자동 저장됩니다. 브라우저 데이터를 지우면 사라집니다.
- **[선수 관리] → [명단 백업]**으로 전체 명단과 능력치를 파일 하나(`futsal_roster_날짜.json`)로 저장해 두세요. 아이폰에서는 공유 시트의 "파일에 저장"으로 iCloud Drive에 보관할 수 있습니다. 폰을 바꾸거나 데이터가 지워졌을 때 **[명단 복원]**으로 되살립니다(합치기 또는 바꾸기).
- 아이폰 Safari는 7일 동안 열지 않은 사이트의 저장 데이터를 지울 수 있습니다. **홈 화면에 추가해서 쓰면** 이 규칙에서 제외됩니다.
- [팀 확정] 시 내려받는 JSON 파일을 보관해 두면 [불러오기]로 언제든 복원할 수 있습니다. 다른 기기에서 불러오면 명단에 없는 선수도 함께 추가됩니다.
