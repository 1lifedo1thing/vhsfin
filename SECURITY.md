# Security

VHSFin signs in to your Jellyfin server and keeps a session token in local app storage (browser storage on web). Problems that could expose that token, a Jellyfin account, or a server are security issues.

## Reporting a vulnerability

Please report privately through GitHub: open the repository's **Security** tab and choose **Report a vulnerability**. Don't open a public issue for security problems.

Include the platform, app version or commit, and steps to reproduce. Remove real server addresses, usernames, passwords, and tokens from anything you send.

You'll get an acknowledgement when the report is read. Fixes land on the main branch; there are no separately supported release branches yet.

## Out of scope

- Your Jellyfin server's own security, permissions, and HTTPS setup. Report those to the [Jellyfin project](https://jellyfin.org).
- The sample `tool/serve_web.py` helper exposed beyond a trusted home network. It is documented as a local convenience, not a production web server.
