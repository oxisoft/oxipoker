# Roadmap

Version 1 is built in six milestones. Each one ends with something running on our test server.

1. **M0 Foundations:** repository, CI, Docker image with the web app built in, Compose file with the minimal and full options, release workflow to Docker Hub.
2. **M1 Accounts and admin:** first admin from the deployment settings, passwords, passkeys, optional two-factor codes, invitation links, admin console, avatars.
3. **M2 Cash tables:** game engine with a full test suite, tables and lobby, classic table design, spectators, text chat, hand history, stats. First real games.
4. **M3 Sit-and-go and finish:** sit-and-go with a blind clock, cyberpunk theme, custom card backs, report and block, resume after a server restart, about ten languages.
5. **M4 Voice and video:** LiveKit integration, camera and microphone controls, host moderation, relay for players behind strict routers.
6. **M5 Apps and 1.0:** Windows, macOS and Linux builds, Android via F-Droid, install guide, security review, version 1.0.

Later: multi-table tournaments, Pot-Limit Omaha.

## Design rules

- The server is the only authority on the game. Each client receives only what its seat may see; other players' hole cards never leave the server before they are shown.
- One container runs the whole game. Voice and video are optional and come as a second container (LiveKit).
- No real money, no open registration, no tracking, no outbound calls from the server.
