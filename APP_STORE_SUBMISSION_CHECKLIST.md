# RackRush Kids - App Store Submission Checklist

**App Name:** RackRush Kids  
**Bundle ID:** com.rackrush.kids  
**Version:** 1.0  
**Target:** iOS 17.0+  
**Category:** Education > Word Games (Made for Kids)

---

## ✅ Pre-Submission Technical Checks

### Build & Code
- [ ] Clean build succeeds (`xcodebuild clean build`)
- [ ] No compiler warnings
- [ ] No force-unwraps in production code
- [ ] Memory leaks checked with Instruments
- [ ] Test on physical device (not just simulator)
- [ ] Test offline mode works completely

### Assets
- [x] App Icon - 1024x1024 (App Store)
- [x] App Icon - All device sizes (120, 152, 167, 180)
- [ ] Screenshots - iPhone 6.7" (1290 x 2796)
- [ ] Screenshots - iPhone 6.1" (1179 x 2556)
- [ ] Screenshots - iPad 12.9" (2048 x 2732)
- [ ] App Preview video (optional but recommended)

### Required Files in Bundle
- [x] Info.plist configured
- [x] PrivacyInfo.xcprivacy (Privacy Manifest)
- [x] PRIVACY_POLICY.md
- [x] RackRushKids.entitlements
- [x] All sound files (.wav)
- [x] Dictionary files (kids_enable.txt, kids_definitions.json)

---

## ✅ Kids Category Requirements

### Made for Kids Declaration
- [ ] In App Store Connect: Age Band = "Ages 5-8" or "Ages 6-8"
- [ ] Confirm "Made for Kids" checkbox
- [ ] No external links accessible to children
- [ ] All external links gated behind parental controls ✅

### COPPA Compliance
- [x] No personal data collection from children
- [x] No behavioral tracking
- [x] No third-party advertising
- [x] No social media integration
- [x] No in-app purchases targeting children
- [x] Parental gate for settings (PIN required)

### Content Safety
- [x] Age-appropriate vocabulary (UK DfE KS2)
- [x] Multi-layer word filtering/blocklist
- [x] No user-generated content visible to children
- [x] No chat or messaging features

---

## ✅ Privacy Requirements

### Privacy Manifest (PrivacyInfo.xcprivacy)
- [x] NSPrivacyTracking = false
- [x] NSPrivacyTrackingDomains = empty
- [x] NSPrivacyCollectedDataTypes = DeviceID (App Functionality only)
- [x] NSPrivacyAccessedAPITypes = UserDefaults (CA92.1)

### App Store Privacy Questions
When filling out App Store Connect privacy section:

| Data Type | Collected? | Purpose | Linked to Identity? |
|-----------|------------|---------|---------------------|
| Device ID | Yes | App Functionality (matchmaking) | No |
| Game Progress | Yes (on-device) | App Functionality | No |
| Other Data | No | - | - |

---

## ✅ App Store Connect Setup

### Basic Information
- [ ] **App Name:** RackRush Kids
- [ ] **Subtitle:** Learn Words, Have Fun!
- [ ] **Bundle ID:** com.rackrush.kids
- [ ] **SKU:** rackrush-kids-2026
- [ ] **Primary Language:** English (US)

### Category & Age Rating
- [ ] **Primary Category:** Education
- [ ] **Secondary Category:** Games > Word
- [ ] **Age Rating:** 4+ (no objectionable content)
- [ ] **Made for Kids:** Yes
- [ ] **Age Band:** 5-8 years

### URLs (Required)
- [ ] **Privacy Policy URL:** https://playrackrush.com/privacy
- [ ] **Support URL:** https://playrackrush.com/support
- [ ] **Marketing URL:** (optional)

### Pricing
- [ ] **Price:** Free
- [ ] **In-App Purchases:** None

---

## ✅ Screenshot Checklist

Capture these screens on iPhone 15 Pro Max (6.7"):

1. **Home Screen** - Shows RACK RUSH logo, avatar, streak badge
2. **Gameplay** - Mid-game with letters and score
3. **Word Definition** - Show a word being learned
4. **Sticker Book** - Collection of earned stickers
5. **Adventure Map** - Islands with stars
6. **Victory Screen** - Winning celebration with confetti
7. **Onboarding** - Benny the Bear welcome screen
8. **Parental Controls** - Progress report (for parents)

### Screenshot Tips for Kids Apps
- Use bright, colorful screens
- Show achievements and rewards
- Include the mascot (Benny Bear)
- Avoid showing any external links or settings

---

## ✅ App Store Description

### Short Description (Subtitle)
```
Learn Words, Have Fun!
```

### Full Description
See APP_STORE_DESCRIPTION.md

### Keywords (100 characters max)
```
word game,kids,spelling,education,vocabulary,learn,children,letters,puzzle,fun
```

### What's New (Version 1.0)
```
Welcome to RackRush Kids! 🎉

• Spell words and compete against friendly opponents
• Earn stars, stickers, and badges
• Build your daily streak
• Learn new words every day
• Fun for ages 5-12!
```

---

## ✅ Review Notes for Apple

Provide this in the "Notes for Review" field:

```
RackRush Kids is an educational word game designed for children ages 5-12.

PARENTAL CONTROLS:
To access Parental Controls, tap the gear icon on the home screen, then tap "Parental Controls". You will be prompted to set a 4-digit PIN on first use.

TEST INSTRUCTIONS:
1. Launch the app
2. Follow the onboarding tutorial (or tap Skip)
3. Tap "Play" to start a game against the computer
4. Tap letters to spell words, then tap the checkmark to submit
5. The game plays 5 rounds, then shows results

KIDS SAFETY:
- No ads
- No in-app purchases
- No external links accessible to children
- All settings behind parental PIN
- Offline gameplay fully supported

This app is designed for the "Made for Kids" category, age band 5-8.
```

---

## ✅ Final Steps

### Before Submitting
1. [ ] Archive build created (`Product > Archive`)
2. [ ] Validate archive (no errors)
3. [ ] Upload to App Store Connect
4. [ ] Fill in all metadata fields
5. [ ] Upload screenshots for all required sizes
6. [ ] Complete privacy questionnaire
7. [ ] Set pricing to Free
8. [ ] Select "Made for Kids" age band

### After Submitting
- [ ] Monitor for review feedback
- [ ] Respond to any rejection reasons promptly
- [ ] Typical review time: 1-3 days for Kids apps

---

## 🚨 Common Rejection Reasons (Avoid These)

1. **External links** - Make sure NO links are accessible without parental gate
2. **Missing privacy policy** - Must be accessible from App Store and in-app
3. **Unclear parental gate** - PIN must be required for all settings
4. **Age-inappropriate content** - Verify word list is 100% safe
5. **Broken offline mode** - App must work fully without internet
6. **Missing screenshots** - Need all required device sizes

---

## ✅ Quick Commands

```bash
# Clean and build
xcodebuild clean build -scheme RackRushKids -destination 'generic/platform=iOS'

# Archive for distribution
xcodebuild archive -scheme RackRushKids -archivePath build/RackRushKids.xcarchive

# Validate archive
xcrun altool --validate-app -f build/RackRushKids.ipa -t ios

# Upload to App Store
xcrun altool --upload-app -f build/RackRushKids.ipa -t ios
```

---

**Ready to submit!** 🚀
