import type { TeamSnapshotRequest } from "./types";

const hashPattern = /^[A-Za-z0-9_-]{16,128}$/;
const datePattern = /^\d{4}-\d{2}-\d{2}$/;

export function validateSnapshot(value: unknown): TeamSnapshotRequest {
  if (!isRecord(value)) {
    throw new Error("Expected JSON object.");
  }

  const teamCodeHash = requireString(value.teamCodeHash, "teamCodeHash");
  const memberIdHash = requireString(value.memberIdHash, "memberIdHash");
  const date = requireString(value.date, "date");
  const longevityMinutes = requireInteger(value.longevityMinutes, "longevityMinutes");
  const completedTaskCount = requireInteger(value.completedTaskCount, "completedTaskCount");

  if (!hashPattern.test(teamCodeHash)) {
    throw new Error("Invalid teamCodeHash.");
  }
  if (!hashPattern.test(memberIdHash)) {
    throw new Error("Invalid memberIdHash.");
  }
  if (!datePattern.test(date)) {
    throw new Error("Invalid date.");
  }
  if (longevityMinutes < 0 || longevityMinutes > 1440) {
    throw new Error("Invalid longevityMinutes.");
  }
  if (completedTaskCount < 0 || completedTaskCount > 1000) {
    throw new Error("Invalid completedTaskCount.");
  }

  const displayName = typeof value.displayName === "string"
    ? value.displayName.trim().slice(0, 40)
    : undefined;
  const updatedAt = typeof value.updatedAt === "string" && value.updatedAt.length > 0
    ? value.updatedAt
    : undefined;

  return {
    teamCodeHash,
    memberIdHash,
    displayName,
    date,
    longevityMinutes,
    completedTaskCount,
    updatedAt
  };
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

function requireString(value: unknown, field: string): string {
  if (typeof value !== "string" || value.trim().length === 0) {
    throw new Error(`Missing ${field}.`);
  }

  return value.trim();
}

function requireInteger(value: unknown, field: string): number {
  if (typeof value !== "number" || !Number.isInteger(value)) {
    throw new Error(`Invalid ${field}.`);
  }

  return value;
}
