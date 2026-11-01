[Download small Setup.exe](https://github.com/vanshgamerzyt2711/cricket26-auction-hub/releases/latest/download/Cricket26AuctionHub-Setup.exe) | [Latest release](https://github.com/vanshgamerzyt2711/cricket26-auction-hub/releases/latest)

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
