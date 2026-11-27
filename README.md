# エンジニア案件管理 — セットアップ手順

エンジニアごとの月別の案件数・単価・売上を管理するWebシステムです。
画面は **GitHub Pages**、ログインとデータ保存は **Supabase** で動かします。使う人は Claude も GitHub も不要で、メールアドレスとパスワードだけでログインできます。

## ファイル構成

| ファイル | 中身 |
|---|---|
| `index.html` | 画面とプログラム本体（変更不要） |
| `config.js` | Supabase の接続情報（手順3で書き換える） |
| `schema.sql` | Supabase に作るデータの表とアクセス制限（手順2で実行） |
| `seed.sql` | 動作確認用のサンプルデータ（任意） |

---

## 手順1〜3　Supabase の準備 ✅ 完了済み

プロジェクト作成（東京）、データの表とアクセス制限の作成、`config.js` への接続情報の設定は済んでいます。作り直すときだけ以下を参照してください。

### 手順1　Supabase のプロジェクトを作る

1. https://supabase.com にアクセスし「Start your project」から登録します（GitHub アカウントで登録できます）。
2. 「New project」を押し、次のとおり入力して作成します。
   - Name：`anken`（任意）
   - Database Password：自動生成のままでOK（念のため控えておく）
   - Region：**Northeast Asia (Tokyo)**
3. 作成完了まで1〜2分待ちます。

### 手順2　データの表を作る

1. 左メニューの **SQL Editor** を開きます。
2. `schema.sql` の中身を丸ごと貼り付けて **Run** を押します。「Success」と出ればOKです。
3. （任意）サンプルデータで試したい場合は、同じように `seed.sql` を実行します。

> この設定により、**ログインした人だけ**がデータを見たり変更したりできます。未ログインの人には一切見えません。

### 手順3　接続情報を config.js に貼る

1. 画面上部の **Connect** ボタン（または左下の Project Settings → API / API Keys）を開きます。
2. 次の2つをコピーし、`config.js` の該当箇所に貼り付けます。
   - **Project URL**（`https://xxxx.supabase.co`）→ `SUPABASE_URL`
   - **anon public key**（または `sb_publishable_` で始まるキー）→ `SUPABASE_ANON_KEY`

> ⚠️ `service_role` / `secret` と書かれたキーは**絶対に貼らないでください**。anon / publishable キーは公開されても問題ない設計です（手順2のアクセス制限で守られます）。

## 手順4　ログイン設定とアカウント作成

1. 左メニュー **Authentication** → **Sign In / Providers**（または Settings）で、
   - **Allow new users to sign up をオフ**にします（知らない人が勝手に登録できないようにするため）。
   - Email が有効になっていることを確認します。
2. **Authentication → Users → Add user → Create new user** を開き、最初のアカウントを作ります。
   - Email：`k-onomura@legarea.jp`
   - Password：任意のパスワード
   - **Auto Confirm User にチェック**
3. これでこのメールアドレスとパスワードでログインできるようになります（ログイン後、画面右上の「パスワード変更」から変更も可能）。

## 手順5　GitHub Pages で公開する

1. https://github.com でアカウントを作ります。
2. 右上の「＋」→ **New repository** で、名前（例：`anken`）を付けて作成します。
   - 無料プランで GitHub Pages を使う場合は **Public** を選びます。プログラムが見えるだけで、案件などのデータは Supabase 側にありログインなしでは見えません。
3. 作成したリポジトリで **Add file → Upload files** を押し、`index.html` と `config.js`（書き換え済み）をアップロードして **Commit changes** を押します。
   （`schema.sql` などはアップロードしなくても動きます）
4. リポジトリの **Settings → Pages** を開き、
   - Source：**Deploy from a branch**
   - Branch：**main** / **/(root)** を選んで **Save**
5. 1〜2分後、同じ画面に表示されるURL（例：`https://ユーザー名.github.io/anken/`）を開くとログイン画面が出ます。

## 手順6　Supabase にURLを登録する

パスワード再設定メールや招待メールのリンク先を正しくするための設定です。

1. Supabase の **Authentication → URL Configuration** を開きます。
2. **Site URL** に手順5のURL（例：`https://ユーザー名.github.io/anken/`）を入れて保存します。
3. **Redirect URLs** にも同じURLを追加します。

---

## アカウントを追加するとき

- **Authentication → Users → Invite user** でメールアドレスを入れて招待します。
- 相手に届いたメールのリンクを開くと、パスワード設定画面が表示されます。設定後そのまま使えます。
- 手順4-2の「Create new user」でパスワードを決めて作り、本人に伝える方法でもOKです。
- 使わなくなった人は **Users** の一覧から削除すればログインできなくなります。

## パスワードを忘れたとき

ログイン画面の「パスワードを忘れた場合」からメールアドレスを入れると、再設定用のリンクが届きます。

## 知っておきたいこと

- Supabase 標準のメール送信は**1時間あたりの送信数に制限**があります。招待やパスワード再設定を頻繁に使うようになったら、Authentication → Emails で自社のメールサーバー（SMTP）を設定してください。
- Supabase の無料プランは、**一定期間アクセスがないとプロジェクトが一時停止**されることがあります。停止された場合は Supabase の管理画面から再開できます。
- ほかの人が変更した内容は、画面を開き直すと反映されます。
