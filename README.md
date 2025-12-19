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
        <td><b>Login & Setup</b><br/><img src="Images/Login.png" width="250"/></td>
        <td><b>Calendar View</b><br/><img src="Images/Calendar.png" width="250"/></td>
        <td><b>Profile</b><br/><img src="Images/Profile.png" width="250"/></td>
      </tr>
      <tr>
        <td><b>Search Conditions</b><br/><img src="Images/ScheduleSearch_open.png" width="250"/></td>
        <td><b>Search Results</b><br/><img src="Images/ScheduleSearchResult.png" width="250"/></td>
        <td><b>Event Request</b><br/><img src="Images/EventRequest.png" width="250"/></td>
      </tr>
      <tr>
        <td><b>Friend List</b><br/><img src="Images/FriendRequest.png" width="250"/></td>
        <td><b>Group Chat</b><br/><img src="Images/Chat.png" width="250"/></td>
        <td><b>Settings</b><br/><img src="Images/Profile.png" width="250"/></td>
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

<div align="center">
  <p>Created by <b>Masaaki Manabe</b> <b>Yuuki Uchida</b> <b>Shinji Suzuki<\b></p>
</div>
