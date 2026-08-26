# AniNova for iOS

Native SwiftUI client for Anixart. It uses `URLSession`, `async/await`, `AVKit`, `AVFoundation`, `Codable`, and Keychain; it is not a WebView or an Electron port.

> Unofficial client. Use only with an account and content you are authorised to access. The API is undocumented and may change or block third-party clients.

## Start

Windows: push this repository to GitHub and run **iOS CI**. The workflow generates an unsigned simulator build artifact.

macOS: install Xcode 16+ and [XcodeGen](https://github.com/yonaskolb/XcodeGen), then run `xcodegen generate`, open `AniNova.xcodeproj`, select your Team and a unique bundle identifier, then run on an iPhone.

See [Build guide](docs/BUILD.md), [API map](docs/API-MAP.md), and [limitations](docs/LIMITATIONS.md).

## Licence and attribution

AniNova is released under GPL-2.0-or-later. It is a clean-room Swift implementation; no TypeScript source from the reference projects is included. API facts were audited from AnixartJS and AnixAPI; see [THIRD-PARTY-NOTICES.md](THIRD-PARTY-NOTICES.md).

