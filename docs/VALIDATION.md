# Validation record

* 2026-08-26: public API probe `GET https://api-s.anixsekai.com/release/101?extended_mode=true` returned HTTP 200 and `code: 0`.
* 2026-08-26: AnixartJS and AnixAPI source was independently cloned at depth 1 and endpoint paths/parameters were compared; results are recorded in `API-MAP.md`.
* Windows has no Swift or Xcode toolchain in this workspace, so native compilation cannot be claimed locally. `.github/workflows/ios.yml` is the required macOS build/test gate. The first GitHub Actions run must be treated as the compilation verification.

