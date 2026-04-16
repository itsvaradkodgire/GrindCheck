# GRINDCHECK — Xcode Setup Guide

## Phase 1 is done. Here's how to get it running.

---

## Step 1 — Create the Xcode Project

1. Open Xcode → **File → New → Project**
2. Template: **Multiplatform → App**
3. Fill in:
   - Product Name: `GrindCheck`
   - Bundle ID: `com.yourname.grindcheck`
   - Interface: **SwiftUI**
   - Storage: **SwiftData** ← important
   - Language: **Swift**
   - Check **Include Tests** if you want
4. **Save to this directory** (or move files here after)

---

## Step 2 — Add the Source Files

Delete the auto-generated files Xcode creates:
- `ContentView.swift` — we have our own root view
- Any auto-generated SwiftData sample models

Then drag the entire `GrindCheck/` folder from this directory into Xcode:
- Make sure **"Copy items if needed"** is checked
- Target membership: both **iOS** and **macOS**

The final structure in Xcode should mirror:
```
GrindCheck/
├── GrindCheckApp.swift
├── Models/
│   ├── Enums.swift
│   ├── UserProfile.swift
│   ├── Subject.swift
│   ├── Topic.swift
│   ├── Question.swift
│   ├── QuizAttempt.swift
│   ├── StudySession.swift
│   ├── DailyLog.swift
│   └── Achievement.swift
├── Views/
│   ├── Shared/
│   ├── Dashboard/
│   └── Subjects/
├── Utilities/
│   ├── Constants.swift
│   ├── Extensions.swift
│   └── HapticManager.swift
└── Resources/
    ├── SeedDataManager.swift
    ├── BrutalMessages.swift
    └── AchievementDefinitions.swift
```

---

## Step 3 — Configure Capabilities

### iCloud + CloudKit (for Mac ↔ iPhone sync)
1. Select your project in the navigator → **Signing & Capabilities**
2. Select your **iOS target**
3. Click **+ Capability** → add **iCloud**
4. Check **CloudKit**
5. Create a new container: `iCloud.com.yourname.grindcheck`
6. Repeat for the **macOS target** using the SAME container name
7. In `GrindCheckApp.swift`, replace the local `ModelConfiguration` with the CloudKit version (see the comment in the file)

### Background Modes (for Widgets & timers — Phase 5)
1. **+ Capability** → **Background Modes**
2. Check: **Background fetch**, **Remote notifications**

### Keychain Sharing (for Gemini API key — Phase 4)
1. **+ Capability** → **Keychain Sharing**
2. Add group: `com.yourname.grindcheck`

---

## Step 4 — Set Deployment Targets

- iOS: **17.0** minimum (SwiftData requires iOS 17+)
- macOS: **14.0** minimum (SwiftData requires macOS 14+)

In Project settings → General → Deployment Info

---

## Step 5 — Build & Run

1. Select the **iOS simulator** (iPhone 15 or newer)
2. **Cmd+R** to build and run
3. First launch seeds 8 subjects, ~60 topics, ~50 questions, 14 days of daily logs
4. The app opens on the Feed tab (placeholder) — tap **Subjects** or **Dashboard**

For macOS: switch the scheme to the macOS target and run.

---

## What's in Phase 1

| Feature | Status |
|---|---|
| SwiftData models (all 8) | ✅ Done |
| iCloud sync (CloudKit config) | ✅ Ready (enable in Xcode) |
| iOS Tab Navigation | ✅ Done |
| macOS Sidebar Navigation | ✅ Done |
| Dashboard (reality check, stats, XP) | ✅ Done |
| Subjects grid + CRUD | ✅ Done |
| Subject detail with topic list | ✅ Done |
| Topic detail with proficiency | ✅ Done |
| Add questions (manual) | ✅ Done |
| Bulk add topics | ✅ Done |
| Seed data (8 subjects, real questions) | ✅ Done |
| BrutalMessages (150+ messages) | ✅ Done |
| Achievement definitions (55 achievements) | ✅ Done |
| HapticManager | ✅ Done |

---

## Next Phases

**Phase 2 — The Feed (the Instagram killer)**
- `ScrollFeedView` with vertical snap paging
- All 6 card types (Quiz, Flashcard, Reality Check, Stats, Achievement Tease, Challenge)
- Swipe gestures, combo multiplier, XP animations
- Haptic feedback everywhere

**Phase 3 — Quiz Engine + Study Timer**
- All 5 quiz modes with adaptive difficulty
- Quiz results with brutal feedback
- Pomodoro study timer
- Post-session summaries

**Phase 4 — AI + Gamification**
- GeminiService direct REST API
- AI question generation + review flow
- XP system + level-up animations
- All 55 achievements with unlock popups
- Daily challenges

**Phase 5 — Analytics + Polish**
- Swift Charts heatmap, trend lines
- Reality Score™ algorithm
- iOS Widgets
- Mac menu bar item
- Weekly reality report

---

## Troubleshooting

**Build error: "Cannot find type X"**
→ Make sure all files are added to both targets (iOS + macOS)

**"Unsupported OS version" warning**
→ Set deployment targets to iOS 17.0 / macOS 14.0

**CloudKit sync not working**
→ Must be signed in to iCloud on both devices; same container in both targets

**Seed data not appearing**
→ Delete the app from simulator (wipes SwiftData store) and re-run

**macOS Sidebar shows blank**
→ Make sure `MacNavigationView.swift` is included in the macOS target
