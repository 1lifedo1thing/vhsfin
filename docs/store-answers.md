# Store answers

Answers for the App Store Connect and Play Console questionnaires, taken from what
the 1.0 release build actually does. Re-check them before any release that adds
an SDK, analytics, or a new network service.

## What the app sends, and to whom

| Destination | What | Ours? |
| --- | --- | --- |
| The user's Jellyfin server | Sign-in, library browsing, streams, optional box-art save | No, the user's own server |
| Internet Archive (archive.org) | Title/year searches, sleeve images | No, public API |
| VHSCollector | Only in builds with `VHSFIN_VHSCOLLECTOR=true`, which the store builds are not | No |

MarkDid runs no backend, analytics, crash reporting, ads, or purchases for VHSFin.

## Apple: App Privacy

- **Data collection:** Data Not Collected. Nothing reaches MarkDid or a partner of ours. Data sent to the user's own server, or title lookups sent to a public archive at the user's request, is not "collected" in Apple's sense.
- **Tracking:** No. No `NSUserTrackingUsageDescription`, no ATT prompt.
- **Privacy Policy URL:** https://vhsfin.markdid.dev/privacy/

## Apple: other fields

| Field | Answer |
| --- | --- |
| Category | Entertainment; secondary Photo & Video |
| Age rating | Answer "None" to every content question: the app ships no content. Media clients are rated anywhere from 4+ to 17+; compare Swiftfin's current rating before choosing. |
| Made for Kids | No. Family-friendly, but set up by adults; the Kids category forbids features VHSFin needs. |
| Export compliance | Only standard HTTPS through the OS: exempt. `ITSAppUsesNonExemptEncryption = NO` is in Info.plist, so TestFlight won't ask. |
| Content rights | Contains third-party content: Yes (the user's own media and public cover art), with rights: Yes. Mention it in the review notes. |
| Sign-in required | Yes. Review notes give Jellyfin's public demo server. |
| Copyright | 2026 MarkDid, LLC |
| License | Apple standard EULA |
| URLs | Privacy https://vhsfin.markdid.dev/privacy/, Support https://vhsfin.markdid.dev/support/, Marketing https://vhsfin.markdid.dev |

`NSAllowsArbitraryLoads` is on so users can reach HTTP servers on their own network. The reason is in `fastlane/metadata/ios/review_information/notes.txt`.

## Google Play: Data safety

- **Does your app collect or share any of the required user data types?** No.
- **Account creation:** My app does not allow users to create an account. (Users sign in to their own Jellyfin server; there's no account with us.)
- **Data deletion URL:** not required without collection; if asked, use https://vhsfin.markdid.dev/privacy/

## Google Play: App content

| Section | Answer |
| --- | --- |
| Privacy policy | https://vhsfin.markdid.dev/privacy/ |
| App access | All or some functionality is restricted. Instructions: server https://demo.jellyfin.org/stable, username demo, blank password. |
| Ads | No ads |
| Content rating (IARC) | Category "All other app types". No violence, sexuality, language, or gambling in the app itself; no user-to-user communication; no location sharing; no purchases. |
| Target audience | 13 and over. Don't select under-13 age groups (Designed for Families rules). |
| News app / COVID / government / financial / health | No |
| Advertising ID | No. The app has no AD_ID permission. |
| Category | Video Players & Editors |

## Review notes and demo access

Both stores: Jellyfin demo server https://demo.jellyfin.org/stable, user `demo`, empty password. Check it still works right before submitting:

```sh
curl -s https://demo.jellyfin.org/stable/System/Info/Public
```
