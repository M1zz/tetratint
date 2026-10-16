#!/bin/sh
# 배포 전 게이트 — 여기서 실패하면 DeployBar 가 아카이브를 만들지 않는다.
#
# 1) 단위 테스트(색 계산 · 변형 파생 · 색각 시뮬레이션 · 내보내기 · 팔레트 저장)
# 2) Release 빌드가 깨지지 않는지.
#
# ⚠️ CODE_SIGNING_ALLOWED=NO 로 빠르게 만들지 말 것.
#    entitlements(샌드박스 · 사용자 선택 파일 쓰기)가 빠지면 실제 배포 경로에서만 터지는 문제를 놓친다.
set -e
ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$ROOT"

echo "🧪 단위 테스트 (TetraTintTests)"
xcodebuild test \
  -project TetraTint.xcodeproj \
  -scheme TetraTint \
  -destination 'platform=macOS' \
  -quiet

echo "🔨 Release 빌드 (TetraTint)"
xcodebuild build \
  -project TetraTint.xcodeproj \
  -scheme TetraTint \
  -configuration Release \
  -destination 'platform=macOS' \
  -quiet

echo ""
echo "✅ 게이트 통과 — 배포 가능"
