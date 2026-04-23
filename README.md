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
- `http` 用の proxy 設定を `data/conf.d/` に生成
- 空の `.htpasswd` を作成

## HTTPS 化

外部から `80/tcp` で `/.well-known/acme-challenge/` へ到達できる前提で、証明書取得と HTTPS 切り替えを行えます。

```bash
./scripts/request-certificates.sh
```

このスクリプトは次を行います。

- `http` 用設定を書き出す
- `certbot certonly --webroot` で証明書を取得する
- `https` 用設定へ切り替える
- `nginx -t` と `reload` を実行する

`munin` も使う場合は、`.env.local` に `MUNIN_HOST` と `MUNIN_UPSTREAM` を入れておくと同じ流れで `munin.<domain>` を生成できます。

## 補足

- 公開経路そのものはこの repo の責務ではありません
- `myip`、固定IP、ルータ転送などの回線固有設定は別管理にしてください
