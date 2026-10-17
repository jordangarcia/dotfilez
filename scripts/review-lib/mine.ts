import { command, daysAgo, DEFAULT_DAYS } from "./github";
import { relativeAge, renderTable, type Cell } from "./table";

type Actor = { login: string; __typename: string } | null;

type Node = {
  number: number; title: string; url: string; state: "OPEN" | "CLOSED" | "MERGED"; isDraft: boolean;
  createdAt: string; mergedAt: string | null; closedAt: string | null; reviewDecision: string | null;
  body: string; author: Actor;
  repository: { nameWithOwner: string };
  latestReviews: { nodes: { state: string; author: Actor }[] };
  reviews: { nodes: { state: string; createdAt: string; author: Actor; comments: { totalCount: number } }[] };
  comments: { nodes: { createdAt: string; author: Actor }[] };
};

export type MyPull = {
  repo: string; number: number; title: string; url: string;
  status: "merged" | "closed" | "draft" | "open";
  // Devin opens PRs as its bot and names the requester in the body.
  viaDevin: boolean;
  createdAt: string; mergedAt: string | null; closedAt: string | null;
  approvers: string[];
  changesRequested: string[];
  // Most recent first: issue comments, review summaries, and inline review comments.
  commenters: string[];
};

const DEVIN = "devin-ai-integration";

const FIELDS = `number title url state isDraft createdAt mergedAt closedAt reviewDecision body author { login }
  repository { nameWithOwner }
  latestReviews(first: 100) { nodes { state author { login __typename } } }
  reviews(last: 100) { nodes { state createdAt author { login __typename } comments { totalCount } } }
  comments(last: 100) { nodes { createdAt author { login __typename } } }`;

function isPerson(actor: Actor, viewer: string): actor is { login: string; __typename: string } {
  if (!actor) {
    return false;
  }
  const bot = actor.__typename === "Bot" || actor.login.endsWith("[bot]");

  return !bot && actor.login !== viewer;
}

function statusOf(node: Node): MyPull["status"] {
  if (node.state === "MERGED") {
    return "merged";
  }
  if (node.state === "CLOSED") {
    return "closed";
  }

  return node.isDraft ? "draft" : "open";
}

export function normalizeMine(node: Node, viewer: string): MyPull {
  const people = node.latestReviews.nodes.filter((review) => isPerson(review.author, viewer));
  const byState = (state: string) => people
    .filter((review) => review.state === state)
    .map((review) => review.author!.login);

  // An APPROVED or CHANGES_REQUESTED review with no body and no inline comments is only a verdict,
  // so it counts as an approval, not a comment.
  const reviewActivity = node.reviews.nodes
    .filter((review) => isPerson(review.author, viewer))
    .filter((review) => review.state === "COMMENTED" || review.comments.totalCount > 0)
    .map((review) => ({ login: review.author!.login, createdAt: review.createdAt }));
  const commentActivity = node.comments.nodes
    .filter((comment) => isPerson(comment.author, viewer))
    .map((comment) => ({ login: comment.author!.login, createdAt: comment.createdAt }));

  const commenters = [...reviewActivity, ...commentActivity]
    .sort((a, b) => b.createdAt.localeCompare(a.createdAt))
    .map((item) => item.login);

  return {
    repo: node.repository.nameWithOwner.toLowerCase(), number: node.number, title: node.title, url: node.url,
    status: statusOf(node), viaDevin: node.author?.login.startsWith(DEVIN) ?? false, createdAt: node.createdAt, mergedAt: node.mergedAt, closedAt: node.closedAt,
    approvers: byState("APPROVED"),
    changesRequested: byState("CHANGES_REQUESTED"),
    commenters: [...new Set(commenters)],
  };
}

export function requestedBy(body: string, viewer: string): boolean {
  const escaped = viewer.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");

  return new RegExp(`^Requested by: @${escaped}\\s*$`, "im").test(body);
}

