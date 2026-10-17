import { existsSync } from "node:fs";
import { join } from "node:path";
import { pathToFileURL } from "node:url";
import { allPulls, daysAgo, DEFAULT_DAYS } from "./github";
import { indicators, others } from "./actions";
import { loadReview } from "./runner";
import { directory } from "./store";
import { relativeAge, renderTable, type Cell } from "./table";

export { relativeAge };

export async function dashboard(root: string, links = Boolean(process.stdout.isTTY), days = DEFAULT_DAYS): Promise<string> {
  const { cache, pulls: savedPulls } = await allPulls(root, days);
  const cutoff = daysAgo(days);
  const pulls = savedPulls
    .filter((pull) => pull.createdAt && pull.createdAt >= cutoff)
    .filter((pull) => pull.state === "OPEN")
    .sort((a, b) => Date.parse(b.createdAt!) - Date.parse(a.createdAt!));
  const records = await Promise.all(pulls.map(async (pull): Promise<Cell[]> => {
    const status = await indicators(root, pull, await loadReview(root, pull));
    const htmlPath = join(directory(root, pull), "diff.html");
    const viewer = cache?.viewer ?? "";
    const people = others(pull, viewer);
    const approvedByMe = pull.reviewers.some((person) => person.login === viewer && !person.bot && person.state === "APPROVED");
    const approvers = people.filter((person) => person.state === "APPROVED").map((person) => person.login);
    const approvals = [...(approvedByMe ? [`✅ ${viewer}`] : []), ...approvers].join(", ");
    const ready = existsSync(htmlPath);
    const stalled = status.activity.state === "stalled";
    const html = stalled ? (ready ? "📄 Open (stalled)" : "⚠️ Stalled") : ready ? "📄 Open" : status.html === "running" ? "⏳ Running" : status.html === "error" ? "⚠️ Failed" : "—";

    return [
      { text: relativeAge(pull.createdAt) },
      { text: `#${pull.number} — ${pull.title}`, url: pull.url },
      { text: pull.author },
      { text: html, url: ready ? pathToFileURL(htmlPath).href : undefined },
      { text: approvals || "—" },
    ];
  }));
  const columns = [
    { heading: "Created", limit: 10 },
    { heading: "PR", limit: 100 },
    { heading: "Author", limit: 22 },
    { heading: "HTML", limit: 18 },
    { heading: "Approvals", limit: 64 },
  ];
  const table = renderTable(columns, records, 1, links);

  return `${table}\n${pulls.length} PRs | created in the last ${days} days\n✅ you approved · 📄 HTML · ⏳ generating · ⚠️ needs attention\n`;
}
