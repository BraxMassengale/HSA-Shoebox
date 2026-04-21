# HSA Shoebox

HSA Shoebox is a SwiftUI iPhone app for the HSA "shoebox method": scan qualifying medical receipts, preserve the originals locally and in private iCloud sync, and keep a live unreimbursed total that represents your future tax-free reimbursement balance.

## Features

- VisionKit document scanning with multi-page capture
- OCR pre-fill for merchant, total, and date of service
- SwiftData persistence with private CloudKit sync
- Reimbursement bundles with PDF export
- Full backup export to ZIP with CSV, JSON, and receipt images
- Dynamic Type, Dark Mode, and VoiceOver-friendly SwiftUI screens

## Requirements

- Xcode 16 or later
- iOS 18 SDK
- A physical device or simulator running iOS 18+
- An Apple Developer team if you want to test CloudKit sync

## Build Steps

1. Open [HSAShoebox.xcodeproj](/Users/braxton/projects/hsa-shoebox/HSAShoebox.xcodeproj).
2. In Xcode, set your signing team for the `HSAShoebox` target.
3. Update the CloudKit container identifier in:
   - [HSAShoebox.entitlements](/Users/braxton/projects/hsa-shoebox/HSAShoebox/Resources/HSAShoebox.entitlements)
   - [Info.plist](/Users/braxton/projects/hsa-shoebox/HSAShoebox/Resources/Info.plist)
   - [HSAShoeboxApp.swift](/Users/braxton/projects/hsa-shoebox/HSAShoebox/App/HSAShoeboxApp.swift)
4. Enable the `iCloud` capability and check `CloudKit`.
5. Build and run the `HSAShoebox` scheme.

## CloudKit Setup

Use a private CloudKit container, for example `iCloud.com.yourcompany.HSAShoebox`.

Update these places to the same identifier:

- `CloudKitContainerIdentifier` in `Info.plist`
- `com.apple.developer.icloud-container-identifiers` in the entitlements file
- `com.apple.developer.ubiquity-container-identifiers` in the entitlements file
- The fallback identifier in `AppConfiguration`

SwiftData is configured with:

```swift
ModelConfiguration(cloudKitDatabase: .private("<your-container>"))
```

After the first successful build on a signed target, open the CloudKit Dashboard and deploy the development schema before testing production-style sync.

## Entitlements

The app expects these entitlements:

- iCloud
- CloudKit
- Ubiquity container identifier that matches the CloudKit container

## Required Info.plist Keys

- `NSCameraUsageDescription`
- `NSPhotoLibraryAddUsageDescription`
- `CloudKitContainerIdentifier` custom key used by the app bootstrap

## Tests

- `OCRParserTests`
- `ReimbursementTests`

Run them with:

```bash
xcodebuild test -project HSAShoebox.xcodeproj -scheme HSAShoebox -destination 'platform=iOS Simulator,name=iPhone 16'
```

## Privacy

All data is stored on your device and your private iCloud. No analytics, no network calls beyond iCloud sync.
