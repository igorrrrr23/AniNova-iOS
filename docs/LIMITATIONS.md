# Limitations

* Anixart exposes no documented public API contract. The implementation is based on independently audited open-source clients and uses only evidenced paths.
* The service’s current domain is `https://api-s.anixsekai.com`, confirmed by a read-only `GET /release/101` on 2026-08-26. It can change; `APIClient.Configuration` centralises it.
* The desktop client’s HLS downloader joins segments with FFmpeg. That architecture is not usable on iOS. AniNova deliberately does not present an offline-download control. Native playback is provided only for a directly returned playable URL that AVFoundation can load.
* API episode records may contain an iframe rather than a directly playable HLS URL. AniNova does not embed the iframe or use a WebView; it reports that source as unavailable to the native player.
* No documented server endpoint saves playback time. Completion/episode state is synchronised through `/history/add` and `/episode/watch` when authenticated; exact seconds stay local.
* There is no evidenced logout endpoint. Logout securely deletes the local token and local account state.

