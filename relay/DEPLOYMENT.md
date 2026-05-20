# HealthyVibe Relay Deployment

## Current Production

Production endpoint:

```text
https://healthyvibe.owlib.ai
```

Current production runtime:

- Backend service: Node.js + SQLite.
- systemd service: `healthyvibe-relay`.
- Local listener: `127.0.0.1:8787`.
- Public access: nginx reverse proxy.
- HTTPS: Let's Encrypt / Certbot with automatic renewal.
- Database: `/var/lib/healthyvibe-relay/relay.sqlite`.

The API contract remains the same as `API.md`.

The included implementation targets Cloudflare Workers + D1. A server team may also reimplement the same API on a normal server with SQLite/PostgreSQL/MySQL.

## Option A: Cloudflare Workers + D1

### Prerequisites

- Cloudflare account.
- Node.js 20+.
- `npm install` completed in this folder.
- A domain or Workers subdomain.

### Local Validation

```bash
npm install
npm run typecheck
npm test
```

### Create D1 Database

```bash
npx wrangler login
npx wrangler d1 create healthyvibe-relay
```

Wrangler prints a database id and binding snippet. Put the database id into `wrangler.toml`:

```toml
[[d1_databases]]
binding = "DB"
database_name = "healthyvibe-relay"
database_id = "<real-d1-database-id>"
migrations_dir = "migrations"
```

### Apply Migration

```bash
npx wrangler d1 migrations apply healthyvibe-relay --remote
```

### Deploy Worker

```bash
npm run deploy
```

For a custom domain, use one of:

```bash
npx wrangler deploy --domain healthyvibe.owlib.ai
```

or configure the custom domain/route in the Cloudflare dashboard.

### Smoke Test

```bash
BASE_URL="https://healthyvibe.owlib.ai"

curl -sS "$BASE_URL/v1/team/snapshot" \
  -H 'content-type: application/json' \
  -d '{
    "teamCodeHash":"0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef",
    "memberIdHash":"abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789",
    "date":"2026-05-20",
    "longevityMinutes":18,
    "completedTaskCount":6,
    "updatedAt":"2026-05-20T07:00:00Z"
  }'

curl -sS "$BASE_URL/v1/team/ranking?team=0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef&date=2026-05-20"
```

Expected:

- First command returns `{"ok":true}`.
- Second command returns a `members` array with one row.

## Option B: Self-Hosted Server

Any stack is acceptable if it keeps the same API. A minimal implementation needs:

- HTTPS.
- JSON body parser.
- Persistent database table equivalent to `team_snapshots`.
- Upsert by `(team_code_hash, member_id_hash, date)`.
- Ranking sort:
  - `longevity_minutes DESC`
  - `completed_task_count DESC`
  - `updated_at ASC`
- Old row cleanup for date older than 3 days.

Equivalent SQL schema:

```sql
CREATE TABLE team_snapshots (
  team_code_hash TEXT NOT NULL,
  member_id_hash TEXT NOT NULL,
  display_name TEXT,
  date TEXT NOT NULL,
  longevity_minutes INTEGER NOT NULL,
  completed_task_count INTEGER NOT NULL,
  updated_at TEXT NOT NULL,
  PRIMARY KEY (team_code_hash, member_id_hash, date)
);

CREATE INDEX idx_team_snapshots_team_date
  ON team_snapshots (team_code_hash, date);
```

## Client Integration Note

The macOS client currently has a default relay URL in:

```text
Sources/HealthyVibeTeam/TeamRelayClient.swift
```

Before enabling the team UI in production, set the default base URL to the final deployed endpoint, probably:

```text
https://healthyvibe.owlib.ai
```

No client secret is needed.

## Rollback

Relay is optional. If the endpoint is unavailable, the app should still:

- keep local task completion working;
- keep local history working;
- show a lightweight "Relay unavailable" state for team sync;
- avoid blocking health-task completion.
