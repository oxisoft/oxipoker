# Security policy

## Reporting a vulnerability

Please report security issues privately to **security@oxisoft.io**, or through GitHub's "Report a vulnerability" button on the Security tab of this repository. Do not open a public issue.

Include what you found, how to reproduce it, and the version (`/api/v1/health` shows it). We confirm receipt within 3 working days and keep you posted until a fix is released. We credit reporters in the release notes unless you prefer otherwise.

## Supported versions

Only the latest release receives security fixes. Self-hosted servers should follow the `latest` image or the newest `X.Y` tag.

## Scope

In scope: the server, the web app it serves, the native apps, the Docker image and the Compose setup in this repository. Out of scope: LiveKit itself (report to the LiveKit project), and a host's own reverse proxy or server configuration.
