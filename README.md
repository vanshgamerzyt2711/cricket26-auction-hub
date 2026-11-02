# Cricket 26 Auction Hub — V5.0.2 Smooth UI Stable + Automatic Updates

**Latest stable — V5.0.2:** [Release / changelog](https://github.com/vanshgamerzyt2711/cricket26-auction-hub/releases/tag/v5.0.2) | [Offline installer](https://github.com/vanshgamerzyt2711/cricket26-auction-hub/releases/download/v5.0.2/Cricket26AuctionHub-Setup.exe). The existing **Updates / Update & Restart** control in older V4/V5 installations can detect this newer non-prerelease release. No new update button or logo overlay has been added. Smooth UI changes reduce heavyweight transitions and redraw flicker. The V5.0.2 stable release contains the full ZIP, patch ZIP and update manifest required by the old updater; older installations may use the full-package fallback. Back up saves before upgrading. Real end-to-end Windows tests are still needed.


> **Optional historical test build (V5.0.2 beta 1):** [Download the optional Windows installer](https://github.com/vanshgamerzyt2711/cricket26-auction-hub/releases/download/v5.0.2-beta.1/Cricket26AuctionHub-Setup.exe) or [review the beta release](https://github.com/vanshgamerzyt2711/cricket26-auction-hub/releases/tag/v5.0.2-beta.1). It removes the expensive two-screenshot tab-transition animation and double-buffers form/pages/lists to reduce flickering. **This is not the latest stable version and is not sent as an automatic update.** Back up your auctions before testing; Windows UI testing on a user desktop is still needed. The stable V5.0.1 release stays unchanged.


[Download previous V5.0.1 installer](https://github.com/vanshgamerzyt2711/cricket26-auction-hub/releases/download/v5.0.1/Cricket26AuctionHub-Setup.exe) | [Latest release](https://github.com/vanshgamerzyt2711/cricket26-auction-hub/releases/latest) | [Update troubleshooting](https://github.com/vanshgamerzyt2711/cricket26-auction-hub/issues/1)

**V4 users:** V5.0.1 has a verified full ZIP and delta patch/manifest required by the V4 updater. On startup, V4 should offer **Update & Restart**. It updates the existing app files in place; backups remain outside the app in `%LOCALAPPDATA%\Cricket26AuctionHub\UserData`. Do not uninstall the old app before updating.

**New installations:** The V5.0.1 offline installer creates Desktop and Start Menu shortcuts. It uses a separate install directory, so existing V4 users should use the in-app updater to avoid duplicate installations.

**Security:** Core gameplay features remain based on V4.0.1. Internal version markers were updated to V5.0.1. Repackaging does not remove malware or guarantee 0 antivirus detections. Keep antivirus enabled and preserve a backup.

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
