#!/bin/bash
# HTML to Image 앱 실행 스크립트

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ELECTRON="$DIR/node_modules/electron/dist/electron"

# ELECTRON_RUN_AS_NODE 해제 (Claude Code 환경에서 설정됨)
unset ELECTRON_RUN_AS_NODE

# X 서버 확인
if [ -n "$DISPLAY" ]; then
  echo "X 서버 감지됨: $DISPLAY"
  exec "$ELECTRON" "$DIR" --no-sandbox "$@"
elif command -v xvfb-run &>/dev/null; then
  echo "Xvfb 가상 디스플레이로 실행 중..."
  exec xvfb-run --auto-servernum "$ELECTRON" "$DIR" --no-sandbox --disable-gpu "$@"
else
  echo "오류: X 서버 또는 Xvfb가 필요합니다."
  echo "설치: sudo apt install xvfb"
  exit 1
fi
