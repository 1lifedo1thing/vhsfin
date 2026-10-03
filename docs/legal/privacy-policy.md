# Privacy Policy

**Effective:** October 3, 2026

VHSFin is a free app from MarkDid, LLC ("we") that plays movies and shows from your own Jellyfin server. This policy explains what the app does with your information. The short version: **we don't collect any of it.** VHSFin has no accounts, no ads, no analytics, and no servers of ours that it talks to.

## What VHSFin handles

| Information | Where it goes | Why |
| --- | --- | --- |
| Your Jellyfin server address, username, and password | Your Jellyfin server only | To sign you in. The password is not stored on your device. |
| Jellyfin session token and a random device ID | Stored on your device; sent to your Jellyfin server | To keep you signed in and identify this device to your server |
| Your shelves, settings, playback positions, and cached cover art | Stored on your device only | So the app remembers your choices |
| Movie and show titles and years | Internet Archive (archive.org) | To look up VHS sleeve art for the titles on your shelves |

When you play a tape, the video streams straight from your Jellyfin server to your device. When VHSFin saves a sleeve it found as box art, your Jellyfin server downloads that image itself.

## Third parties

- **Your Jellyfin server** is run by you or whoever gave you your account. Its own settings and policies decide what it records, such as sign-ins and what you watch. VHSFin is not affiliated with the Jellyfin project.
- **Internet Archive** receives title searches and image requests, along with your device's IP address, as any website does. See the [Internet Archive privacy policy](https://archive.org/about/terms.php).
- **Apple and Google** deliver the app through their stores under their own privacy policies. We receive only the aggregate download and crash statistics the stores provide to every developer.

Versions of VHSFin you build from source can turn on an optional lookup on [VHSCollector](https://vhscollector.com), which receives title searches in the same way. It is not part of the store apps.

We don't sell, share, or receive your information, and nothing in the app tracks you across other apps or websites.

## Keeping and deleting your information

Everything VHSFin stores stays on your device until you sign out, clear the app's data, or delete the app. Signing out removes your session from the device. To end the session on the server too, revoke it in your Jellyfin dashboard. Because we never receive your information, there is nothing for us to delete.

If you email us, we keep the message only as long as needed to help you. Ask us to delete it at any time.

## Security

Use an HTTPS address for your Jellyfin server where you can. If you connect over plain HTTP, your password and video travel unencrypted on that network. VHSFin stores your session token in the app's ordinary local storage, not an encrypted vault, so sign out on shared devices.

## Children

VHSFin is family-friendly, but it is set up by adults and is not directed at children under 13. What a child can watch is controlled by the Jellyfin account you give them, not by VHSFin. We don't knowingly collect information from anyone, including children.

## Changes and contact

If this policy changes, we'll update this page and its effective date before the app behaves differently. VHSFin is open source, so you can also check what it does in its [source code](https://github.com/markdid/vhsfin).

Questions? Email [support+vhsfin@markdid.dev](mailto:support+vhsfin@markdid.dev). See also our [Terms of Service](/terms/).
