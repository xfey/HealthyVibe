CREATE TABLE IF NOT EXISTS team_snapshots (
  team_code_hash TEXT NOT NULL,
  member_id_hash TEXT NOT NULL,
  display_name TEXT,
  date TEXT NOT NULL,
  longevity_minutes INTEGER NOT NULL,
  completed_task_count INTEGER NOT NULL,
  updated_at TEXT NOT NULL,
  PRIMARY KEY (team_code_hash, member_id_hash, date)
);

CREATE INDEX IF NOT EXISTS idx_team_snapshots_team_date
  ON team_snapshots (team_code_hash, date);

CREATE INDEX IF NOT EXISTS idx_team_snapshots_updated_at
  ON team_snapshots (updated_at);
