#!/usr/bin/env python3
"""Mac App Store 스크린샷 합성: 창 캡처 + 헤드라인 → 2880x1800. HTML → 헤드리스 Chrome.

사용법: python3 scripts/make_marketing_screenshots.py [로케일 ...]
  원본: docs/screenshots/raw/<로케일>/NN-….png   (1440x840pt 창을 screencapture -o -l 로 뜬 것, 2880x1680)
  제출: docs/screenshots/marketing/<로케일>/NN-….png  (2880x1800, DeployBar 가 올린다)
원본은 그 언어로 띄운 앱 화면이어야 한다(-AppleLanguages "(ko)" / "(en)").
"""
import subprocess, sys, pathlib

ROOT = pathlib.Path(__file__).resolve().parent.parent
RAW = ROOT / "docs" / "screenshots" / "raw"
OUTROOT = ROOT / "docs" / "screenshots" / "marketing"
CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
W, H = 2880, 1800

# 헤드라인은 언어마다 따로 쓴다(직역 금지). 앱에 있는 기능만.
SHOTS = {
    "ko": [
        ("01-generator.png",    "색 하나로 다크와 고대비까지", "라이트 색 하나에서 네 가지 변형을 만들고 .colorset으로 내보내요"),
        ("02-contrast.png",     "고대비 대응이 필요한 색만 골라내기", "앱에서 쓰는 색을 붙여넣으면 WCAG 기준으로 바로 판정해요"),
        ("03-color-vision.png", "색각이상 사용자의 눈으로 확인", "적색맹, 녹색맹, 청색맹, 흑백 시뮬레이션과 구분 불가 경고"),
        ("04-dynamic-type.png", "커스텀 폰트도 다이나믹 타입으로", "크기 표와 SwiftUI, UIKit 코드를 한 화면에서"),
        ("05-system-colors.png", "시스템 색상의 네 가지 모습을 한눈에", "라이트, 다크, 고대비 값을 나란히 보고 바로 복사해요"),
    ],
    "en-US": [
        ("01-generator.png",    "One color in. Dark and high contrast out.", "Derive four variants from a single light color and export a .colorset"),
        ("02-contrast.png",     "Find the colors that fail contrast", "Paste the colors your app uses and get a WCAG verdict for each"),
        ("03-color-vision.png", "See your palette through other eyes", "Simulate protanopia, deuteranopia, tritanopia and grayscale"),
        ("04-dynamic-type.png", "Dynamic Type for your custom fonts", "Size tables and ready-to-paste SwiftUI and UIKit code"),
        ("05-system-colors.png", "Every system color, all four looks", "Light, dark and high contrast values side by side, ready to copy"),
    ],
}

HTML = """<!doctype html><html lang="{lang}"><head><meta charset="utf-8"><style>
* {{ margin:0; padding:0; box-sizing:border-box; }}
html,body {{ width:{W}px; height:{H}px; overflow:hidden; }}
body {{ background:linear-gradient(160deg,#f6f4ff 0%,#eef3ff 55%,#fdf2f7 100%);
  font-family:-apple-system,"SF Pro Display","Apple SD Gothic Neo",sans-serif; position:relative; }}
.text {{ position:absolute; left:0; right:0; top:110px; text-align:center; padding:0 160px; }}
.headline {{ font-size:104px; font-weight:800; color:#1c1c2e; letter-spacing:-0.025em; line-height:1.1; word-break:keep-all; }}
.sub {{ margin-top:30px; font-size:48px; font-weight:500; color:#5e5e70; letter-spacing:-0.01em; word-break:keep-all; }}
.win {{ position:absolute; left:50%; top:470px; width:2380px; transform:translateX(-50%);
  border-radius:26px; overflow:hidden;
  box-shadow:0 50px 120px rgba(40,30,90,.22), 0 0 0 1px rgba(0,0,0,.08); }}
.win img {{ width:100%; display:block; }}
</style></head><body>
<div class="text"><div class="headline">{headline}</div><div class="sub">{sub}</div></div>
<div class="win"><img src="{img}"></div>
</body></html>"""


def render(html_path, out_png):
    for _ in range(4):
        try:
            r = subprocess.run([CHROME, "--headless=new", f"--screenshot={out_png}",
                                f"--window-size={W},{H}", "--force-device-scale-factor=1",
                                "--hide-scrollbars", "--disable-gpu", "--virtual-time-budget=2000",
                                "--allow-file-access-from-files", html_path.as_uri()],
                               capture_output=True, timeout=90)
        except subprocess.TimeoutExpired:
            continue
        if r.returncode == 0:
            return
    raise SystemExit(f"Chrome 이 그리지 못했다: {out_png}")


def main(only=None):
    for loc, shots in SHOTS.items():
        if only and loc not in only:
            continue
        out = OUTROOT / loc
        out.mkdir(parents=True, exist_ok=True)
        for fname, headline, sub in shots:
            html = HTML.format(lang=loc[:2], W=W, H=H, headline=headline, sub=sub,
                               img=(RAW / loc / fname).as_uri())
            html_path = pathlib.Path("/tmp") / f"tetratint-{loc}-{fname.replace('.png', '.html')}"
            html_path.write_text(html, encoding="utf-8")
            render(html_path, out / fname)
            print(f"rendered {out / fname}")


if __name__ == "__main__":
    main(sys.argv[1:] or None)
