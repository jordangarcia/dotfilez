import { join } from "node:path";
import { key, parseTarget, readJson, savedReviews, writeJson, type Cache, type Pull } from "./store";

export async function command(args: string[], cwd?: string, env?: NodeJS.ProcessEnv, signal?: AbortSignal): Promise<string> {
  try {
    const child = Bun.spawn(args, { cwd, env, signal, stdin: "ignore", stdout: "pipe", stderr: "pipe" });
    const [stdout, stderr, code] = await Promise.all([
      new Response(child.stdout).text(), new Response(child.stderr).text(), child.exited,
    ]);
    if (code !== 0) {
      throw new Error(`${args[0]} exited ${code}: ${stderr.trim() || stdout.trim()}`);
    }

    return stdout.trim();
  } catch (error) {
    throw new Error(`Command failed (${args.slice(0, 3).join(" ")}): ${error}`);
  }
}

const FIELDS = `number title body url state updatedAt createdAt mergedAt headRefName baseRefName headRefOid reviewDecision
  author { login } repository { nameWithOwner }
  latestReviews(first: 100) { nodes { state author { login __typename } } }`;

type Node = {
  number: number; title: string; body: string; url: string; state: string; updatedAt: string; createdAt: string;
  mergedAt: string | null; headRefName: string; baseRefName: string; headRefOid: string; reviewDecision: string | null;
  author: { login: string } | null; repository: { nameWithOwner: string };
  latestReviews: { nodes: { state: string; author: { login: string; __typename: string } | null }[] };
};

function normalize(node: Node): Pull {
  return {
    repo: node.repository.nameWithOwner.toLowerCase(), number: node.number, title: node.title,
    body: node.body, author: node.author?.login ?? "deleted", url: node.url, state: node.state, updatedAt: node.updatedAt, createdAt: node.createdAt,
    mergedAt: node.mergedAt, head: node.headRefName, base: node.baseRefName, sha: node.headRefOid, decision: node.reviewDecision,
    reviewers: node.latestReviews.nodes.filter((review) => review.author && review.state !== "PENDING")
      .map((review) => ({ login: review.author!.login, state: review.state, bot: review.author!.__typename === "Bot" })),
  };
}

export async function fetchPull(target: { repo: string; number: number }, signal?: AbortSignal): Promise<Pull> {
  const [owner, name] = target.repo.split("/");
  const query = `query($owner: String!, $name: String!, $number: Int!) {
    repository(owner: $owner, name: $name) { pullRequest(number: $number) { ${FIELDS} } }
  }`;
  const output = await command(["gh", "api", "graphql", "-f", `query=${query}`, "-f", `owner=${owner}`, "-f", `name=${name}`, "-F", `number=${target.number}`], undefined, undefined, signal);
  const response = JSON.parse(output);
  if (!response.data?.repository?.pullRequest) {
    throw new Error(`GitHub did not return ${key(target)}`);
  }

  return normalize(response.data.repository.pullRequest);
}

export const DEFAULT_DAYS = 7;

export function daysAgo(days: number, now = Date.now()): string {
  return new Date(now - days * 24 * 60 * 60 * 1000).toISOString();
}

export function weekAgo(now = Date.now()): string {
  return daysAgo(DEFAULT_DAYS, now);
}

// Removes `--days N` from args. Shared by rv and rvme.
export function takeDays(args: string[]): number {
  const index = args.indexOf("--days");
  if (index < 0) {
    return DEFAULT_DAYS;
  }

  const [, value] = args.splice(index, 2);
  const days = Number(value);
  const valid = /^[1-9]\d*$/.test(value ?? "");
  if (!valid) {
    throw new Error(`--days needs a positive whole number (got ${value ?? "nothing"}).`);
  }

  return days;
}

