import { mkdir } from "node:fs/promises";
import { homedir } from "node:os";
import { join } from "node:path";
import { directory, key, readJson, writeJson, type Review } from "./store";

// The kitty agents picker (cmd+shift+a, kitty/kittens/agents.py) reads this file to show
// which PR a review chat is about. Shape: { [sessionId]: ReviewChat }.
export type ReviewChat = {
  agent: string;
  url: string;
  repo: string;
  number: number;
  title: string;
  // Review directory with review.json and html.json; root holds pulls.json (viewer login).
  dir: string;
  root: string;
};

export function reviewChatsPath(): string {
  const state = process.env.KITTY_AGENTS_STATE ?? join(homedir(), ".local", "state", "kitty-agents");

  return join(state, "reviews.json");
}

function sameChat(a: ReviewChat | undefined, b: ReviewChat): boolean {
  return Boolean(a) && JSON.stringify(a) === JSON.stringify(b);
}

// saveReview runs on every agent event, so this only writes when the entry changes.
// The picker is optional: failures are logged and never stop a review.
export async function registerReviewChat(root: string, review: Review): Promise<void> {
  const run = review.run;
  if (!run?.sessionId) {
    return;
  }

  const path = reviewChatsPath();
  const chat: ReviewChat = {
    agent: run.agent,
    url: review.pull.url,
    repo: review.pull.repo,
    number: review.pull.number,
    title: review.pull.title,
    dir: directory(root, review.pull),
    root,
  };

  try {
    const chats = await readJson<Record<string, ReviewChat>>(path) ?? {};
    if (sameChat(chats[run.sessionId], chat)) {
      return;
    }

    await mkdir(join(path, ".."), { recursive: true });
    await writeJson(path, { ...chats, [run.sessionId]: chat });
  } catch (error) {
    console.error(`rv: could not register ${key(review.pull)} for the agents picker (${path}): ${error}`);
  }
}
