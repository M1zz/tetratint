# TetraTint

애플 시스템이 자동으로 해주지 **않는** 접근성 개발 작업을 대신해주는 macOS 개발자 도구입니다. 시스템 컬러와 시스템 폰트를 쓰면 공짜로 얻는 적응성을, 커스텀 컬러와 커스텀 폰트에서도 얻을 수 있게 해줍니다.

**링크** · [지원 / Support](https://m1zz.github.io/tetratint/support.html) · [개인정보처리방침 / Privacy](https://m1zz.github.io/tetratint/privacy.html)

## 포지셔닝: "애플이 안 해주는 것"

| 애플이 해주는 것 | 애플이 안 해주는 것 → TetraTint가 해주는 것 |
|---|---|
| 시스템 컬러의 다크/고대비 자동 전환 | **커스텀 컬러**의 4종 변형 자동 파생 + .colorset 내보내기 (Generator) |
| Increase Contrast 설정 제공 | 기존 앱 색상 중 **어떤 색이 고대비 대응이 필요한지 선별** (Contrast audit) |
| — | **색각이상 시뮬레이션** + 구분 불가 색상 쌍 경고 + 색맹 안전 팔레트 제안 (Color vision) |
| 시스템 폰트의 Dynamic Type 자동 스케일 | **커스텀 폰트**의 Dynamic Type 대응 코드 생성 — UIFontMetrics, relativeTo, @ScaledMetric, AX 레이아웃 전환 (Dynamic Type) |
| Xcode의 2색 대비 계산기 | 팔레트 전체의 모드별 WCAG 배지, ΔE 기반 구분 가능성 검사 |

Adaptivity(Geoff Hackworth)가 시스템 값을 "보여주는" 레퍼런스라면, TetraTint는 커스텀 디자인을 접근성 기준에 "맞춰주는" 도구입니다. App Store Connect Accessibility Nutrition Label의 Sufficient Contrast 항목 대응이 직접적인 사용 시나리오입니다.

## 모듈

1. **Generator** — 라이트 색 1개 → Light / Light·HC / Dark / Dark·HC 4종 파생. 4모드 동시 미리보기, 변형별 수동 미세조정, Contents.json·.colorset·UIKit·SwiftUI 내보내기.
2. **Contrast audit** — 앱에서 쓰는 hex 목록을 통째로 붙여넣으면 색마다 "그대로 사용 가능 / 고대비 변형 필요 / 장식용으로만" 판정. 문제 색상은 원클릭으로 4종 변형 생성.
3. **Color vision** — 팔레트를 적색맹·녹색맹·청색맹·흑백으로 시뮬레이션(Machado 행렬), ΔE < 12인 구분 불가 쌍 경고, Okabe–Ito·IBM·Paul Tol 안전 팔레트 원클릭 도입.
4. **Dynamic Type** — 11개 텍스트 스타일 × 7개 카테고리 크기 표, 카테고리 슬라이더 실시간 프리뷰, 커스텀 폰트용 UIKit/SwiftUI/@ScaledMetric/AX 레이아웃 전환 코드 생성.
5. **System colors** — HIG 시스템 컬러의 4가지 appearance 값을 한 화면에 동시 표시, 클릭 복사.
6. **Palette** — 저장한 브랜드 컬러 전체를 하나의 .xcassets로 일괄 내보내기.

## 프로젝트 열기

### 방법 1 — Xcode에서 직접 생성 (권장)

1. Xcode → File → New → Project → **macOS App**
2. Product Name: `TetraTint`, Interface: SwiftUI, Language: Swift
3. 생성된 프로젝트의 `ContentView.swift`와 `TetraTintApp.swift`를 삭제
4. 이 저장소의 `TetraTint/` 폴더 안 파일 전체(`Models/`, `Views/`, `Export/`, `TetraTintApp.swift`)를 프로젝트 네비게이터로 드래그 (Copy items if needed 체크)
5. Signing & Capabilities에서 App Sandbox의 **User Selected File: Read/Write** 권한 추가 (내보내기용) — 또는 로컬 테스트라면 Sandbox 비활성화
6. Run (⌘R)

### 방법 2 — XcodeGen

```bash
brew install xcodegen
cd TetraTint
xcodegen generate
open TetraTint.xcodeproj
```

## 요구 사항

- macOS 13.0+ (NavigationSplitView)
- Xcode 15+

## 구조

```
TetraTint/
├── TetraTintApp.swift          # 앱 진입점 + 사이드바 네비게이션
├── Models/
│   ├── ColorMath.swift         # RGB/HSL 변환, WCAG 대비 계산
│   ├── AppearanceSet.swift     # 4종 변형 모델 + 파생 엔진
│   ├── CVDSimulation.swift     # 색각이상 시뮬레이션(Machado), Lab ΔE, 안전 팔레트
│   ├── DynamicTypeData.swift   # 텍스트 스타일 크기 표 + 코드 스니펫 생성
│   ├── SystemColorData.swift   # HIG 시스템 컬러 레퍼런스 값
│   └── PaletteStore.swift      # 저장 팔레트 (UserDefaults 영속화)
├── Views/
│   ├── GeneratorView.swift     # 색상 입력 → 4패널 미리보기 → 내보내기
│   ├── AuditView.swift         # hex 일괄 붙여넣기 → 고대비 대응 선별
│   ├── ColorVisionView.swift   # CVD 시뮬레이션 그리드 + 충돌 경고 + 안전 팔레트
│   ├── DynamicTypeView.swift   # 크기 표 + 스케일 프리뷰 + 코드 생성
│   ├── VariantCard.swift       # 모드별 고정 배경 카드 + 컴포넌트 프리뷰
│   ├── SystemColorsView.swift  # 시스템 컬러 4모드 동시 레퍼런스
│   └── PaletteView.swift       # 저장 색상 관리 + .xcassets 일괄 내보내기
└── Export/
    └── Exporters.swift         # Contents.json, UIKit/SwiftUI 코드, 파일 쓰기
```

## 파생 알고리즘

애플 시스템 컬러의 실제 이동 패턴을 근사합니다.

- **Dark**: 명도 +5, 채도 +3 (systemBlue #007AFF → #0A84FF 패턴)
- **Light·HC**: 채도 +8 후, 흰색 배경 대비 4.5:1을 만족할 때까지 명도 하향
- **Dark·HC**: Dark 값에서 검정 배경 대비 7:1을 만족할 때까지 명도 상향

자동 파생 결과가 브랜드 톤과 안 맞으면 각 카드의 컬러 피커로 개별 수정할 수 있고, "Regenerate all"로 언제든 초기화됩니다.

## 주의

시스템 컬러 레퍼런스 값은 HIG 문서 기준이며 OS 릴리스마다 달라질 수 있습니다. 실제 앱에서는 항상 `UIColor` / `Color` API를 사용하세요.
