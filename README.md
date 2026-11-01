[Download Setup.exe](https://github.com/vanshgamerzyt2711/cricket26-auction-hub/releases/latest/download/Cricket26AuctionHub-Setup.exe) | [Latest release](https://github.com/vanshgamerzyt2711/cricket26-auction-hub/releases/latest)

# Cricket 26 Auction Hub — V1.0.1

For legally purchased copies of Cricket 26 only. We do not support piracy. Cricket 26 is not included.

Download Cricket26AuctionHub-Setup.exe for a fresh installation. Existing users: Settings & Tools → Updates → Update & Restart. If V1 is stuck at Scan Your Game and cannot reach Settings, run the new Setup.exe once; it preserves your saved auctions and backups.

- Fixed genuine Steam version-5 Academy saves: preserve the existing save header, update the payload checksum, and verify the decoded squads before applying.
- Fixed Xbox/Microsoft Store save discovery: discover the actual Academy container instead of using one developer-specific folder ID.
- Separate original-squad checkpoints for different installations and save profiles.
- Failed scans restore the previous game configuration.
- Added Check Updates on the game scan screen.

Validation: actual locally installed Steam and Xbox databases/saves scanned successfully (254 and 250 IPL players respectively); two genuine Steam saves passed checksum and encode/decode tests; an isolated copy of a real Steam save passed exact squad import and restore using the actual Steam database. Random Xbox container/account tests passed. No live game saves, profile metadata, careers, or original archive were replaced during automated tests. In-game squad verification and public download/install test remain pending; do not treat file checks as gameplay verification.

Independent community tool, not an official Cricket 26/IPL product. 3D auction assets credited to Game Changer 5. Node notices included. Unsigned beta.
