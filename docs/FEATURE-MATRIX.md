# Feature matrix

| Feature | AnixApp | AnixartJS | AnixAPI | iOS implementation | Status |
| --- | --- | --- | --- | --- | --- |
| Sign in/token | yes | yes | yes | Keychain + session restore | implemented |
| Home categories | yes | filter | filter | native filter-backed catalog | implemented |
| Search | releases/profiles/collections | yes | yes | debounced native search + local history | implemented |
| Release details | yes | yes | yes | native detail, screenshots/comments/related | implemented |
| Bookmarks | yes | yes | yes | server list and status mutation | implemented |
| Profile/statistics | yes | yes | yes | self/other profile | implemented |
| Notifications | yes | yes | yes | pageable list/read | implemented |
| Episodes/dubs/sources | yes | yes | yes | source hierarchy; no assumed URL | implemented |
| Native player | hls.js | model only | model only | AVPlayer/PiP for direct non-iframe media only | implemented with provider limitation |
| Continue watching | yes | history endpoint | history endpoint | local exact-position + server episode history | implemented |
| Downloads | ffmpeg desktop | no | no | not exposed on iOS | unsupported by design |
| Collections UI | yes | partial | yes | API map/repository planned | deferred |
| Friends UI | yes | yes | yes | API map/repository planned | deferred |
| Themes | yes | n/a | n/a | System/Dark/Light/AMOLED | implemented |

