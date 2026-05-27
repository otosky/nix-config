import test from "node:test";
import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";

const sourcePath = new URL("./web-search.ts", import.meta.url);
const source = await readFile(sourcePath, "utf8");

test("web search provider enum includes searxng", () => {
  assert.match(source, /Searxng: "searxng"/);
});

test("auto provider order is searxng, codex, brave, tavily", () => {
  assert.match(source, /const AUTO_SEARCH_PROVIDERS[^=]*= \[\s*SearchProvider\.Searxng,\s*SearchProvider\.Codex,\s*SearchProvider\.Brave,\s*SearchProvider\.Tavily,\s*\]/s);
});

test("searxng default endpoint is search.toskbot.xyz", () => {
  assert.match(source, /https:\/\/search\.toskbot\.xyz/);
});
