<div align="center">
  <h1>🥪 Sando</h1>
  <p><b>Social Calendar & Smart Scheduling Application</b></p>

  <p>
    <a href="README.md" style="text-decoration: none;">
      <img src="https://img.shields.io/badge/🇬🇧_English-Active-00599C?style=for-the-badge&labelColor=white&color=00599C" alt="English"/>
    </a>
    &nbsp;&nbsp;
    <a href="README_JP.md" style="text-decoration: none;">
      <img src="https://img.shields.io/badge/🇯🇵_日本語-Switch-gray?style=for-the-badge&labelColor=white&color=gray" alt="Japanese"/>
    </a>
  </p>
</div>
<br/>

## 🇬🇧 English

### 💡 Overview
**Sando** solves the hassle of coordinating schedules with friends. Instead of listing out every free date or explaining when you are busy, Sando syncs directly with Google Calendar to streamline social planning.

It balances **convenience** with **privacy**. Users can share their free/busy status with friends or groups without revealing the specific details of their private appointments.

**🏆 Recognition:** Selected as **Top 24 out of 3,000 applicants** in the *Appli Koushien* competition.

### ✨ Key Features

* **🔒 Privacy-First Sharing:** Share *availability* (free/busy) without sharing *content* (what you are doing).
* **🧩 Smart Content Grouping:** Combine multiple calendars (e.g., Work + Private) into specific "Contents" to share with different friend groups.
* **🔎 Smart Scheduling:** Input conditions (weather, participants, time range), and the app suggests the optimal schedule.
* **💬 In-App Chat:** Discuss plans directly within the calendar view.
* **⚡ Seamless Sync:** Accepted events are automatically added to your native Google Calendar.

### 📸 Gallery
<details>
  <summary><b>Click to view 10+ Screenshots</b></summary>
  <br/>
  <div align="center">
    <table>
      <tr>
        <td><b>Login & Setup</b><br/><img src="LINK_IMG_1" width="250"/></td>
        <td><b>Calendar View</b><br/><img src="LINK_IMG_2" width="250"/></td>
        <td><b>Availability Heatmap</b><br/><img src="LINK_IMG_3" width="250"/></td>
      </tr>
      <tr>
        <td><b>Search Conditions</b><br/><img src="LINK_IMG_4" width="250"/></td>
        <td><b>Search Results</b><br/><img src="LINK_IMG_5" width="250"/></td>
        <td><b>Event Request</b><br/><img src="LINK_IMG_6" width="250"/></td>
      </tr>
      <tr>
        <td><b>Friend List</b><br/><img src="LINK_IMG_7" width="250"/></td>
        <td><b>Group Chat</b><br/><img src="LINK_IMG_8" width="250"/></td>
        <td><b>Settings</b><br/><img src="LINK_IMG_9" width="250"/></td>
      </tr>
    </table>
  </div>
</details>

### 🛠 Technical Architecture

| Component | Tech Stack |
| :--- | :--- |
| **Frontend** | Flutter, Dart (Android Studio / VS Code) |
| **Backend** | PHP 7.4.33 (Coreserver V2 CORE-X) |
| **Database** | MySQL (phpMyAdmin) |
| **APIs** | Google OAuth 2.0, Google Calendar API, JMA Weather API |
| **Sync Logic** | Google Calendar Push Notifications (Watch API) for real-time DB sync |

---

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

<div align="center">
  <p>Created by <b>Masaaki Manabe</b></p>
</div>
