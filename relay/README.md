# HealthyVibe Relay

HealthyVibe Relay is the optional lightweight backend for the "team" feature of HealthyVibe / Vibe延寿指南.

The production app can work without Relay. Relay only exists to synchronize a small, anonymous, same-day leaderboard for users who join the same team code.

## Current Scope

- Store anonymous team snapshots for the current day and a short retention window.
- Return a sorted daily ranking for one team.
- Keep the API stateless and account-free.
- Never receive prompts, code, diffs, file paths, hook payloads, command contents, email, phone numbers, or account identities.

## Production

Current production endpoint:

```text
https://healthyvibe.owlib.ai
```

Health check:

```text
https://healthyvibe.owlib.ai/healthz
```

The current production service is implemented as Node.js + SQLite behind nginx, with the same API contract documented in `API.md`. This folder remains the protocol reference and Cloudflare Workers + D1 reference implementation.

## Included Reference Implementation

This folder contains a Cloudflare Workers + D1 reference implementation:

- `src/index.ts`: HTTP routes.
- `src/validation.ts`: payload validation.
- `src/ranking.ts`: ranking rules.
- `src/types.ts`: API and database types.
- `migrations/0001_team_snapshots.sql`: D1 schema.
- `test/validation.test.ts`: validation and ranking tests.
- `wrangler.toml`: Cloudflare deployment config template.

## Read Next

- `HANDOFF.md`: product background, privacy boundaries, implementation requirements, and acceptance checklist.
- `API.md`: exact HTTP API contract.
- `DEPLOYMENT.md`: local development and deployment guide.

## Quick Check

```bash
npm install
npm run typecheck
npm test
```
