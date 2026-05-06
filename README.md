# infra-reverse-proxy

公開入口をまとめるリバースプロキシ用リポジトリです。
Traefik を使い、外部から来た通信を各 Docker サービスのローカル公開ポートへ振り分けます。

## 使い方

```bash
cp .env.example .env.local
./scripts/init-layout.sh
docker compose --env-file .env.local up -d
```

証明書を取得できる公開条件がそろっている場合:

```bash
./scripts/request-certificates.sh
```

## 変更する値

`.env.example` は公開用の見本です。実際の値は `.env.local` に書きます。

- `DOMAIN`: 公開する親ドメインです。
- `ROOT_HOST`: WordPress など、親ドメイン直下で出すホスト名です。
- `TTRSS_HOST` など: 各サービスの公開ホスト名です。
- `LETSENCRYPT_EMAIL`: 証明書通知を受け取るメールアドレスです。
- `BASIC_AUTH_USER` と `BASIC_AUTH_PASSWORD`: 管理系画面の認証情報です。
- `BASIC_AUTH_EXEMPT_SOURCE_RANGES`: Basic 認証を省略してよい送信元 IP 範囲です。
- `WORDPRESS_UPSTREAM` など: 各サービスの転送先です。
- `INFRA_REVERSE_PROXY__...`: 親リポジトリからまとめて設定するときに使います。

## 公開するもの

通常公開:

- WordPress
- Tiny Tiny RSS
- tategaki
- Syncthing
- OpenVPN

Basic 認証で保護する管理系:

- Munin
- Mirakurun
- epgrec
- EPGStation
- Traefik 管理画面

`BASIC_AUTH_EXEMPT_SOURCE_RANGES` には、既定でローカルアドレス、家庭内ネットワーク、Tailscale の IPv4 と IPv6 を入れています。

## データ

GitHub に上げるもの:

- `compose.yaml`
- `.env.example`
- `scripts/`
- `templates/`
- `README.md`

GitHub に上げないもの:

- `.env.local`
- `data/letsencrypt/acme.json`
- `data/log/`
- 生成済み設定ファイル

## 補足

- 公開回線、固定 IP、ルーター転送、ダイナミック DNS はこのリポジトリの担当外です。
- 初回導入は `docker-stack-installer` から呼び出す前提です。
