# HealthyVibe Relay Handoff

## Background

HealthyVibe is a macOS menu bar app for programmers using Claude Code, Codex, and similar AI coding agents. When a user submits a prompt, the local app receives a minimal hook event and reminds the user to do a short health task while the agent works.

The app is local-first:

- Personal task history is stored in local SQLite.
- Agent hook payloads are discarded locally and are not uploaded.
- The user can use the app without any account or server.

Relay is only needed for the optional team feature. A team is identified by a six-digit team code in the UI. The client hashes the team code and a local anonymous member id before uploading.

## Goal

Provide a minimal service that lets members of the same team compare today's "longevity minutes" in a simple leaderboard.

Relay should not become a user/account system. It should stay closer to a shared, anonymous scoreboard.

## Non-Goals

- No user accounts.
- No login.
- No email or phone number.
- No long-term personal analytics.
- No prompt/code/diff/file-path collection.
- No admin dashboard for MVP.
- No moderation workflow for MVP.

## Privacy Boundary

Relay may receive:

- `teamCodeHash`: SHA-256 hex string generated from the six-digit team code.
- `memberIdHash`: SHA-256 hex string generated from a local UUID.
- `displayName`: optional short display name. Current MVP can omit it.
- `date`: local app date key, `YYYY-MM-DD`.
- `longevityMinutes`: today's completed task reward total.
- `completedTaskCount`: today's completed task count.
- `updatedAt`: client timestamp, ISO-8601.

Relay must not receive or store:

- Prompt content.
- Agent hook raw payload.
- Code content.
- Diff content.
- File paths.
- Shell commands.
- User account identifiers.
- Email, phone, OAuth ids, Apple ids, GitHub ids.
- Personal long-term history.

## Data Retention

MVP retention should be short:

- Keep current day data.
- Keep the last 48-72 hours for clock skew and time zone tolerance.
- Delete snapshots older than the retention window on write or via scheduled cleanup.

The included reference implementation deletes rows older than three days whenever a snapshot is posted.

## Ranking Rules

For a team and date:

1. Higher `longevityMinutes` ranks first.
2. If tied, higher `completedTaskCount` ranks first.
3. If still tied, earlier `updatedAt` ranks first.

Ranks are 1-based.

## Expected Client Flow

1. User creates or joins a team in the app.
2. App saves the six-digit team code locally.
3. App creates a local anonymous member id and stores it locally.
4. App computes:
   - `teamCodeHash = SHA256(teamCode)`
   - `memberIdHash = SHA256(memberID)`
5. After completing a health task, app posts today's latest snapshot.
6. App fetches today's ranking and caches it locally.
7. UI shows only simple rank information.

## Operational Requirements

Minimum:

- HTTPS endpoint.
- JSON API.
- SQLite-like durable storage is enough.
- Upsert snapshot by `(teamCodeHash, memberIdHash, date)`.
- Validate payload shape and value ranges.
- Return deterministic ranking.
- CORS may be permissive because the native app does not need browser CORS, but it helps simple web/manual testing.

Recommended:

- Request body size limit around 4 KB.
- Basic per-IP or per-team rate limiting if available.
- Structured logs without request bodies.
- No logging of raw JSON payload unless explicitly redacted.
- Health check can be added later, but is not required for MVP.

## Acceptance Checklist

- `POST /v1/team/snapshot` accepts a valid snapshot and returns `{"ok":true}`.
- Posting the same `(teamCodeHash, memberIdHash, date)` updates the row, not duplicates it.
- `GET /v1/team/ranking?team=...&date=...` returns all members for that team/date, sorted by the ranking rules.
- Invalid hash/date/minute/count payloads return 400.
- Unknown routes return 404.
- The database contains no prompt/code/diff/path/hook payload columns.
- Rows older than the retention window are removed.
- Server-side logs do not include sensitive client payloads.
