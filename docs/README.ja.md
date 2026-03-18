<p align="center">
  <img src="hushflow-banner.svg" alt="HushFlow — AIの思考時間をマインドフル呼吸に変える" width="720" />
</p>

<p align="center">
  <a href="../README.md">English</a> | <a href="README.zh-TW.md">繁體中文</a> | <a href="README.zh-CN.md">简体中文</a> | <b>日本語</b>
</p>

<p align="center">
  <a href="https://github.com/cry8a8y/HushFlow/stargazers"><img src="https://img.shields.io/github/stars/cry8a8y/HushFlow?style=social" alt="GitHub Stars" /></a>
  &nbsp;
  <img src="https://img.shields.io/npm/v/hushflow?color=cb3837&label=npm" alt="npm" />
  <img src="https://img.shields.io/badge/platform-macOS%20|%20Linux%20|%20Windows-blue" alt="Platform Support" />
</p>

---

AIターミナルのための呼吸レイヤー。すべての待ち時間を、自動化された穏やかなひとときに変えます — ツール横断、プラットフォーム横断。

**Claude Code** と **Gemini CLI** はプロンプトごとのhookを完全サポート。**Codex CLI** はセッションレベルで対応。

## 🚀 60秒でインストール

```bash
curl -fsSL https://raw.githubusercontent.com/cry8a8y/HushFlow/main/install-remote.sh | sh
```

<details>
<summary>その他のインストール方法</summary>

**npx：**

```bash
npx hushflow install
```

**手動インストール：**

```bash
git clone https://github.com/cry8a8y/HushFlow.git
cd HushFlow
./install.sh
```

**Windows (PowerShell)：**

```powershell
git clone https://github.com/cry8a8y/HushFlow.git
cd HushFlow
.\install.ps1
```

</details>

**インストーラーの動作：**
1. HushFlowを `~/.hushflow/` にコピー
2. AIツールの設定ファイルに起動/停止hookを登録
3. デフォルト設定を `~/.<tool>/hushflow/config` に作成

**インストールの確認：**

```bash
~/.hushflow/doctor.sh  # インストール状態と環境をチェック
```

AIツールに任意のプロンプトを送信して5秒待つと、呼吸ウィンドウが表示されます。

### 📋 依存関係

| 種類 | パッケージ | プラットフォーム | 用途 |
|------|-----------|----------------|------|
| **必須** | `bash` 4.0+ | すべて | シェルランタイム |
| **必須** | `jq` | すべて | 設定・テーマ解析 |
| **macOS** | `osascript` | macOS | ウィンドウ配置（組み込み） |
| **Linux** | `xdotool` | Linux (X11) | ウィンドウフォーカス・位置 |
| **任意** | `tmux` | すべて | tmux-pane / tmux-popup モード |
| **任意** | `ffplay` / `mpv` / `afplay` | すべて | サウンド再生 |

## 📺 使用イメージ

<br/>
<p align="center">
  <img src="../demo.gif" alt="HushFlow — AIが作業中、呼吸アニメーションがターミナルの横に表示される" width="720" />
</p>
<br/>

HushFlowは4つのUIモードでワークフローに適応：

| モード | 最適な用途 | 有効化方法 |
|--------|-----------|-----------|
| **Window** | デフォルト — コンパニオンターミナルを開く | `HUSHFLOW_UI_MODE=window` |
| **tmux pane** | tmuxユーザー — ペインを分割 | `HUSHFLOW_UI_MODE=tmux-pane` |
| **tmux popup** | tmux 3.2+ — フローティングオーバーレイ | `HUSHFLOW_UI_MODE=tmux-popup` |
| **Inline** | ミニマル — 現在のターミナルで描画 | `HUSHFLOW_UI_MODE=inline` |

## ✨ なぜ便利か

- **自動で表示** — 設定した遅延後に自動起動、AI完了後に自動消去。手動操作は不要。
- **フォーカスを奪わない** — 別ウィンドウまたはtmuxペインで実行。ターミナルはそのまま。
- **あなたのツールと連携** — Claude Code、Gemini CLI、Codex CLI。一度のインストールですべてカバー。
- **どこでも動作** — macOS、Linux、Windows。Ghostty、iTerm2、Terminal.app、GNOME Terminal、xterm、Windows Terminal。
- **4つの呼吸パターン** — コヒーレント、ため息、ボックス、4-7-8。選んだリズムをHushFlowが記憶。
- **6つのアニメーション、8+テーマ** — 星座から雨まで、ティールからDraculaまで。カスタマイズは自由。

