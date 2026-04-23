# infra-reverse-proxy

nginx / certbot をまとめた共通 reverse proxy 基盤です。旧 installer の `inst/proxy` を repo として独立させるための新しい正本候補です。

## 起動

```bash
cp .env.example .env.local
./scripts/init-layout.sh
docker compose --env-file .env.local up -d
```

現在の推奨は `nginx-proxy` を host network で動かす構成です。
MyIP / PPP 系の公開IPと Docker のポート公開を組み合わせると返り道が不安定になりやすいため、
外部公開は host 側で `80/443` を受け、各アプリへは `127.0.0.1:<port>` で流します。

初回は app 側の compose が参加する external network が必要です。

```bash
./scripts/create-network.sh
```

## データ配置

- `data/conf.d/`
- `data/html/`
- `data/letsencrypt/`
- `data/log/`
- `data/log_letsencrypt/`

## 設定テンプレート

`templates/` に旧 proxy 資産を保存しています。

- `first.conf`
- `after_SSL.conf`
- `*_proxy.conf`
- `nginx.conf`
- `logformat.conf`

## 初期化

```bash
./scripts/init-layout.sh
```

このスクリプトは以下を行います。

- `data/` 配下ディレクトリ作成
- `templates/nginx.conf` を `nginx.conf` に配置
- `templates/logformat.conf` を `data/conf.d/logformat.conf` に配置
- `templates/first.conf` から `data/conf.d/default.conf` を生成
- 空の `.htpasswd` を作成

## 補足

- アプリ repo を proxy network に参加させる override は別途追加する想定です
- Let’s Encrypt の取得フローはまだ旧 `proxy.sh` 相当を完全には移していません