async function searchPulls(search: string, signal?: AbortSignal): Promise<{ viewer: string; nodes: Node[] }> {
  const query = `query($search: String!, $cursor: String) {
    viewer { login }
    search(query: $search, type: ISSUE, first: 25, after: $cursor) {
      pageInfo { hasNextPage endCursor }
      nodes { ... on PullRequest { ${FIELDS} } }
    }
  }`;

  const nodes: Node[] = [];
  let viewer = "";
  let cursor: string | null = null;
  do {
    const args = ["gh", "api", "graphql", "-f", `query=${query}`, "-f", `search=${search}`];
    if (cursor) {
      args.push("-f", `cursor=${cursor}`);
    }
    const response = JSON.parse(await command(args, undefined, undefined, signal));
    if (response.errors || !response.data?.search) {
      throw new Error(`GitHub search failed (${search}): ${JSON.stringify(response.errors)}`);
    }

    viewer = response.data.viewer.login;
    nodes.push(...response.data.search.nodes.filter((node: Node) => node.number));

    const page = response.data.search.pageInfo;
    cursor = page.hasNextPage ? page.endCursor : null;
  } while (cursor);

  return { viewer, nodes };
}

// The Devin search needs the login up front. gh's local config answers in ~25ms;
// `gh api user` costs a ~1.7s round trip before either search can start.
async function viewerLogin(signal?: AbortSignal): Promise<string> {
  try {
    const login = await command(["gh", "config", "get", "-h", "github.com", "user"], undefined, undefined, signal);
    if (login) {
      return login;
    }
  } catch (error) {
    console.error(`rvme: gh config has no login, asking GitHub. ${error instanceof Error ? error.message : error}`);
  }

  return command(["gh", "api", "user", "--jq", ".login"], undefined, undefined, signal);
}

export async function fetchMine(days = DEFAULT_DAYS, signal?: AbortSignal): Promise<MyPull[]> {
  const cutoff = daysAgo(days);
  const viewer = await viewerLogin(signal);

  // `mentions:@me` misses bot-authored PRs, so match the requester line as text and verify it below.
  const [authored, devin] = await Promise.all([
    searchPulls(`is:pr author:@me updated:>=${cutoff} sort:created-desc`, signal),
    searchPulls(`is:pr author:app/${DEVIN} "Requested by: @${viewer}" updated:>=${cutoff} sort:created-desc`, signal)
      .catch((error) => {
        console.error(`rvme: skipping Devin PRs. ${error instanceof Error ? error.message : error}`);
        return { viewer, nodes: [] };
      }),
  ]);
  const requested = devin.nodes.filter((node) => requestedBy(node.body, viewer));

  return [...authored.nodes, ...requested].map((node) => normalizeMine(node, viewer));
}

function shortAge(value: string | null): string {
  return relativeAge(value).replace(/ ago$/, "");
}

function statusCell(pull: MyPull): string {
  switch (pull.status) {
    case "merged":
      return `🟣 Merged ${shortAge(pull.mergedAt)}`;
    case "closed":
      return `🔴 Closed ${shortAge(pull.closedAt)}`;
    case "draft":
      return "⚪ Draft";
    case "open":
      return "🟢 Open";
  }
}

function reviewCell(pull: MyPull): string {
  const approved = pull.approvers.map((login) => `✅ ${login}`);
  const blocked = pull.changesRequested.map((login) => `❌ ${login}`);

  const verdicts = [...blocked, ...approved];
  if (verdicts.length) {
    return verdicts.join(", ");
  }

  const commented = pull.commenters.map((login) => `💬 ${login}`);

  return commented.join(", ") || "—";
}

export function mineTable(pulls: MyPull[], links = Boolean(process.stdout.isTTY), days = DEFAULT_DAYS): string {
  const sorted = [...pulls].sort((a, b) => Date.parse(b.createdAt) - Date.parse(a.createdAt));
  const records: Cell[][] = sorted.map((pull) => [
    { text: relativeAge(pull.createdAt) },
    { text: `${pull.viaDevin ? "🤖 " : ""}#${pull.number} — ${pull.title}`, url: pull.url },
    { text: statusCell(pull) },
    { text: reviewCell(pull) },
  ]);
  const columns = [
    { heading: "Created", limit: 10 },
    { heading: "PR", limit: 100 },
    { heading: "Status", limit: 14 },
    { heading: "Reviews", limit: 40 },
  ];
  const table = renderTable(columns, records, 1, links);

  const merged = sorted.filter((pull) => pull.status === "merged").length;
  const summary = `${sorted.length} PRs (${merged} merged) | updated in the last ${days} days`;
  const legend = "🟣 merged 🟢 open ⚪ draft 🔴 closed · ✅ approved ❌ changes 💬 commented · 🤖 Devin";

  return `${table}\n${summary}\n${legend}\n`;
}
