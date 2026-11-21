# Pocket Wisdom 🌿

> *A little wisdom, always with you.*  
> An offline-first, mindful daily quote & reflection app built with Flutter as **Task 2 (Random Quote Generator)** for the **CodeAlpha App Development Internship**.

[![Download Android APK](https://img.shields.io/badge/Download-Android%20APK%20(v1.0.0)-213D2C?style=for-the-badge&logo=android&logoColor=white)](https://drive.google.com/file/d/1mmnSoX-yCMaoRH1ZhMrfXxGPXPp7oKSX/view?usp=drive_link)

---

## 📱 Live Android Build

- **Direct Release APK Download:** [Pocket Wisdom v1.0.0 (Google Drive)](https://drive.google.com/file/d/1mmnSoX-yCMaoRH1ZhMrfXxGPXPp7oKSX/view?usp=drive_link)

---
## ⚠️ Installation & Permissions Note

- **Installing the APK:** Since this release APK is distributed outside the Google Play Store, Android may ask you to allow **"Install unknown apps"** for your browser or file manager—tap **Allow** to proceed.
- **Notifications (Android 13+):** On first launch or when enabling daily reminders/sample notifications, tap **Allow** on the notification permission prompt.
- **Battery Optimization (Realme / Xiaomi / Oppo / Vivo):** Some custom Android skins restrict background alarms by default. If scheduled 8:30 AM reminders are delayed, open **App Info → Battery Usage** and enable **Allow background activity** (or set to **Unrestricted**).


## ✨ Key Features

- **Curated & Offline-First Wisdom:** 60+ handpicked quotes across **Motivation**, **Focus**, **Wisdom**, **Calm**, **Learning**, and **Resilience** with non-repeating randomized deck cycling.
- **Tactile Card Physics:** Swipe left/right with smooth rotation and spring snap-back, double-tap any card for a terracotta heart burst, or tap **New Quote** for fresh inspiration.
- **Personal Quote Journal (`My Quotes`):** Full offline CRUD (**Create, Read, Update, Delete**) for writing, editing, and managing your own personal mantras, persisted locally via JSON in `SharedPreferences`.
- **Share Studio (3x High-DPI PNG Export):** Render shareable quote cards in **Forest**, **Sunset**, **Paper**, and **Midnight** themes with a **4:5 Portrait / 1:1 Square** aspect-ratio toggle.
- **60-Second Pause & Breathe Pacer:** Built-in guided breathing sheet (`4s Inhale · 4s Hold · 4s Exhale`) synchronized with subtle haptic pulses—zero external audio files required.
- **Deep-Linked Daily Notifications:** Daily 8:30 AM scheduled reminders and instant status-bar previews using `flutter_local_notifications` + `timezone`. Tapping a notification opens directly to that exact quote.
- **Adaptive Forest & Dark Mode:** Custom botanical typography and color system (`#213D2C` Forest Green & `#D98A6C` Terracotta) with full Light and Dark theme persistence.

---

## 🛠️ Tech Stack & Architecture

- **Framework:** Flutter & Dart
- **Local Persistence:** `shared_preferences` (JSON serialization for custom quotes, favorites ordering, theme & reminder state)
- **Native Notifications:** `flutter_local_notifications` & `timezone` (Android 13+ runtime permissions, custom monochrome status-bar drawable, payload deep-linking, R8/ProGuard keep rules)
- **Image Rendering & Sharing:** Flutter `RepaintBoundary` (`3.0x` pixel ratio) + `share_plus`
- **Design Tooling:** Custom botanical vector painters (`CustomPainter`) & `google_fonts`

---

## 🚀 Getting Started

```bash
# 1. Clone the repository
git clone [https://github.com/hujaif21/CodeAlpha_Random_Quote_Generator.git](https://github.com/hujaif21/CodeAlpha_Random_Quote_Generator.git)
cd CodeAlpha_Random_Quote_Generator

# 2. Install dependencies
flutter pub get

# 3. Run on a connected Android device
flutter run

# 4. Build release APK
flutter build apk --release
The compiled APK will be generated at `build/app/outputs/flutter-apk/app-release.apk`.

---

## 👨‍💻 Author

**Hujaif Belim**  
App Development Intern @ **CodeAlpha**  
GitHub: [@hujaif21](https://github.com/hujaif21)
