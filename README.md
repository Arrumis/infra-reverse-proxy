# infra-reverse-proxy

公開入口をまとめるリバースプロキシ用リポジトリです。
トラエフィックを使い、外部から来た通信を各コンテナサービスの内部公開ポートへ振り分けます。

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
- `ROOT_HOST`: ブログなど、親ドメイン直下で出すホスト名です。
- `WWW_HOST`: `ROOT_HOST` へ転送する `www` ホスト名です。
- `TUNNEL_INTERNAL_PORT`: cloudflaredからだけ接続する、このサーバー内部専用の
  ポートです。
- `TTRSS_HOST` など: 各サービスの公開ホスト名です。
- `LETSENCRYPT_EMAIL`: 証明書通知を受け取るメールアドレスです。
- `BASIC_AUTH_USER` と `BASIC_AUTH_PASSWORD`: 管理系画面の認証情報です。
- `BASIC_AUTH_EXEMPT_SOURCE_RANGES`: 簡易認証を省略してよい送信元アドレス範囲です。
- `WORDPRESS_UPSTREAM` など: 各サービスの転送先です。
- `INFRA_REVERSE_PROXY__...`: 親リポジトリからまとめて設定するときに使います。

## 公開するもの

通常公開:

- ブログ
- 記事購読機能
- 縦書き小説リーダー
- ファイル同期機能
- 遠隔接続サーバー

簡易認証で保護する管理系:

- サーバー監視画面
- テレビチューナー管理画面
- 録画管理画面
- 番組録画管理画面
- リバースプロキシ管理画面

`BASIC_AUTH_EXEMPT_SOURCE_RANGES`には、既定でローカルアドレス、家庭内ネットワーク、
テイルスケールのIPv4とIPv6を入れています。

## クラウドフレアトンネル

生成されるトラエフィック設定には、`127.0.0.1:8089`で待ち受けるトンネル専用入口が含まれます。
この入口ではブログ、縦書き小説リーダー、`www`から親ドメインへの転送だけを扱います。
転送情報はこのサーバー内部からの接続だけを信頼するため、ブログはクラウドフレア側のHTTPSと
訪問者IPを正しく認識できます。

## データ

公開リポジトリに上げるもの:

- `compose.yaml`
- `.env.example`
- `scripts/`
- `templates/`
- `README.md`

公開リポジトリに上げないもの:

- `.env.local`
- `data/letsencrypt/acme.json`
- `data/log/`
- 生成済み設定ファイル

## 補足

- 公開回線、固定アドレス、ルーター転送、動的な名前解決はこのリポジトリの担当外です。
- 初回導入は `docker-stack-installer` から呼び出す前提です。
