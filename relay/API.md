# HealthyVibe Relay API

Base URL for production is expected to be one of:

- `https://healthyvibe.owlib.ai`
- or a temporary Workers URL such as `https://healthyvibe-relay.<account>.workers.dev`

The path contract should remain the same regardless of hosting provider.

## POST `/v1/team/snapshot`

Upserts one member's current daily result for one team.

### Request

Headers:

```http
content-type: application/json
```

Body:

```json
{
  "teamCodeHash": "64-char-sha256-hex",
  "memberIdHash": "64-char-sha256-hex",
  "displayName": "optional name",
  "date": "2026-05-20",
  "longevityMinutes": 18,
  "completedTaskCount": 6,
  "updatedAt": "2026-05-20T07:00:00Z"
}
```

### Field Rules

- `teamCodeHash`: required string, 16-128 chars in the reference implementation. The native client currently sends SHA-256 hex, 64 chars.
- `memberIdHash`: required string, 16-128 chars in the reference implementation. The native client currently sends SHA-256 hex, 64 chars.
- `displayName`: optional string. Trim and cap to 40 chars.
- `date`: required `YYYY-MM-DD`.
- `longevityMinutes`: integer, 0-1440.
- `completedTaskCount`: integer, 0-1000.
- `updatedAt`: optional ISO-8601 string. If missing, server may use current time.

### Success Response

```json
{
  "ok": true
}
```

Status: `200`.

### Error Response

```json
{
  "error": "Invalid longevityMinutes."
}
```

Status: `400` for invalid input.

## GET `/v1/team/ranking`

Returns the daily ranking for one team.

### Query

```text
team=<teamCodeHash>
date=<YYYY-MM-DD>
```

Example:

```text
GET /v1/team/ranking?team=3f...&date=2026-05-20
```

### Success Response

```json
{
  "teamCodeHash": "64-char-sha256-hex",
  "date": "2026-05-20",
  "generatedAt": "2026-05-20T07:01:00.000Z",
  "members": [
    {
      "rank": 1,
      "memberIdHash": "64-char-sha256-hex",
      "displayName": null,
      "longevityMinutes": 24,
      "completedTaskCount": 8,
      "updatedAt": "2026-05-20T07:00:00Z"
    }
  ]
}
```

Status: `200`.

If there are no rows, return an empty `members` array.

### Error Response

```json
{
  "error": "Missing team or date."
}
```

Status: `400` for missing query parameters.

## CORS

The native macOS app does not require CORS. The reference implementation still returns:

```http
access-control-allow-origin: *
access-control-allow-methods: GET,POST,OPTIONS
access-control-allow-headers: content-type
```

This is acceptable for MVP because no credentials or private account data are involved.

## Curl Examples

```bash
curl -sS https://healthyvibe.owlib.ai/v1/team/snapshot \
  -H 'content-type: application/json' \
  -d '{
    "teamCodeHash":"0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef",
    "memberIdHash":"abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789",
    "date":"2026-05-20",
    "longevityMinutes":18,
    "completedTaskCount":6,
    "updatedAt":"2026-05-20T07:00:00Z"
  }'
```

```bash
curl -sS 'https://healthyvibe.owlib.ai/v1/team/ranking?team=0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef&date=2026-05-20'
```
