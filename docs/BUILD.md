# Build and sideload

## Windows

1. Clone the repository and push it to your GitHub account.
2. Open **Actions → iOS CI → Run workflow**. It type-checks/tests and uploads an unsigned simulator build when successful.
3. A device IPA needs Apple signing. Do not add signing files or credentials to Git.

## macOS

1. Install Xcode 16 or newer and XcodeGen: `brew install xcodegen`.
2. At repository root run `xcodegen generate`, then open `AniNova.xcodeproj`.
3. Select the `AniNova` target, change `PRODUCT_BUNDLE_IDENTIFIER` from `com.example.AniNova`, select your Team, and connect your iPhone.
4. Run the app. For an archive use **Product → Archive**, then export an IPA with a signing method your account permits.

## GitHub signing (optional)

The supplied CI intentionally performs no signing. If you extend it, keep `APPLE_CERTIFICATE_P12_BASE64`, `APPLE_CERTIFICATE_PASSWORD`, `APPLE_PROVISIONING_PROFILE_BASE64`, and `KEYCHAIN_PASSWORD` solely as GitHub Actions secrets. A free/personal signing workflow is most safely performed in Xcode with your own Apple ID.

## AltStore

Export a signed IPA from Xcode, install/open AltServer on a computer, connect the iPhone, then choose the IPA in AltStore. Follow AltStore’s current documentation for trust and refresh requirements; neither Apple ID credentials nor certificates belong in this repository.

