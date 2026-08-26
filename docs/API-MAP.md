# API map

Audit date: 2026-08-26. Paths were read from `theDesConnet/AnixartJS` and independently compared with `Maks1mio/anixapi` (API 9.x). `GET /release/101?extended_mode=true` against `https://api-s.anixsekai.com` returned HTTP 200 / `code: 0` on that date. Requests with JSON/form bodies are POST in AnixAPI; older AnixartJS sometimes omits the explicit method but its client infers POST.

| Function | Endpoint | Method | Authorization | Source | iOS status |
| --- | --- | --- | --- | --- | --- |
| Login | `/auth/signIn` form `login,password` | POST | no | both | implemented |
| Logout | no endpoint evidenced | — | local | both | local Keychain deletion |
| Current profile | `/profile/info` | GET | token | AnixAPI | implemented |
| Profile | `/profile/{id}` | GET | optional/token | both | implemented |
| Release list | `/filter/{page}` JSON | POST | optional | both | implemented |
| Release details | `/release/{id}?extended_mode=true` | GET | optional | both | implemented |
| Release search | `/search/releases/{page}` JSON + `API-Version:v2` | POST | optional | both | implemented |
| Profile search | `/search/profiles/{page}` JSON | POST | optional | both | implemented |
| Collection search | `/search/collections/{page}` JSON | POST | optional | both | implemented |
| Profile list/bookmarks | `/profile/list/all/{profile}/{status}/{page}` | GET | token | both | implemented |
| Change bookmark | `/profile/list/add/{status}/{release}`, `/profile/list/delete/{status}/{release}` | GET | token | both | implemented |
| History | `/history/{page}`, `/history/add/{release}/{source}/{episode}` | GET | token | both | implemented |
| Episode types | `/episode/{release}` | GET | optional | both | implemented |
| Episode sources | `/episode/{release}/{dubber}` | GET | optional | both | implemented |
| Episodes | `/episode/{release}/{dubber}/{source}?sort=1` | GET | optional | both | implemented |
| Target episode | `/episode/target/{release}/{source}/{position}` | GET | optional | both | implemented |
| Watch state | `/episode/watch/...`, `/episode/unwatch/...` | GET | token | both | implemented |
| Release comments | `/release/comment/all/{release}/{page}?sort=...` | GET | optional | both | implemented read-only |
| Similar/related | `/related/{related}/{page}` + `API-Version:v2` | GET | optional | both | implemented |
| Notifications | `/notification/all/{page}`, `/notification/read` | GET | token | both | implemented |
| Collections | `/collection/all/{page}`, `/collection/{id}`, `/collection/{id}/releases/{page}` | GET | optional | both | repository ready; UI deferred |
| Friends | `/profile/friend/all/{profile}/{page}` | GET | token | both | repository ready; UI deferred |
| Recommendations | `/discover/recommendations/{page}` | POST | token likely | both | not shown until authenticated/validated |
| Feed | `/feed/latest/all/{page}` (AnixAPI differs: `/feed/latest/all/{page}`) | GET | optional | differs | deferred pending device validation |
| Screenshots | fields `screenshots`/`screenshot_images` in release response | n/a | optional | both | implemented |
| Statistics/activity | fields in `/profile/{id}` | GET | optional | both | implemented |

## Authentication and transport

Both reference clients add the session token as query parameter `token`. AnixAPI 9.x defines base URL `https://api-s.anixsekai.com`; it also sends a mobile Anixart user agent. AniNova identifies itself as `AniNova/1.0 (iOS)` instead of impersonating the official client. API result code `0` means success, `401` is invalid/expired token; the client clears the local session on that code or HTTP 401.

## Deliberately unsupported

No endpoint is used for offline downloads or extraction of iframe/provider streams. See `LIMITATIONS.md`.

