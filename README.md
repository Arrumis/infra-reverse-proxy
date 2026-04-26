# infra-reverse-proxy

`Traefik v2.11` を使う共通 reverse proxy 基盤です。  
各アプリは `127.0.0.1:<port>` を upstream にし、公開側の `80/443` は Traefik が host network で受けます。

## 日本語メモ

GitHub のコミット一覧が英語で分かりにくい場合は、[コミット履歴の日本語メモ](docs/COMMIT_HISTORY_JA.md) を見てください。

## サンプル値の置き換え

`.env.example` は公開用の見本です。実際に使う値は `.env.local` に書きます。

- `DOMAIN` / `ROOT_HOST` は実際に公開するドメインへ変更します
- `TTRSS_HOST` や `MUNIN_HOST` などは、使うサブドメインへ変更します
- `LETSENCRYPT_EMAIL` は証明書通知を受け取れるメールへ変更します
- `BASIC_AUTH_USER` / `BASIC_AUTH_PASSWORD` は管理画面用の強い認証情報へ変更します
- `WORDPRESS_UPSTREAM` などは各アプリのローカル公開ポートと一致させます
- 親 repo からまとめて使う場合は、`stack.service.env.local` の `GLOBAL__DOMAIN` や `GLOBAL__BASIC_AUTH_*` を使います

例:

```env
DOMAIN=ponkotu.mydns.jp
ROOT_HOST=ponkotu.mydns.jp
TTRSS_HOST=ttrss.ponkotu.mydns.jp
LETSENCRYPT_EMAIL=admin@ponkotu.mydns.jp
BASIC_AUTH_USER=admin
BASIC_AUTH_PASSWORD=自分で決めた強いパスワード
```

## 起動

```bash
cp .env.example .env.local
./scripts/init-layout.sh
docker compose --env-file .env.local up -d
```

## 方式

- Proxy: `Traefik v2.11`
- 証明書: Let's Encrypt `HTTP-01`
- 設定供給: `file provider`
- 公開ポート: host 側の `80/443`

Traefik の dashboard/API は secure mode で使い、`traefik.<domain>` から通常の router として公開します。

録画系と管理系の入口には Basic 認証をかけます。

- `munin.<domain>`
- `mirakurun.<domain>`
- `epgrec.<domain>`
- `epgstation.<domain>`
- `traefik.<domain>`

## データ配置

- `data/traefik/traefik.yml`
- `data/traefik/dynamic/routes.yml`
- `data/letsencrypt/acme.json`
- `data/log/`

`acme.json` は Traefik の ACME 保存先なので、`600` 権限で管理します。

## 初期化

```bash
./scripts/init-layout.sh
```

このスクリプトは次を行います。

- `data/` 配下の必要ディレクトリを作成
- `acme.json` を作成して権限を整える
- `.htpasswd` を生成して権限を整える
- Traefik の static / dynamic 設定を書き出す

Basic 認証の資格情報は `.env.local` の以下を使います。

- `BASIC_AUTH_USER`
- `BASIC_AUTH_PASSWORD`

## HTTPS 化

外部から `80/tcp` と `443/tcp` に到達できる前提で、Traefik 自身の ACME 取得を誘発します。

```bash
./scripts/request-certificates.sh
```

このスクリプトは次を行います。

- Traefik 設定を再生成
- Traefik を起動
- 各公開ホストへローカルから HTTPS アクセスして ACME 発行を誘発

`traefik.<domain>` は dashboard 用の補助ホストなので、ここだけ失敗しても他サービスの HTTPS 化は継続します。

## ホスト名

`.env.local` の以下を使います。

- `ROOT_HOST`
- `TTRSS_HOST`
- `MUNIN_HOST`
- `TATEGAKI_HOST`
- `SYNCTHING_HOST`
- `OPENVPN_HOST`
- `TRAEFIK_HOST`
- `MIRAKURUN_HOST`
- `EPGREC_HOST`
- `EPGSTATION_HOST`

録画 UI は `epgrec.<domain>` を旧構成互換の正面入口にしつつ、`epgstation.<domain>` も同じ UI へ流します。

## 補足

- 公開経路そのものはこの repo の責務ではありません
- `myip`、固定IP、ルータ転送などの回線固有設定は別管理です
- 初回導入は `docker-stack-installer` から呼ぶ前提です
