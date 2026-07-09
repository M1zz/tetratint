# TetraTint TODO

## 완료
- [x] XcodeGen으로 Xcode 프로젝트 생성 (`TetraTint.xcodeproj`)
- [x] Debug 빌드 성공 확인
- [x] 전체 UI 폰트 크기 한 단계 확대 (caption→callout, body→title3 등)
- [x] Save to palette 시 새 항목 bounce(pop-in) 애니메이션
- [x] Contrast audit 행 레이아웃 유연화 — 좁은 창에서 잘림 해결
- [x] 앱 전체 글자 추가 확대 (root dynamicTypeSize .xLarge + 고정 라벨 9/10→13/14)
- [x] Contrast audit 입력 실시간 스와치 미리보기 (붙여넣는 즉시 색 표시, 인식 불가 값 표시)
- [x] Color vision 화면 3단계 구조화 (①시뮬레이션 ②문제진단 ③안전팔레트 배지+캡션)
- [x] 앱 로고/아이콘 제작 (2×2 틴트 그리드) → 파란색 4변형(라이트/다크/고대비)으로 리디자인
- [x] Palette 탭 4변형 라벨 + 상단 범례 추가

- [x] 언어 통일 + 다국어(i18n) 지원 — 영어 기본 + 한국어(ko.lproj), 시스템 언어 자동 전환. 한국어 실행 스크린샷으로 검증
- [x] UI 구분 기호(—, ·) 전부 제거
- [x] 메뉴바 스포이드(NSColorSampler + MenuBarExtra) — 화면 색 추출→클립보드 복사+최근 기록
- [x] 색 중심 재구성: 공유 작업 색상(AppState) — Generator ↔ 색각이 같은 색 공유(하나의 색, 여러 관점)
- [x] 스포이드를 메뉴바 제거 → 앱 툴바 + Generator/색각 입력에 배치
- [x] 색각 화면에서 작업 색상 직접 편집(색 우물+스포이드), 시뮬레이션에 즉시 반영

- [x] SwiftUI 내보내기 2종 제공: SwiftUI (asset) 에셋 참조형 + SwiftUI (code) 자체 완결형(UIColor 브리징)
- [x] Contrast audit도 작업 색상 연동 — 상단에 작업 색상 실시간 판정 + 하단 대량 검사 유지
- [x] 색 중심 IA 개편: 색상 워크스페이스(고정 색 헤더 + 변형/대비/색각 렌즈 탭). 네비게이션 이동 대신 렌즈 전환. 사이드바는 색상·다이나믹타입·시스템색상·팔레트로 축소
- [x] 렌즈 스위처 가시성 개선: 회색 세그먼트 → 아이콘+라벨 큰 탭(선택 시 액센트) + 현재 렌즈 목적 설명 한 줄

- [x] 렌즈 탭 라벨 동사형 전환 (변형→변형 만들기, 대비→대비 검사하기, 색각→색각 확인하기)
- [x] 저장/변형 생성 시 버튼→팔레트 탭으로 스와치 날아가는 애니메이션 + 사이드바 미확인 개수 뱃지
- [x] 팔레트 탭 컬럼 정렬 수정 (헤더+스와치+hex 고정폭 세로 정렬)
- [x] App Sandbox entitlement 추가 (TetraTint.entitlements) — 배포 검증 에러 해결, codesign으로 확인
- [x] 지원/개인정보처리 페이지 제작(docs/) + GitHub Pages 게시(https://m1zz.github.io/tetratint/) + README 링크

- [x] 앱 아이콘 1024×1024(512@2x) 누락 수정 — App Store 아이콘 검증 통과
- [x] 색맹 사용자 접근성: 전역 CVD 프리뷰(CIColorMatrix 창 필터, 적/녹/청/흑백 실시간) + 툴바 토글 + 프리뷰 배너
- [x] 색 이름 파생(RGB.colorName, 한/영) + 스와치 VoiceOver 접근성 라벨(변형/팔레트/대비)

## 할 일
- [ ] Xcode에서 앱 실행 및 동작 확인 (팔레트 정렬/애니메이션 눈으로 확인)
- [ ] 배포용 Archive는 Release 구성으로 다시 생성해 App Store Connect 업로드
