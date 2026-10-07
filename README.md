# 풋살 팀 밸런서

풋살 경기 전 참석 선수의 능력치를 바탕으로 2팀 또는 3팀을 균형 있게(평준화) 또는 수준별로(전문화) 편성하는 웹 앱입니다. Flutter Web으로 만들었고 서버나 DB는 없습니다.

- 개발계획서: [docs/DEVELOPMENT_PLAN.md](docs/DEVELOPMENT_PLAN.md)
- 화면 시안: [docs/design/mockup.html](docs/design/mockup.html)
- 테스트 시나리오: [docs/TEST_SCENARIOS.md](docs/TEST_SCENARIOS.md)
- 인수인계서 (PC 웹 서비스 버전): [docs/HANDOVER.md](docs/HANDOVER.md)
- 앱 소스 (Flutter Web): [app/](app/)
- **로컬 PC 웹 버전 (HTML/JS, 서버 불필요)**: [web_local/](web_local/) — `web_local/index.html`을 더블클릭하면 바로 실행됩니다. 테스트 시나리오: [docs/LOCAL_WEB_TEST_SCENARIOS.md](docs/LOCAL_WEB_TEST_SCENARIOS.md)

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

## 데이터 보관
- 선수 명단과 날짜별 편성은 브라우저 저장소(localStorage)에 자동 저장됩니다. 브라우저 데이터를 지우면 사라집니다.
- [팀 확정] 시 내려받는 JSON 파일을 보관해 두면 [불러오기]로 언제든 복원할 수 있습니다. 다른 기기에서 불러오면 명단에 없는 선수도 함께 추가됩니다.
