#!/usr/bin/env python3
"""빌드 결과물의 스크립트 주소에 버전 표시(?v=...)를 붙인다.

브라우저(특히 Safari)는 main.dart.js 같은 파일을 오래 캐시해서,
새로 배포해도 이전 화면을 보여 줄 수 있다. 배포할 때마다 주소가 바뀌면
브라우저가 새 파일을 받는다.

사용법: python3 tool/stamp_version.py <버전> [build/web 경로]
"""

import pathlib
import re
import sys


def stamp(web_dir: pathlib.Path, version: str) -> None:
    if not re.fullmatch(r"[0-9A-Za-z._-]+", version):
        sys.exit(f"버전에는 영문, 숫자, . _ - 만 쓸 수 있습니다: {version!r}")

    replacements = {
        # index.html → flutter_bootstrap.js
        web_dir / "index.html": [
            ('src="flutter_bootstrap.js"', f'src="flutter_bootstrap.js?v={version}"'),
        ],
        # flutter_bootstrap.js → main.dart.js
        web_dir / "flutter_bootstrap.js": [
            ('"mainJsPath":"main.dart.js"', f'"mainJsPath":"main.dart.js?v={version}"'),
        ],
    }
    for path, pairs in replacements.items():
        text = path.read_text(encoding="utf-8")
        for old, new in pairs:
            if old not in text:
                sys.exit(f"{path.name}에서 '{old}'를 찾지 못했습니다. Flutter 빌드 형식이 바뀌었는지 확인하세요.")
            text = text.replace(old, new)
        path.write_text(text, encoding="utf-8")
    print(f"버전 표시 {version} 적용: index.html, flutter_bootstrap.js")


if __name__ == "__main__":
    if len(sys.argv) < 2:
        sys.exit(__doc__)
    web = pathlib.Path(sys.argv[2] if len(sys.argv) > 2 else "build/web")
    stamp(web, sys.argv[1])
