#!/bin/bash
# 十二支の審査官を生成する。
# 共通仕様（素材・衣装・背景・照明・画風・穏やかな表情）は一字も変えず、
# 面の意匠 (MOTIF) だけを差し替えることで12体の画風を揃える。
set -u

ASSETS="/Users/ryoseiworld/dev/2026-08-04-eto-founding/assets"
PROMPTS="/Users/ryoseiworld/dev/2026-08-04-eto-founding/prompts"
LOGS="/Users/ryoseiworld/dev/2026-08-04-eto-founding/logs"
mkdir -p "$ASSETS" "$PROMPTS" "$LOGS"

# 共通仕様（v2＝静かな威厳で確定した版）
build_prompt() {
  local motif="$1"
  cat <<EOF
A dramatic cinematic portrait of a solemn judge figure wearing a carved wooden Japanese Noh-style theatrical mask.

The mask expression is SERENE AND EMOTIONLESS, not angry, not menacing — the calm neutral dignity of a classical Noh mask. Level relaxed eyebrows that do NOT arch upward or furrow. A straight horizontal closed mouth, lips level and at rest, absolutely no downturned frown. Calm level eye slits with soft shadow inside, not narrowed or fierce. The overall feeling is quiet gravity and stillness — a mask that is listening, not judging harshly.

The mask craft: carved from aged cypress wood with visible grain and subtle lacquer sheen, warm bone-ivory tone, worn gold leaf detailing at the edges. A genuine hand-carved antique artifact with visible tool marks, museum quality, not a costume prop.

DISTINCTIVE DESIGN OF THIS PARTICULAR MASK: ${motif}

The figure: wears a heavy black formal Japanese montsuki kimono with a stiff kamishimo shoulder garment, deep matte black fabric with subtle woven texture and a small family crest, seated upright and perfectly still, shoulders squared.

Background: deep near-black sumi ink darkness, with a faint out-of-focus suggestion of theater curtain vertical bands in dark persimmon orange and deep moss green, heavily shadowed.

Lighting: a soft but directional key light from the upper left, gently raking across the mask surface to reveal carved wood texture, with a softer gradual falloff into shadow on the right rather than harsh contrast, subtle warm gold rim light along the mask's jaw. Reverent and warm rather than sinister.

Style: cinematic photorealism, medium format camera look, shallow depth of field, rich film grain, museum-artifact realism. Dignified, composed, ceremonial, quietly authoritative. Vertical portrait, centered composition.

Absolutely no text, no watermark, no logos, no lettering of any language anywhere in the image. Original design that does not resemble any real person or any existing copyrighted character. Not horror, not scary, not a demon — a dignified ceremonial mask.
EOF
}

# 生成を1体投げる（バックグラウンド）
gen() {
  local slug="$1" motif="$2"
  local out="$ASSETS/judge-${slug}.png"
  local pfile="$PROMPTS/${slug}.txt"

  build_prompt "$motif" > "$pfile"

  local task="画像を1枚生成して保存してください。内蔵の image_gen ツールを使ってください。

保存先: ${out}
サイズ: 縦長ポートレート（1024x1536 相当）

生成プロンプト（英語のままツールに渡してください）:
---
$(cat "$pfile")
---

生成後、ls -la ${out} でファイルの存在とサイズを確認して報告してください。"

  codex exec "$task" --sandbox workspace-write </dev/null > "$LOGS/${slug}.log" 2>&1 &
  echo "  投入: ${slug}"
}

# ── 十二支の意匠（寅は生成済みのため除く）──────────────
declare -a SLUGS=(ne ushi u tatsu mi uma hitsuji saru tori inu i)

motif_for() {
  case "$1" in
    ne)      echo "slender elongated calm eye openings, a slightly smaller and finer mask than usual, delicate radiating chisel lines fanning across the forehead suggesting multiplication and abundance, small silver inlay accents at the temples" ;;
    ushi)    echo "a broad heavy jaw and a thick solid brow ridge (level, never furrowed), two very subtle rounded swellings on the upper forehead hinting at the base of horns, a noticeably thicker and heavier mask body" ;;
    u)       echo "a vertically elongated narrow mask, a high clean brow line, unusually large perfectly round eye openings giving a wide alert gaze while remaining calm, a thin lightweight mask" ;;
    tatsu)   echo "the most ornate of the set: fine overlapping scale-like carving across the cheeks and temples, the carved base of a single horn rising from the center of the forehead, spiral chisel work encircling the eye openings, the heaviest gold leaf application of all the masks" ;;
    mi)      echo "part of the outer lacquer surface has flaked away revealing the paler wood layer beneath, as if mid-shedding, narrow horizontally elongated eye openings, a completely unreadable expression" ;;
    uma)     echo "a long vertically extended mask, a high straight prominent nose bridge, eye openings set wide and angled outward toward the periphery, long flowing chisel lines streaming back across the cheeks" ;;
    hitsuji) echo "a continuous band of spiral scroll carving running around the entire outer rim of the mask, soft rounded contours, gently downturned outer eye corners giving a mild gaze, though the mouth stays firmly level" ;;
    saru)    echo "a flatter mask profile than the others, a broad open forehead, eye openings set noticeably close together as if peering in for a closer look, interlocking joinery-pattern carving at the temples resembling traditional Japanese wood joints" ;;
    tori)    echo "a sharply ridged center line running down the mask from brow to nose, an abstraction of a beak, eye openings set unusually far apart to the sides, fan-shaped chisel rays across the forehead" ;;
    inu)     echo "the most plain and well-proportioned mask of the set, straight level eye openings, and a noticeably deeper lacquer sheen than the others as though this mask has been polished and cared for over many years" ;;
    i)       echo "the thickest and heaviest mask of the set, a single straight ridge running unbroken from forehead down the nose bridge, two small blunt protrusions at the lower lip suggesting the remnants of tusks, and many old scars, nicks and repairs across the surface" ;;
  esac
}

echo "十二支の審査官を生成します（寅は生成済み・残り11体）"
echo "並列数: ${1:-3}"
echo ""

PARALLEL="${1:-3}"
count=0
for slug in "${SLUGS[@]}"; do
  gen "$slug" "$(motif_for "$slug")"
  count=$((count+1))
  if [ $((count % PARALLEL)) -eq 0 ]; then
    echo "  --- ${PARALLEL}体投入したので完了を待ちます ---"
    wait
  fi
done
wait

echo ""
echo "=== 生成結果 ==="
ls -la "$ASSETS"/*.png 2>/dev/null | awk '{print $9, $5"バイト"}'
