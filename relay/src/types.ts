export interface Env {
  DB: D1Database;
}

export interface TeamSnapshotRequest {
  teamCodeHash: string;
  memberIdHash: string;
  displayName?: string;
  date: string;
  longevityMinutes: number;
  completedTaskCount: number;
  updatedAt?: string;
}

export interface TeamSnapshotRow {
  team_code_hash: string;
  member_id_hash: string;
  display_name: string | null;
  date: string;
  longevity_minutes: number;
  completed_task_count: number;
  updated_at: string;
}

export interface RankingMember {
  rank: number;
  memberIdHash: string;
  displayName: string | null;
  longevityMinutes: number;
  completedTaskCount: number;
  updatedAt: string;
}

export interface RankingResponse {
  teamCodeHash: string;
  date: string;
  generatedAt: string;
  members: RankingMember[];
}