async function searchPulls(search: string, signal?: AbortSignal): Promise<{ viewer: string; pulls: Pull[] }> {
  const query = `query($cursor: String) {
    viewer { login }
    search(query: "${search}", type: ISSUE, first: 50, after: $cursor) {
      pageInfo { hasNextPage endCursor }
      nodes { ... on PullRequest { ${FIELDS} } }
    }
  }`;
  const pulls: Pull[] = [];
  let cursor: string | null = null;
  let viewer = "";
  do {
    const args = ["gh", "api", "graphql", "-f", `query=${query}`];
    if (cursor) {
      args.push("-f", `cursor=${cursor}`);
    }
    const response = JSON.parse(await command(args, undefined, undefined, signal));
    if (response.errors || !response.data?.search) {
      throw new Error(`GitHub search failed: ${JSON.stringify(response.errors)}`);
    }
    viewer = response.data.viewer.login;
    pulls.push(...response.data.search.nodes.filter((node: Node) => node.number).map(normalize));
    const page = response.data.search.pageInfo;
    cursor = page.hasNextPage ? page.endCursor : null;
  } while (cursor);

  return { viewer, pulls };
}

export async function refresh(root: string, signal?: AbortSignal, days = DEFAULT_DAYS): Promise<Cache> {
  const cutoff = daysAgo(days);
  const [requestedResult, reviewedResult, previous, saved] = await Promise.all([
    searchPulls(`is:pr review-requested:@me created:>=${cutoff} sort:created-desc`, signal),
    searchPulls(`is:pr reviewed-by:@me created:>=${cutoff} sort:created-desc`, signal),
    readJson<Cache>(join(root, "pulls.json")),
    savedReviews(root),
  ]);
  const viewer = requestedResult.viewer;
  const pulls = [...new Map([...requestedResult.pulls, ...reviewedResult.pulls].map((pull) => [key(pull), pull])).values()];
  const requested = new Set(pulls.map(key));
  // Keep requested PRs addressable after a merge clears their pending review request.
  const tracked = [...new Map([
    ...(previous?.pulls ?? []).filter((pull) => pull.createdAt && pull.createdAt >= cutoff),
    ...saved.map((review) => review.pull),
  ].map((pull) => [key(pull), pull])).values()];
  const missing = tracked.filter((pull) => !requested.has(key(pull)));
  const refreshed = await Promise.allSettled(missing.map((pull) => fetchPull(pull, signal)));
  signal?.throwIfAborted();
  refreshed.forEach((result, index) => {
    if (result.status === "fulfilled") {
      pulls.push(result.value);
    } else {
      console.error(`Could not refresh tracked ${key(missing[index])}: ${result.reason}`);
      pulls.push(missing[index]);
    }
  });

  const cache = { viewer, fetchedAt: new Date().toISOString(), pulls };
  await writeJson(join(root, "pulls.json"), cache);

  return cache;
}

export async function allPulls(root: string, days = DEFAULT_DAYS): Promise<{ cache: Cache | null; pulls: Pull[] }> {
  const cutoff = daysAgo(days);
  const [cache, saved] = await Promise.all([
    readJson<Cache>(join(root, "pulls.json")), savedReviews(root),
  ]);
  const merged = new Map(saved.map((review) => [key(review.pull), review.pull]));
  for (const pull of cache?.pulls ?? []) {
    if (merged.has(key(pull)) || (pull.createdAt && pull.createdAt >= cutoff)) {
      merged.set(key(pull), pull);
    }
  }
  for (const review of saved) {
    if (review.run && review.run.startedAt > (cache?.fetchedAt ?? "")) {
      merged.set(key(review.pull), review.pull);
    }
  }

  return { cache, pulls: [...merged.values()].sort((a, b) => a.repo.localeCompare(b.repo) || b.number - a.number) };
}

export async function resolvePull(root: string, input: string): Promise<Pull> {
  const target = parseTarget(input);
  if (target) {
    const { pulls } = await allPulls(root);
    return pulls.find((pull) => key(pull) === key(target)) ?? await fetchPull(target);
  }
  if (!/^[1-9]\d*$/.test(input)) {
    throw new Error("Use a PR number, owner/repo#number, or GitHub/Graphite URL.");
  }

  const { pulls } = await allPulls(root);
  const matches = pulls.filter((pull) => pull.number === Number(input));
  if (matches.length === 1) {
    return matches[0];
  }
  if (matches.length > 1) {
    throw new Error(`PR #${input} is ambiguous: ${matches.map(key).join(", ")}. Use owner/repo#number.`);
  }

  throw new Error(`No saved or requested PR #${input}. Refresh rv or pass its full URL.`);
}
