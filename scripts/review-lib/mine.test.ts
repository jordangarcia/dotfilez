import { describe, expect, test } from "bun:test";
import { mineTable, normalizeMine, requestedBy } from "./mine";

const person = (login: string) => ({ login, __typename: "User" });
const bot = (login: string) => ({ login, __typename: "Bot" });

const node = {
  number: 7, title: "Ship it", url: "https://github.com/gamma-app/gamma/pull/7", state: "MERGED" as const, isDraft: false,
  createdAt: "2026-09-20T00:00:00Z", mergedAt: "2026-09-21T00:00:00Z", closedAt: "2026-09-21T00:00:00Z", reviewDecision: "APPROVED",
  body: "", author: person("me"),
  repository: { nameWithOwner: "gamma-app/Gamma" },
  latestReviews: { nodes: [
    { state: "APPROVED", author: person("alice") },
    { state: "CHANGES_REQUESTED", author: person("bob") },
    { state: "APPROVED", author: bot("graphite-app") },
    { state: "COMMENTED", author: person("me") },
  ] },
  reviews: { nodes: [
    // bare approval: a verdict, not a comment
    { state: "APPROVED", createdAt: "2026-09-20T05:00:00Z", author: person("alice"), comments: { totalCount: 0 } },
    { state: "CHANGES_REQUESTED", createdAt: "2026-09-20T03:00:00Z", author: person("bob"), comments: { totalCount: 3 } },
    { state: "COMMENTED", createdAt: "2026-09-20T02:00:00Z", author: bot("cursor"), comments: { totalCount: 5 } },
  ] },
  comments: { nodes: [
    { createdAt: "2026-09-20T06:00:00Z", author: person("carol") },
    { createdAt: "2026-09-20T01:00:00Z", author: person("bob") },
    { createdAt: "2026-09-20T07:00:00Z", author: person("me") },
    { createdAt: "2026-09-20T08:00:00Z", author: person("linear[bot]") },
  ] },
};

describe("rvme", () => {
  test("splits reviewers by verdict and drops bots and the viewer", () => {
    const pull = normalizeMine(node, "me");

    expect(pull.repo).toBe("gamma-app/gamma");
    expect(pull.status).toBe("merged");
    expect(pull.approvers).toEqual(["alice"]);
    expect(pull.changesRequested).toEqual(["bob"]);
  });

  test("lists commenters most recent first, excluding bare approvals", () => {
    const pull = normalizeMine(node, "me");

    expect(pull.commenters).toEqual(["carol", "bob"]);
  });

  test("falls back to commenters when nobody has a verdict", () => {
    const pull = { ...normalizeMine(node, "me"), approvers: [], changesRequested: [] };

    expect(mineTable([pull], false)).toContain("💬 carol, 💬 bob");
  });

  test("fits a half-width terminal without wrapping", () => {
    const columns = process.stdout.columns;
    process.stdout.columns = 90;
    const output = mineTable([normalizeMine({ ...node, title: "a very long title ".repeat(8) }, "me")], false);
    process.stdout.columns = columns;

    const rows = output.split("\n").slice(0, 3);
    rows.forEach((row) => expect(Bun.stringWidth(row)).toBeLessThanOrEqual(90));
  });

  test("derives draft and closed status", () => {
    expect(normalizeMine({ ...node, state: "OPEN", isDraft: true }, "me").status).toBe("draft");
    expect(normalizeMine({ ...node, state: "OPEN" }, "me").status).toBe("open");
    expect(normalizeMine({ ...node, state: "CLOSED" }, "me").status).toBe("closed");
  });

  test("renders merge status, reviews, and commenters", () => {
    const output = mineTable([normalizeMine(node, "me")], false);

    expect(output).toContain("#7 — Ship it");
    expect(output).toContain("🟣 Merged");
    expect(output).toContain("❌ bob, ✅ alice");
    expect(output).toContain("1 PRs (1 merged)");
  });

  test("matches the Devin requester line exactly", () => {
    const body = "Link to Devin session: https://example\nRequested by: @jordangarcia\n";

    expect(requestedBy(body, "jordangarcia")).toBe(true);
    expect(requestedBy(body, "jordan")).toBe(false);
    expect(requestedBy("Requested by: @jordangarcia2", "jordangarcia")).toBe(false);
  });

  test("marks Devin PRs", () => {
    const pull = normalizeMine({ ...node, author: bot("devin-ai-integration[bot]") }, "me");

    expect(pull.viaDevin).toBe(true);
    expect(mineTable([pull], false)).toContain("🤖 #7 — Ship it");
  });
});
