#!/bin/bash
# Sonlit 출력 비트 검사 (0단계) — 사용자 Mac에서 한 번 실행
# 음악 앱이 내보내는 소리가 원본과 한 비트도 다르지 않은지 확인한다. 약 10~15분, 그동안 Mac에서 소리가 안 난다.
# 받는 것: 시험 도구(bitcheck), 가상 출력 장치 BlackHole 2ch(무료, 없을 때만 설치·관리자 암호 필요)
set -u
BASE="${BITCHECK_BASE:-https://pfljw.github.io/applemusic-remote-info/tools}"
BITCHECK_SHA="78da89517e6722c7710de47627607cb0892bdeaae75798529c5b44d8bfe26bd1"   # 공개할 때 채운다 (도구 파일 지문)
BH_URL="https://existential.audio/downloads/BlackHole2ch-0.7.1.pkg"
BH_SHA="57b540f27a3e29c37e310e01bee0fdfab76733087e47f997ef9dccf851400dcf"
WORK="$HOME/Sonlit-BitCheck"
mkdir -p "$WORK" && cd "$WORK" || exit 1

echo "== 1/5 시험 도구 받기"
curl -fsSL -o bitcheck "$BASE/bitcheck" || { echo "도구를 받지 못했습니다 ($BASE/bitcheck)"; exit 1; }
if [ -n "$BITCHECK_SHA" ]; then
  echo "$BITCHECK_SHA  bitcheck" | shasum -a 256 -c - >/dev/null || { echo "도구 파일 확인 실패 (다시 받아 보세요)"; exit 1; }
fi
chmod +x bitcheck
./bitcheck env | head -1

echo "== 2/5 가상 출력 장치 BlackHole 2ch"
if ./bitcheck env | grep -q "BlackHole"; then
  echo "이미 있음"
else
  curl -fsSL -o BlackHole2ch.pkg "$BH_URL" || { echo "BlackHole을 받지 못했습니다"; exit 1; }
  echo "$BH_SHA  BlackHole2ch.pkg" | shasum -a 256 -c - || { echo "BlackHole 파일 확인 실패"; exit 1; }
  echo "설치합니다. Mac 로그인 암호를 물으면 입력하세요 (화면에 글자가 안 보이는 게 정상)"
  sudo installer -pkg BlackHole2ch.pkg -target / || exit 1
  sudo killall coreaudiod 2>/dev/null
  sleep 6
  ./bitcheck env | grep -q "BlackHole" || { echo "BlackHole이 아직 안 보입니다. Mac을 다시 시작한 뒤 이 스크립트를 다시 실행하세요"; exit 1; }
fi

echo "== 3/5 권한 준비: 창이 뜨면 모두 '허용'·'확인'을 누르세요"
osascript -e 'tell application "Music" to get sound volume' >/dev/null 2>&1 || true
./bitcheck perm --device BlackHole

echo "== 4/5 시험 음원 만들기"
./bitcheck gen signals || exit 1

echo "== 5/5 시험 (afplay=측정 기준, music=음악 앱). 음악 앱이 몇 번 열렸다 닫힙니다"
echo "   음악 앱 설정 > 재생에서 '사운드 체크'·'크로스페이드'·'사운드 향상기'는 꺼 두세요"
./bitcheck run --files signals --device BlackHole --control --out result
code=$?
echo
echo "결과 파일: $WORK/result/summary.txt (이 내용을 그대로 보내 주세요)"
exit $code
