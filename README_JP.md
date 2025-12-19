<div align="center">
  <h1>🥪 Sando</h1>
  <p><b>ソーシャルカレンダー & スケジュール自動調整アプリ</b></p>

  <p>
    <a href="README.md" style="text-decoration: none;">
      <img src="https://img.shields.io/badge/🇬🇧_English-Switch-gray?style=for-the-badge&labelColor=white&color=gray" alt="English"/>
    </a>
    &nbsp;&nbsp;
    <a href="README_JP.md" style="text-decoration: none;">
      <img src="https://img.shields.io/badge/🇯🇵_日本語-Active-BE0029?style=for-the-badge&labelColor=white&color=BE0029" alt="Japanese"/>
    </a>
  </p>
</div>
<br/>

<div id="-日本語-japanese"></div>

## 🇯🇵 日本語 (Japanese)

### 💡 アプリ概要
友だちと遊ぶ予定を立てるとき、お互いの空いている日を確認するのは非常に面倒です。「Sando」はそのような手間を解決する、スケジュール調整特化型のカレンダーアプリです。

Googleアカウントでログインするだけで、既存のGoogleカレンダーと連携。プライバシーを守りながら、スムーズに予定を調整できます。

**🏆 実績:** アプリ甲子園にて、**応募総数3,000作品の中からTOP24**に選出されました。

### ✨ 主な機能

1.  **Google Calendarとのシームレスな連携**
    * ログインするだけで自動同期。手動で予定を移す必要はありません。
2.  **プライバシーを保った共有**
    * 「予定がある」という事実のみを共有し、内容（「デート」「病院」など）は伏せられます。
3.  **高度なスケジュール検索機能**
    * 「日付範囲」「時間帯」「天気」「参加人数」を指定すると、最適な日時を自動提案します。
4.  **選択的なカレンダー共有**
    * 仕事用、プライベート用など、相手に合わせて共有するカレンダー（コンテンツ）を使い分けられます。
5.  **アプリ内チャット**
    * 日程調整の相談から決定まで、アプリ内で完結します。

### 📸 スクリーンショット
<details>
  <summary><b>クリックしてアプリ画面を見る（10枚）</b></summary>
  <br/>
  <div align="center">
    <table>
      <tr>
        <td><b>ログイン画面</b><br/><img src="LINK_IMG_1" width="250"/></td>
        <td><b>カレンダー表示</b><br/><img src="LINK_IMG_2" width="250"/></td>
        <td><b>予定の有無表示</b><br/><img src="LINK_IMG_3" width="250"/></td>
      </tr>
      <tr>
        <td><b>条件検索</b><br/><img src="LINK_IMG_4" width="250"/></td>
        <td><b>検索結果・提案</b><br/><img src="LINK_IMG_5" width="250"/></td>
        <td><b>追加リクエスト</b><br/><img src="LINK_IMG_6" width="250"/></td>
      </tr>
      <tr>
        <td><b>フレンド管理</b><br/><img src="LINK_IMG_7" width="250"/></td>
        <td><b>グループチャット</b><br/><img src="LINK_IMG_8" width="250"/></td>
        <td><b>設定</b><br/><img src="LINK_IMG_9" width="250"/></td>
      </tr>
    </table>
  </div>
</details>

### 💻 技術スタック・開発環境

**制作環境**
* **IDE:** Android Studio, VS Code
* **Framework:** Flutter (Dart)
* **Version Control:** GitHub Desktop

**サーバーサイド実装**
* **実行環境:** CORESERVER V2 CORE-X
* **言語:** PHP 7.4.33
* **DB:** MySQL
* **API:** Google OAuth2.0, Google Calendar API
* **外部データ:** 気象庁 (天気情報)

**特記事項**
Google Calendar APIのスマートウォッチ機能（Push Notifications）を使用し、カレンダーおよび予定情報をデータベースにリアルタイムで自動同期しています。

---
