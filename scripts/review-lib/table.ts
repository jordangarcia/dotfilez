import { plain } from "./store";

export type Cell = { text: string; url?: string };

export type Column = { heading: string; limit: number };

export function relativeAge(value: string | null | undefined, now = Date.now()): string {
  const timestamp = Date.parse(value ?? "");
  if (!Number.isFinite(timestamp)) {
    return "—";
  }
  const seconds = Math.max(0, Math.floor((now - timestamp) / 1000));
  const units = [{ size: 86400, label: "d" }, { size: 3600, label: "h" }, { size: 60, label: "m" }];
  const unit = units.find((item) => seconds >= item.size);

  return unit ? `${Math.floor(seconds / unit.size)}${unit.label} ago` : "just now";
}

function clip(text: string, width: number): string {
  if (Bun.stringWidth(text) <= width) {
    return text;
  }
  let result = "";
  const segments = new Intl.Segmenter(undefined, { granularity: "grapheme" }).segment(text);
  for (const { segment } of segments) {
    if (Bun.stringWidth(result + segment) > width - 3) {
      break;
    }
    result += segment;
  }

  return `${result}...`;
}

// `flex` is the column that absorbs the remaining terminal width (the PR title).
export function renderTable(columns: Column[], records: Cell[][], flex: number, links: boolean): string {
  const widths = columns.map((column, index) => Math.min(column.limit, Math.max(
    column.heading.length, ...records.map((row) => Bun.stringWidth(plain(row[index].text))),
  )));
  const available = (process.stdout.columns || 180) - (columns.length - 1) * 3;
  const otherColumns = widths.reduce((total, width, index) => total + (index === flex ? 0 : width), 0);
  widths[flex] = Math.min(widths[flex], Math.max(16, available - otherColumns));

  // Narrow terminals (half-width splits): once `flex` hits its floor, take the rest from the
  // widest other column, one cell at a time, so rows never wrap. Headings stay unclipped.
  let overflow = widths.reduce((total, width) => total + width, 0) - available;
  while (overflow > 0) {
    const widest = widths.reduce((best, width, index) => {
      const shrinkable = index !== flex && width > columns[index].heading.length;
      return shrinkable && (best < 0 || width > widths[best]) ? index : best;
    }, -1);
    if (widest < 0) {
      break;
    }

    widths[widest] -= 1;
    overflow -= 1;
  }

  const line = (cells: Cell[]) => cells.map((cell, index) => {
    const clipped = clip(plain(cell.text), widths[index]);
    const label = links && cell.url
      ? `\x1b]8;;${plain(cell.url)}\x1b\\\x1b[36;4m${clipped}\x1b[0m\x1b]8;;\x1b\\`
      : clipped;

    return label + " ".repeat(widths[index] - Bun.stringWidth(clipped));
  }).join("   ");
  const border = widths.map((width) => "─".repeat(width)).join("   ");
  const heading = line(columns.map((column) => ({ text: column.heading })));
  const rows = [
    links ? `\x1b[33m${heading}\x1b[0m` : heading,
    links ? `\x1b[2m${border}\x1b[0m` : border,
    ...records.flatMap((record, index) => [
      line(record),
      ...(index < records.length - 1 ? [links ? `\x1b[2m${border}\x1b[0m` : border] : []),
    ]),
  ];

  return rows.join("\n");
}
