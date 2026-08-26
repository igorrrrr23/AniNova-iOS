# Architecture

`App` composes tab navigation and the authentication gate. `APIClient` owns URL construction, token query injection, encoding, retries, HTTP/API error mapping and decoding. Repositories expose feature-oriented async methods. SwiftUI feature view models own screen state; Keychain owns only the session token; `ProgressStore` owns non-secret local continuation data.

The project targets iOS 16. `AVPlayerViewController` is wrapped for native HLS, full-screen, Control Centre integration and Picture-in-Picture where the stream/provider permits it.

