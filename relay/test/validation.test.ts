import { describe, expect, it } from "vitest";
import { rankRows } from "../src/ranking";
import { validateSnapshot } from "../src/validation";

describe("validateSnapshot", () => {
  it("accepts a minimal valid snapshot", () => {
    expect(validateSnapshot({
      teamCodeHash: "team_hash_123456",
      memberIdHash: "member_hash_1234",
      date: "2026-05-19",
      longevityMinutes: 18,
      completedTaskCount: 6
    })).toMatchObject({
      teamCodeHash: "team_hash_123456",
      memberIdHash: "member_hash_1234",
      longevityMinutes: 18
    });
  });

  it("rejects prompt-like or malformed payloads", () => {
    expect(() => validateSnapshot({ prompt: "secret" })).toThrow();
    expect(() => validateSnapshot({
      teamCodeHash: "short",
      memberIdHash: "member_hash_1234",
      date: "2026-05-19",
      longevityMinutes: 18,
      completedTaskCount: 6
    })).toThrow();
  });
});

describe("rankRows", () => {
  it("ranks by minutes, completed count, then earliest update", () => {
    const ranked = rankRows([
      row("a", 10, 2, "2026-05-19T10:03:00Z"),
      row("b", 12, 1, "2026-05-19T10:02:00Z"),
      row("c", 12, 3, "2026-05-19T10:01:00Z")
    ]);

    expect(ranked.map((member) => member.memberIdHash)).toEqual(["c", "b", "a"]);
    expect(ranked.map((member) => member.rank)).toEqual([1, 2, 3]);
  });
});

function row(member: string, minutes: number, count: number, updatedAt: string) {
  return {
    team_code_hash: "team_hash_123456",
    member_id_hash: member,
    display_name: member,
    date: "2026-05-19",
    longevity_minutes: minutes,
    completed_task_count: count,
    updated_at: updatedAt
  };
}
