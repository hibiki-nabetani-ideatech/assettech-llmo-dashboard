#!/usr/bin/env bash
# アセットテクノロジー LLMO Dashboard — GitHub Pages 公開スクリプト
#
#   ターミナルで、このフォルダに移動して
#       bash publish.sh
#   を実行してください。
#
#   このフォルダの中身が、そのまま公開されるものです。
#   git の初期化・コミット・push・Pages の有効化まで面倒を見ます。
#
#   ※ パスワードや詳細レポートは、このフォルダには入っていません（別フォルダにあります）。
#     このフォルダに移動してこないでください。

set -uo pipefail
cd "$(dirname "$0")"

OWNER="hibiki-nabetani-ideatech"
REPO="assettech-llmo-dashboard"

echo "=================================================="
echo " ${OWNER}/${REPO} を GitHub Pages に公開します"
echo "=================================================="
echo

# --- 公開してはいけないものが混ざっていないか確認 -----------------------------
NG=""
for f in _pipeline _plain; do
  [ -e "$f" ] && NG="${NG} $f"
done
for f in *.docx *.pdf README_公開手順.md; do
  [ -e "$f" ] && NG="${NG} $f"
done
if [ -n "$NG" ]; then
  echo "！ 公開してはいけないものがこのフォルダに入っています:${NG}"
  echo
  echo "  ・_pipeline / _plain … 元データ（Brand Radar の応答全文・競合の実名集計）と暗号化前の平文"
  echo "  ・*.docx / *.pdf     … 詳細レポート"
  echo "  ・README_公開手順.md  … パスワードが書かれています"
  echo
  echo "  GitHub Pages は Public リポジトリでしか配信できないため、"
  echo "  これらを入れると誰でもダウンロードできる状態になります。"
  echo "  別フォルダへ移動してから、もう一度実行してください。"
  exit 1
fi

echo "公開されるファイル:"
ls -A | grep -v '^\.git$'
echo

if ! git rev-parse --git-dir >/dev/null 2>&1; then
  echo "git リポジトリを初期化します。"
  git init -b main >/dev/null
fi

if [ -n "$(git status --porcelain)" ] || [ -z "$(git log --oneline -1 2>/dev/null)" ]; then
  git add -A
  git commit -m "アセットテクノロジー LLMO Dashboard 初回スナップショット（2026年9月）" >/dev/null \
    || git commit -m "update" >/dev/null || true
  echo "コミットしました。"
fi
echo

# --- gh がある場合 -----------------------------------------------------------
if command -v gh >/dev/null 2>&1; then
  echo "GitHub CLI（gh）が見つかりました。自動で公開します。"
  echo

  if ! gh auth status >/dev/null 2>&1; then
    echo "GitHub にログインしていません。ブラウザが開きます。"
    gh auth login || { echo "ログインに失敗しました。"; exit 1; }
  fi

  if gh repo view "${OWNER}/${REPO}" >/dev/null 2>&1; then
    echo "リポジトリは既に存在します。push します。"
    git remote get-url origin >/dev/null 2>&1 || \
      git remote add origin "https://github.com/${OWNER}/${REPO}.git"
    git push -u origin main
  else
    gh repo create "${OWNER}/${REPO}" --public --source=. --remote=origin --push
  fi

  echo
  echo "GitHub Pages を有効化します。"
  gh api -X POST "repos/${OWNER}/${REPO}/pages" \
     -f "source[branch]=main" -f "source[path]=/" >/dev/null 2>&1 \
  || gh api -X PUT "repos/${OWNER}/${REPO}/pages" \
     -f "source[branch]=main" -f "source[path]=/" >/dev/null 2>&1 \
  || echo "※ 自動設定できませんでした。Settings → Pages で main / (root) を選んで Save してください。"

else
  # --- gh が無い場合 ---------------------------------------------------------
  echo "GitHub CLI（gh）が入っていません。どちらかを選んでください。"
  echo
  echo "【A】gh を入れる（以降ずっと楽になります）"
  echo "      brew install gh"
  echo "    を実行してから、もう一度このスクリプトを実行してください。"
  echo
  echo "【B】このまま git だけで進める"
  echo "    1) ブラウザで https://github.com/new を開く"
  echo "    2) Owner = ${OWNER} ／ Repository name = ${REPO}"
  echo "       Public を選択。README・.gitignore・ライセンスは追加しない"
  echo "    3) Create repository を押す"
  echo
  read -r -p "【B】の 1〜3 を終えましたか？ 終えていれば y を押すと push まで進みます [y/N]: " ans
  if [ "${ans:-N}" = "y" ] || [ "${ans:-N}" = "Y" ]; then
    git remote get-url origin >/dev/null 2>&1 || \
      git remote add origin "https://github.com/${OWNER}/${REPO}.git"
    if git push -u origin main; then
      echo
      echo "push できました。"
      echo "最後に、リポジトリの Settings → Pages を開き、"
      echo "  Source = Deploy from a branch ／ Branch = main ／ フォルダ = / (root)"
      echo "にして Save してください。"
    else
      echo
      echo "push に失敗しました。リポジトリ名と Owner を確認してください。"
      exit 1
    fi
  else
    echo "中断しました。リポジトリを作ってから、もう一度実行してください。"
    exit 0
  fi
fi

cat <<'EOS'

==================================================
 公開URL（Pages のビルドに1〜3分かかります）
==================================================
  https://hibiki-nabetani-ideatech.github.io/assettech-llmo-dashboard/
  https://hibiki-nabetani-ideatech.github.io/assettech-llmo-dashboard/monitoring
  https://hibiki-nabetani-ideatech.github.io/assettech-llmo-dashboard/strategy

 パスワードは README_公開手順.md（別フォルダ）に記載しています。
 404 が返るうちは Pages のビルド中です。少し待って再読み込みしてください。
EOS
