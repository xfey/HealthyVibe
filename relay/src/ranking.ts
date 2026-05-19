import type { RankingMember, TeamSnapshotRow } from "./types";

export function rankRows(rows: TeamSnapshotRow[]): RankingMember[] {
  return [...rows]
    .sort((left, right) => {
      if (right.longevity_minutes !== left.longevity_minutes) {
        return right.longevity_minutes - left.longevity_minutes;
      }
      if (right.completed_task_count !== left.completed_task_count) {
        return right.completed_task_count - left.completed_task_count;
      }
      return left.updated_at.localeCompare(right.updated_at);
    })
    .map((row, index) => ({
      rank: index + 1,
      memberIdHash: row.member_id_hash,
      displayName: row.display_name,
      longevityMinutes: row.longevity_minutes,
      completedTaskCount: row.completed_task_count,
      updatedAt: row.updated_at
    }));
}
