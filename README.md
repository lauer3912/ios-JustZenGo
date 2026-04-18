# JustZenGo

> AI-Adaptive Pomodoro & Focus Timer for iPhone

**Version:** 1.0.0+ | **Bundle ID:** com.ggsheng.JustZen

---

## App Store

- [App Store Listing Content](AppStore/Listing.md)
- [App Store Connect Submission Guide](AppStore/HOW-TO-AppStoreConnect.md)
- [Privacy Policy](AppStore/PrivacyPolicy.html)

## Screenshots

Captured screenshots available in `AppStore/Screenshots/` (8 unique UITest-verified screenshots).

---

## Build Instructions

### MacinCloud Build

```bash
cd ~/Desktop/ios-JustZenGo
git pull origin main
~/Desktop/xcodegen/bin/xcodegen generate
xcodebuild archive -scheme JustZenGo -configuration Release \
  CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO \
  DEVELOPMENT_TEAM=9L6N2ZF26B
```

### Xcode Build (MacinCloud Desktop)

1. Open `JustZenGo.xcodeproj`
2. Select iPhone simulator
3. Cmd+B to build

### Upload to App Store Connect

1. Xcode → Window → Organizer
2. Select JustZenGo archive
3. Distribute App → App Store Connect → Sign and Upload

---

## Project Structure

```
ios-JustZenGo/
├── AppStore/
│   ├── Listing.md              # App Store listing content
│   ├── HOW-TO-AppStoreConnect.md # Submission guide
│   ├── PrivacyPolicy.html       # Privacy policy template
│   └── Screenshots/             # UITest screenshots (8)
├── JustZenGo/
│   ├── Sources/
│   │   ├── App/
│   │   ├── Models/
│   │   ├── ViewModels/
│   │   ├── Views/
│   │   └── Utils/
│   └── Assets.xcassets/
├── JustZenGoWidget/             # iOS Widget extension
├── JustZenGoUITests/            # UITest for screenshots
├── project.yml
└── SPEC.md                     # Product specification
```

---

## Features

- AI-adaptive Pomodoro sessions
- 12+ ambient sounds (AVAudioEngine)
- Focus session tracking
- Statistics & insights
- Achievements system
- Projects management
- Wind Down mode
- iOS Widget

---

## Development

- **XcodeGen** for project generation
- **SwiftUI** for UI
- **WidgetKit** for iOS Widget
- **UserDefaults** for local persistence
- **No external dependencies** (fully offline capable)
