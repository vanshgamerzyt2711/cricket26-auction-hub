# Cricket 26 Auction Hub — V5.0.0 Offline Installer

[Download V5 installer (420 MiB)](https://github.com/vanshgamerzyt2711/cricket26-auction-hub/releases/download/v5.0.0/Cricket26AuctionHub-Setup.exe) | [V5 release notes](https://github.com/vanshgamerzyt2711/cricket26-auction-hub/releases/tag/v5.0.0) | [Previous V4.0.1 small downloader](https://github.com/vanshgamerzyt2711/cricket26-auction-hub/releases/download/v4.0.1/Cricket26AuctionHub-Setup.exe)

**V5 is a packaging update, not a new app-feature version.** It contains the V4.0.1 application files in a standard offline Inno Setup installer with Desktop and Start Menu shortcuts, per-user installation, and an uninstaller.

**Existing V4 users:** V5 is an offline packaging-only release. It does **not** provide the legacy `Cricket26AuctionHub-update-manifest.json` or `Cricket26AuctionHub-update-win-x64.zip`, and its application binary still identifies itself as 4.0.1. Do not expect the old in-app updater to offer V5. Download the V5 installer manually, close the old app, back up your profiles/saves, and install without uninstalling your existing working version. The standard installer uses a separate per-user install directory, so automatic in-place migration is not supported. Do not publish a fabricated 5.0.0 update manifest until the app is actually rebuilt with updated version/update logic.

**Note:** This release is unsigned; 0 detections on a previously tested local installer do not certify this published binary or its contents. Update compatibility and the application itself require separate testing. Backup any existing installation before switching installers.

---

## Historical release notes

# Cricket 26 Auction Hub — V2.0.1 Fast Updates

For legally purchased copies of Cricket 26 only. We do not support piracy. The game is not included.

## Fast update fix

- Fixed Windows argument quoting for install folders ending with a backslash. This could make the old helper mistake an update for a fresh installation and download the entire app again.
- New Setup checks existing app files and downloads the small update package when the large runtime and auction assets already match. A full download is used for first installation or when required shared files need repair.
- Future in-app updates use the same small-patch route. Verified downloads are cached and reused. Already-current app files skip downloading entirely.
- Unchanged large files are verified and kept. Auction saves, profiles, game backups and game files are not included in app patches.
- Invalid update arguments now stop clearly instead of silently starting another full download.

## Existing V2 / V1 users

For this transition, close the old Hub and run the latest small Setup.exe ONCE. The older installed updater cannot retroactively gain the patch logic and may still download the full package. The new Setup can patch an existing compatible installation with the small payload; you do not need to uninstall or delete auction saves. After this upgrade, use Update & Restart normally.

Validation: Windows trailing-backslash argument round trip; small-patch install with full target-file validation; cached downloads reused without network; current install skips download; fresh/modified installations select full repair; unchanged-file timestamps and user saves preserved; locked-file rollback. V2 lineup, restore, voice-helper and Esc menu features remain included. New lineups/audio still require in-game verification.

Independent community tool, not an official Cricket 26/IPL product. 3D auction assets credited to Game Changer 5. Node notices included. Unsigned beta.
