# How to Submit to App Store Connect — JustZenGo

> **App:** JustZenGo | **Bundle ID:** com.ggsheng.JustZen | **Version:** 1.0.0+
> **Last Updated:** 2026-04-18

---

## Step 1: Prepare Build

1. Ensure latest code is on MacinCloud:
   ```bash
   cd ~/Desktop/ios-JustZenGo && git pull origin main
   ~/Desktop/xcodegen/bin/xcodegen generate
   ```

2. Build archive:
   ```bash
   xcodebuild archive -scheme JustZenGo -configuration Release \
     CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO \
     DEVELOPMENT_TEAM=9L6N2ZF26B
   ```

3. Open Xcode → Window → Organizer → Distribute App → App Store Connect → Sign and Upload

---

## Step 2: App Store Connect Configuration

Navigate to: https://appstoreconnect.apple.com → Apps → JustZenGo

### 2.1 App Information

| Field | Value |
|-------|-------|
| Default Language | English |
| Name | JustZen |
| Subtitle | 专注力训练 · 番茄工作法 · 效率提升 |
| Category | Productivity |
| Primary Category | Productivity |
| Secondary Category | (None) |
| Age Rating | 4+ |

### 2.2 Pricing and Availability

| Field | Value |
|-------|-------|
| Price Schedule | Free or Paid (your choice) |
| Availability | All territories |

### 2.3 App Privacy

| Field | Value |
|-------|-------|
| Privacy Policy | ✅ Required - URL to hosted PrivacyPolicy.html |
| Data Collection | No data collection - all local |

**Privacy Details:**
- **Health & Fitness:** No
- **Location:** No
- **Contact Info:** No
- **Identified Users:** No
- **Browsing History:** No
- **Purchases:** No
- **Crash Data:** No
- **Performance Data:** No
- **Advertising Data:** No

### 2.4 Widgets

Leave at default unless your app supports widgets.

---

## Step 3: App Store Listing

### 3.1 Localized Info (English)

**Promotional Text** (optional, updates without new version):
```
Your personal focus companion — AI-adaptive Pomodoro, ambient sounds, and detailed insights.
```

**Description** — Copy from `AppStore/Listing.md` Description section:
```
超过 100 项功能，史上最完整的专注力 app。

JustZen 将经典的番茄工作法提升到一个全新水平。结合 AI 智能适应、沉浸式环境音、详细的进度追踪，以及让你爱不释手的设计——帮助你重建专注力。

[... Full description in Listing.md ...]
```

**Keywords** — Copy from `AppStore/Listing.md` Keywords section:
```
focus timer, pomodoro, productivity, focus, concentration, study, work, timer, habit, tracker, time management, productivity app, deep work, mindfulness, focus music, white noise
```

**Support URL:** Your website URL (e.g., https://justzengo.app/support)

**Marketing URL:** (Optional) Your website URL

### 3.2 Screenshots

Upload from `AppStore/Screenshots/` directory:

| Device | Size | Files |
|--------|------|-------|
| iPhone 6.7" | 1290×2796 | 01_Home.png, 02_Statistics.png, 03_Intelligence.png, 04_Settings.png, 05_Achievements.png, 06_Shop.png, 07_Profile.png, 08_Projects.png |

### 3.3 App Icon

Automatically pulled from the 1024×1024 App Store Icon in your asset catalog.

---

## Step 4: Build Selection

After upload, select the build from the list:
- Build **version 1** (or latest) with status "Ready to Submit"

---

## Step 5: Certification

| Field | Value |
|-------|-------|
| Export Compliance | No (uses no encryption or standard encryption only) |
| Ads Identifier | No |

---

## Step 6: Submit for Review

1. Click **Add for Review**
2. Confirm all information is correct
3. Submit

**Typical Review Time:** 24-48 hours

---

## Quick Reference — JustZenGo App Store Content

All detailed content is in `AppStore/Listing.md`:
- Full description text
- Keywords list
- Screenshot specifications
- Version history

**Privacy Policy:** `AppStore/PrivacyPolicy.html` — host this file and provide URL

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Build not appearing | Wait 5-10 minutes after upload |
| Screenshots rejected | Ensure exactly 6.7" or correct sizes |
| Export compliance question | Answer "No" unless using special encryption |
| Missing required metadata | Ensure Privacy Policy URL is set |