## 🛠️ 対応AIツール

| ツール | 🟢 開始Hook | 🔴 停止Hook | 状態 |
|--------|----------|----------|------|
| **Claude Code** | `UserPromptSubmit` | `Stop` | ✅ フルサポート |
| **Gemini CLI** | `BeforeAgent` | `AfterAgent` | ✅ フルサポート |
| **Codex CLI** | `SessionStart` | `Stop` | ⏳ セッションレベル |

```bash
hushflow install --target gemini   # 特定のツールにインストール
```

## ⌨️ コマンド

```bash
# 呼吸エクササイズ
hushflow config hrv            # コヒーレント呼吸
hushflow config sigh           # 生理的ため息
hushflow config box            # ボックス呼吸
hushflow config 478            # 4-7-8呼吸

# テーマ・アニメーション
hushflow theme twilight        # トワイライトパープル
hushflow theme list            # 利用可能なテーマを一覧表示
hushflow animation orbit       # 双彗星軌道

# サウンド、統計、ラッパー
hushflow sound on              # 呼吸切替チャイムを有効化
hushflow stats                 # セッション数、連続日数、マインドフル時間を表示
hushflow wrap -- npm install   # 任意のコマンド実行中に呼吸

# 診断ツール
hushflow doctor                # インストール状態と環境をチェック
```

> [!TIP]
> Claude Codeでは `/hushflow` コマンドでインタラクティブに設定できます。

## 🧠 仕組み

```
  AIにプロンプトを送信
        │
        ▼
  ┌─────────────┐    ┌──────────┐    ┌──────────────────┐    ┌──────────────┐
  │ on-start.sh │───▶│   遅延   │───▶│  コンパニオン     │───▶│  呼吸アニメ  │
  │  設定確認   │    │ (既定5s) │    │  ウィンドウを開く │    │  ーション    │
  └─────────────┘    └──────────┘    └──────────────────┘    └──────┬───────┘
        │                                                          │
        │ 無効                                      AI応答完了     │
        ▼                                                          ▼
     [終了]                                               ┌──────────────┐
                                                          │ on-stop.sh   │
                                                          │ 閉じてクリーン│
                                                          │ アップ       │
                                                          └──────────────┘
```

### ⚡ 技術的な詳細

| 指標 | 値 | 備考 |
|------|-----|------|
| **描画** | 10 fps | ダブルバッファリング、フレームごとに1回の `printf` |
| **CPU** | < 2% | 三角関数ルックアップテーブル、ループ内に `bc`/`awk` なし |
| **メモリ** | ~3 MB RSS | 純粋なBash、バックグラウンドデーモンなし |
| **起動** | < 50 ms | インタプリタのブートなし、`bash` のみ |
| **依存** | 描画パスで0個 | `jq` は設定読み込み時のみ |

## 📚 詳細ドキュメント

| トピック | リンク |
|----------|--------|
| **コミュニティテーマ** | 5テーマ（Catppuccin、Dracula、Nord、Solarized、Gruvbox）+ [自作テーマ](../CONTRIBUTING.md) |
| **プラグインAPI** | カスタムアニメーション — [docs/PLUGIN-API.md](PLUGIN-API.md) |
| **環境変数** | `HUSHFLOW_UI_MODE`、`HUSHFLOW_DEBUG` 等 — [一覧](ENVIRONMENT.md) |
| **トラブルシューティング** | `hushflow doctor` または [docs/TROUBLESHOOTING.md](TROUBLESHOOTING.md) |

## 🤝 コントリビューション

コントリビューション歓迎！新テーマ、アニメーションプラグイン、バグ修正、翻訳など — [CONTRIBUTING.md](../CONTRIBUTING.md) をご覧ください。

HushFlowがコーディング中の穏やかさに役立ったら、⭐ をお願いします — より多くの人にプロジェクトを届ける助けになります。

## 💖 謝辞

HushFlowは [Mindful-Claude](https://github.com/halluton/Mindful-Claude)（作者：Halluton）から派生しており、MITライセンスの下で公開されています。詳細は [THIRD-PARTY-NOTICES](../THIRD-PARTY-NOTICES) をご覧ください。

## 📄 ライセンス

MIT。詳細は [LICENSE](../LICENSE) をご覧ください。
