#!/bin/bash
# 生成した審査官の画像をWeb用に最適化する。
# 元は1枚2MB前後のPNG。12枚で24MBになりページが成立しないため、
# 幅720pxのJPEGへ落として1枚150KB前後にする。元PNGは originals/ に退避して保持。
set -eu

BASE="/Users/ryoseiworld/dev/2026-08-04-eto-founding"
ASSETS="$BASE/assets"
ORIG="$ASSETS/originals"
WEB="$BASE/img"

mkdir -p "$ORIG" "$WEB"

# 寅だけ検証時のファイル名なので、他と揃える
if [ -f "$ASSETS/eto-tora-judge-v2-calm.png" ] && [ ! -f "$ASSETS/judge-tora.png" ]; then
  cp "$ASSETS/eto-tora-judge-v2-calm.png" "$ASSETS/judge-tora.png"
  echo "寅のファイル名を judge-tora.png に統一しました"
fi

echo ""
echo "=== 最適化（幅720px / JPEG品質80）==="
total_before=0
total_after=0

for f in "$ASSETS"/judge-*.png; do
  [ -e "$f" ] || continue
  name=$(basename "$f" .png)
  out="$WEB/${name}.jpg"

  before=$(stat -f%z "$f")
  sips -Z 720 -s format jpeg -s formatOptions 80 "$f" --out "$out" >/dev/null 2>&1
  after=$(stat -f%z "$out")

  total_before=$((total_before + before))
  total_after=$((total_after + after))

  printf "  %-16s %6dKB -> %5dKB\n" "$name" $((before/1024)) $((after/1024))

  # 元PNGを退避（再生成せずに作り直せるように残す）
  mv "$f" "$ORIG/" 2>/dev/null || true
done

echo ""
echo "合計: $((total_before/1024/1024))MB -> $((total_after/1024))KB"
echo "Web用: $WEB"
echo "原本 : $ORIG"
echo ""
echo "=== 出力一覧 ==="
ls -la "$WEB"/*.jpg 2>/dev/null | awk '{printf "  %s  %dKB\n", $9, $5/1024}'
