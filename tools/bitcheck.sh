#!/bin/bash
# Sonlit 출력 비트 검사 (0단계) — 사용자 Mac에서 한 번 실행
# 음악 앱이 내보내는 소리가 원본과 한 비트도 다르지 않은지 확인한다. 약 10~15분, 그동안 Mac에서 소리가 안 난다.
# 받는 것: 시험 도구(bitcheck), 가상 출력 장치 BlackHole 2ch(무료, 없을 때만 설치·관리자 암호 필요)
#   bash bitcheck.sh          내 파일(시험 음원)로 음악 앱 출력 검사
#   bash bitcheck.sh stream   애플뮤직 스트리밍 곡으로 검사 (같은 곡을 여러 번 처음부터 재생해 비교)
#   bash bitcheck.sh model    이미 받아 둔 스트리밍 소리(result/stream-*.f32)를 다시 분석 (재생 필요 없음)
#   bash bitcheck.sh seq      샘플레이트를 바꾼 뒤 어떻게 다시 틀어야 원본 그대로인지 6가지 비교 (약 3분)
#   bash bitcheck.sh bridge   음악 앱 소리를 네트워크 플레이어(UPnP/DLNA)로 보내는 시제품 (Ctrl-C로 끝)
#   bash bitcheck.sh listen   같은 다리로 음악 듣기: 최대 12시간, 기록은 listen/날짜 폴더에 따로 (시험 결과는 그대로 둠)
set -u
MODE="${1:-run}"
BASE="${BITCHECK_BASE:-https://pfljw.github.io/applemusic-remote-info/tools}"
BITCHECK_SHA="f5a64466523e3164c6086721f7a1ef67bd027e93c83aae1a4205ae7b8e0649ab"   # 공개할 때 채운다 (도구 파일 지문)
BH_URL="https://existential.audio/downloads/BlackHole2ch-0.7.1.pkg"
BH_SHA="57b540f27a3e29c37e310e01bee0fdfab76733087e47f997ef9dccf851400dcf"
WORK="$HOME/Sonlit-BitCheck"
mkdir -p "$WORK" && cd "$WORK" || exit 1

echo "== 1/5 시험 도구 받기"
# 사이트(GitHub Pages)는 파일을 최대 10분 보관해 옛 파일이 섞일 수 있다 → 버전 꼬리표를 붙여 받고, 틀리면 한 번 더
check_tool() { [ -z "$BITCHECK_SHA" ] || echo "$BITCHECK_SHA  bitcheck" | shasum -a 256 -c - >/dev/null 2>&1; }
curl -fsSL -o bitcheck "$BASE/bitcheck?v=${BITCHECK_SHA:-$(date +%s)}" || { echo "도구를 받지 못했습니다 ($BASE/bitcheck)"; exit 1; }
if ! check_tool; then
  sleep 3
  curl -fsSL -o bitcheck "$BASE/bitcheck?t=$(date +%s)" || { echo "도구를 받지 못했습니다"; exit 1; }
  check_tool || { echo "도구 파일 확인 실패: 사이트에 새 버전이 반영되는 중입니다. 몇 분 뒤 처음 명령(curl …)부터 다시 실행하세요"; exit 1; }
fi
chmod +x bitcheck
./bitcheck env | head -1

if [ "$MODE" = "model" ]; then
  echo "== 받아 둔 스트리밍 소리 분석 (원본 없이 '아주 작은 음량 계수만 곱해졌는지' 확인)"
  ls result/stream-*.f32 >/dev/null 2>&1 || { echo "result/stream-*.f32가 없습니다. 먼저 bash bitcheck.sh stream"; exit 1; }
  ./bitcheck model result/stream-*.f32 | tee result/model.txt
  echo
  echo "결과 파일: $WORK/result/model.txt (이 내용을 그대로 보내 주세요)"
  exit 0
fi

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

if [ "$MODE" = "seq" ]; then
  echo "== 4/4 샘플레이트 바꾼 뒤 다시 트는 방법 비교 (음악 앱이 여러 번 열렸다 닫힙니다, 약 3분)"
  ./bitcheck gen signals >/dev/null || exit 1
  echo "   S12(오디오 서버 재시작) 시험에는 Mac 로그인 암호가 필요합니다. 건너뛰려면 암호 없이 Enter"
  sudo -v 2>/dev/null || echo "   (암호 없음: S12는 건너뜁니다)"
  echo "   S11은 음악 앱 출력을 AirPlay 기기(DR70 등)로 잠깐 바꿨다 돌아옵니다. AirPlay 기기를 켜 두세요"
  ./bitcheck seq --files signals --device BlackHole --out result ${2+"${@:2}"}
  code=$?
  echo
  echo "결과 파일: $WORK/result/seq-summary.txt (이 내용을 그대로 보내 주세요)"
  exit $code
fi

if [ "$MODE" = "listen" ]; then
  OUT="listen/$(date +%Y%m%d-%H%M%S)"
  mkdir -p "$OUT"
  echo "== 네트워크 플레이어로 음악 듣기 (끝내려면 Ctrl-C)"
  echo "   기록은 $WORK/$OUT 에 따로 저장합니다. 지금까지의 시험 결과(result 폴더)는 건드리지 않습니다"
  echo "   방화벽이 '들어오는 연결 허용?'을 물으면 허용을 누르세요"
  shift
  ./bitcheck bridge --device BlackHole --out "$OUT" --minutes 720 ${1+"$@"}
  exit $?
fi

if [ "$MODE" = "bridge" ]; then
  echo "== 4/4 네트워크 플레이어로 보내기 (시제품)"
  echo "   방화벽이 '들어오는 연결 허용?'을 물으면 허용을 누르세요"
  ./bitcheck renderers
  shift
  ./bitcheck bridge --device BlackHole --out result ${1+"$@"}
  code=$?
  echo
  echo "결과 파일: $WORK/result/bridge-summary.txt (이 내용과 플레이어 화면·소리 상태를 알려 주세요)"
  exit $code
fi

if [ "$MODE" = "stream" ]; then
  echo "== 4/4 애플뮤직 스트리밍 곡 검사"
  echo "   음악 앱 설정 > 재생 > 오디오 음질에서 '무손실'(가능하면 '고해상도 무손실')을 켜 두세요"
  echo "   안내가 나올 때마다 같은 애플뮤직 곡을 처음부터 재생하면 됩니다 (보통 3~4번, 약 3분). 그동안 Mac 소리는 안 납니다"
  ./bitcheck stream --device BlackHole --out result
  code=$?
  echo
  echo "결과 파일: $WORK/result/stream-summary.txt (이 내용을 그대로 보내 주세요)"
  exit $code
fi

echo "== 4/5 시험 음원 만들기"
./bitcheck gen signals || exit 1

echo "== 5/5 시험 (afplay=측정 기준, music=음악 앱). 음악 앱이 몇 번 열렸다 닫힙니다"
echo "   음악 앱 설정 > 재생에서 '사운드 체크'·'크로스페이드'·'사운드 향상기'는 꺼 두세요"
./bitcheck run --files signals --device BlackHole --methods loopback --control --out result
code=$?
echo
echo "결과 파일: $WORK/result/summary.txt (이 내용을 그대로 보내 주세요)"
exit $code
