# Cricket 26 Auction Hub — V6.0.0 Smooth UI + Existing One-Click Updates

**Latest stable V6.0.0:** [Release details](https://github.com/vanshgamerzyt2711/cricket26-auction-hub/releases/tag/v6.0.0) | [GitHub latest](https://github.com/vanshgamerzyt2711/cricket26-auction-hub/releases/latest). Existing compatible installations with a functioning updater can use the app's **Updates → Update & Restart** button to install V6 **with one click and no commands**. V6's verified full and delta ZIPs preserve the old update scheme and include the path-fixed updater from V5.0.3. V6 also carries the smooth UI improvements already introduced in V5.0.2. Stable build and archive checks passed in GitHub Actions; user-machine testing is still required.

**Already broken V5 Inno updater limitation:** If a pre-V5.0.3 Inno-installed app displays `Setup can only update its own installed app folder`, **GitHub cannot repair that installed helper just by publishing V6** because it rejects the folder *before* installing any newer release. A one-time [graphical 2.2 MB updater repair](https://github.com/vanshgamerzyt2711/cricket26-auction-hub/releases/download/v5.0.3/Cricket26AuctionHub-UpdateRepair.exe) (no CMD) is required for these old installations. After the repair, they can update in-app directly to V6 and update normally thereafter. Don't tell these users that V6 alone resolves the preexisting installed helper.

---


**Previous stable V5.0.3 (updater recovery):** [Latest release](https://github.com/vanshgamerzyt2711/cricket26-auction-hub/releases/latest) | [Download one-time repair installer](https://github.com/vanshgamerzyt2711/cricket26-auction-hub/releases/download/v5.0.3/Cricket26AuctionHub-Setup.exe)

**Fix for "Setup can only update its own installed app folder":** The old updater accepts only `%LOCALAPPDATA%\Cricket26AuctionHub\App`, while the V5 offline installer installs to `%LOCALAPPDATA%\Programs\Cricket26AuctionHub`. V5.0.3 updates `AuctionUpdateHelper.exe` so **both exact supported locations** are accepted without permitting arbitrary or linked folders. The fix keeps the same existing Updates / Update & Restart UI and all V5.0.2 smooth-page improvements. Windows build, full ZIP hashes, delta reconstruction and folder-security checks passed.

**One-time small-package repair without reinstalling 440 MB:** The verified script at [tools/RepairInstalledUpdater.ps1](tools/RepairInstalledUpdater.ps1) detects the actual installed executable using Inno Setup's uninstall registration, Windows shortcuts, active processes and both official default paths. It deliberately refuses unrelated/custom paths, linked directories and unknown application identities. For the two supported official locations it downloads the SHA-256-pinned 247 KB v5.0.3 update ZIP, backs up the existing helper *outside the app folder*, and replaces only \`AuctionUpdateHelper.exe\`. To use it, completely close the Auction Hub and updater/error dialog, and run the script in Windows PowerShell. It lists multiple installations for explicit selection. **If it identifies a custom location, do not force files into that folder:** run the official V5.0.3 Inno Setup installer with the standard default path, or diagnose the registered location. The script passed a GitHub Actions Windows runner test for detection, secure download, backup and helper replacement; it has not been tested on any user's actual installed copy.

**No-CMD updater fix for old Inno Setup users:** Download [Cricket26AuctionHub-UpdateRepair.exe (2.2 MB)](https://github.com/vanshgamerzyt2711/cricket26-auction-hub/releases/download/v5.0.3/Cricket26AuctionHub-UpdateRepair.exe), close Auction Hub and its error window, then **double-click the EXE** and finish the standard Inno Setup repair wizard. This is a self-contained installer carrying only the repaired V5.0.3 updater helper. It automatically chooses the default install directory or the previously registered location for the same Inno AppId; verifies the application files exist; refuses unrelated and linked directories; replaces only \`AuctionUpdateHelper.exe\`. **UserData is not touched.** After that, reopen the existing app and click **Updates → Update & Restart**. The one-click repair EXE and these behaviors were validated on a clean Windows GitHub Actions runner, including a negative unregistered-folder test. Real user-machine testing remains recommended. Existing already-installed old helpers cannot auto-download this fix before their own path validation, so one separate click is necessary for affected users. Do not disable Windows Defender or run an unverified copy of the installer.

**Important one-time recovery:** For a V5 user currently seeing this error when updating from the `Programs` install location, the *old local helper* cannot install its own fix. **Close the app and the 3D auction, back up `%LOCALAPPDATA%\Cricket26AuctionHub\UserData`, then run V5.0.3 offline Setup once.** Its default install path matches the modern `Programs` location, and future releases can use the already-existing Update & Restart button. For users installed in the legacy `App` directory, the existing in-app updater should be able to update directly. For custom or moved folders, determine the installed path before installing; new Setup may create a separate app location. Real user PC testing still required. Keep antivirus enabled.

---


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
