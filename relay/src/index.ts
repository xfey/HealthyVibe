import { rankRows } from "./ranking";
import type { Env, RankingResponse, TeamSnapshotRow } from "./types";
import { validateSnapshot } from "./validation";

const retentionDays = 3;

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const url = new URL(request.url);

    if (request.method === "OPTIONS") {
      return withCors(new Response(null, { status: 204 }));
    }

    try {
      if (request.method === "POST" && url.pathname === "/v1/team/snapshot") {
        return withCors(await handleSnapshot(request, env));
      }

      if (request.method === "GET" && url.pathname === "/v1/team/ranking") {
        return withCors(await handleRanking(url, env));
      }

      return withCors(json({ error: "Not found." }, 404));
    } catch (error) {
      return withCors(json({ error: error instanceof Error ? error.message : "Unknown error." }, 400));
    }
  }
};

async function handleSnapshot(request: Request, env: Env): Promise<Response> {
  const snapshot = validateSnapshot(await request.json());
  const updatedAt = snapshot.updatedAt ?? new Date().toISOString();

  await cleanupOldSnapshots(env, new Date(updatedAt));
  await env.DB.prepare(`
    INSERT INTO team_snapshots (
      team_code_hash,
      member_id_hash,
      display_name,
      date,
      longevity_minutes,
      completed_task_count,
      updated_at
    )
    VALUES (?, ?, ?, ?, ?, ?, ?)
    ON CONFLICT(team_code_hash, member_id_hash, date) DO UPDATE SET
      display_name = excluded.display_name,
      longevity_minutes = excluded.longevity_minutes,
      completed_task_count = excluded.completed_task_count,
      updated_at = excluded.updated_at
  `)
    .bind(
      snapshot.teamCodeHash,
      snapshot.memberIdHash,
      snapshot.displayName ?? null,
      snapshot.date,
      snapshot.longevityMinutes,
      snapshot.completedTaskCount,
      updatedAt
    )
    .run();

  return json({ ok: true });
}

async function handleRanking(url: URL, env: Env): Promise<Response> {
  const teamCodeHash = url.searchParams.get("team");
  const date = url.searchParams.get("date");

  if (!teamCodeHash || !date) {
    return json({ error: "Missing team or date." }, 400);
  }

  const result = await env.DB.prepare(`
    SELECT
      team_code_hash,
      member_id_hash,
      display_name,
      date,
      longevity_minutes,
      completed_task_count,
      updated_at
    FROM team_snapshots
    WHERE team_code_hash = ? AND date = ?
  `)
    .bind(teamCodeHash, date)
    .all<TeamSnapshotRow>();

  const response: RankingResponse = {
    teamCodeHash,
    date,
    generatedAt: new Date().toISOString(),
    members: rankRows(result.results ?? [])
  };

  return json(response);
}

async function cleanupOldSnapshots(env: Env, now: Date): Promise<void> {
  const cutoff = new Date(now.getTime() - retentionDays * 24 * 60 * 60 * 1000)
    .toISOString()
    .slice(0, 10);

  await env.DB.prepare("DELETE FROM team_snapshots WHERE date < ?")
    .bind(cutoff)
    .run();
}

function json(value: unknown, status = 200): Response {
  return new Response(JSON.stringify(value), {
    status,
    headers: {
      "content-type": "application/json; charset=utf-8"
    }
  });
}

function withCors(response: Response): Response {
  const headers = new Headers(response.headers);
  headers.set("access-control-allow-origin", "*");
  headers.set("access-control-allow-methods", "GET,POST,OPTIONS");
  headers.set("access-control-allow-headers", "content-type");
  return new Response(response.body, {
    status: response.status,
    statusText: response.statusText,
    headers
  });
}
