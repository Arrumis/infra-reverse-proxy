# コミット履歴の日本語メモ

GitHub のコミット一覧が英語だけだと分かりにくいため、この repo で何をしたかを日本語で残します。

| コミット | 英語の表示 | 日本語でいうと |
|---|---|---|
| `f0f525d` | Initial import for repo split | reverse proxy を独立 repo に分けるため最初の内容を取り込み |
| `b6fa2ba` | Run reverse proxy on host network | reverse proxy を host network で動かす方式へ変更 |
| `ee84ed6` | Use localhost upstreams for proxy templates | proxy テンプレートの転送先を localhost 前提へ変更 |
| `3c7fef9` | Automate reverse proxy config rendering | reverse proxy 設定ファイルの生成を自動化 |
| `bde35e4` | Add Munin proxy automation | Munin 用 proxy 設定の自動生成を追加 |
| `9eecde8` | Auto-expand existing proxy certificate | 既存証明書へホスト名を追加する処理を追加 |
| `6b779e6` | Preserve HTTPS configs when certs exist | 証明書がある場合に HTTPS 設定を維持 |
| `290cb84` | Detect existing certs via renewal config | renewal 設定から既存証明書を検出 |
| `e562734` | Add proxy hosts for remaining apps | 残りのアプリ用 proxy ホストを追加 |
| `b8f175b` | Ignore generated proxy logs | 生成される proxy ログを Git 対象外にする |
| `ae979ea` | Split Mirakurun and EPGStation proxy hosts | Mirakurun と EPGStation の proxy ホストを分離 |
| `fbbb225` | Add proxy dashboard for Traefik-compatible host | Traefik dashboard 用の proxy ホストを追加 |
| `aa42cbe` | Preserve proxy mode when certificate refresh fails | 証明書更新に失敗しても proxy モードを壊さないよう修正 |
| `68a5b1a` | Restore per-host certificate handling | ホストごとの証明書処理を復元 |
| `909d3ad` | Replace nginx proxy with Traefik v2.11 | nginx proxy を Traefik v2.11 に置き換え |
| `41687b0` | Avoid Traefik dashboard port conflicts | Traefik dashboard のポート衝突を回避 |
| `accf963` | Document Traefik proxy flow | Traefik proxy の流れを文書化 |
| `176c5ed` | Fix Munin Traefik upstream path | Munin への Traefik 転送先パスを修正 |
| `0504839` | Add Basic auth to protected Traefik routes | 保護対象 route に Basic 認証を追加 |
| `7aa62e7` | Improve env file guidance and comments | env ファイルの説明コメントを分かりやすく改善 |
| `3922c62` | Sanitize sample domain comments | サンプルドメインのコメントを個人情報なしに整理 |
| `409e1c8` | Protect management routes and ignore ACME data | 管理画面 route を保護し、ACME データを Git 対象外にする |

