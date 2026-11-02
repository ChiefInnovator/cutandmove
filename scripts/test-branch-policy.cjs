// Run the trusted workflow's actual inline validator against PR metadata fixtures.
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const workflow = fs.readFileSync(path.join(__dirname, '../.github/workflows/branch-policy.yml'), 'utf8');
const blocks = workflow.split('          script: |\n');
assert.equal(blocks.length, 2, 'Expected exactly one trusted inline validator');
const lines = blocks[1].split('\n');
const end = lines.findIndex(line => line.trim() && !line.startsWith('            '));
const source = lines.slice(0, end < 0 ? undefined : end).map(line => line.slice(12)).join('\n');
const repository = { full_name: 'ChiefInnovator/cutandmove' };
function fixture(base = 'develop', head = 'feature/work') {
  return { base: { ref: base, repo: repository }, head: { ref: head, sha: 'current-head', repo: repository } };
}
const cases = [];
for (const [base, head, expected] of [
  ['main', 'develop', true], ['develop', 'feature/work', true],
  ['develop', 'feature/ui/permissions', true], ['develop', 'main', false],
  ['develop', 'docs/work', false], ['main', 'feature/work', false],
  ['develop', 'feature/', false], ['main', 'main', false],
]) cases.push({ name: `${head} → ${base}`, live: fixture(base, head), expected });
for (const base of ['main', 'develop']) {
  const live = fixture(base, base === 'main' ? 'develop' : 'feature/work');
  live.head.repo = { full_name: 'fork/cutandmove' };
  cases.push({ name: `fork → ${base}`, live, expected: false });
}
for (const repo of [null, undefined]) {
  const live = fixture();
  live.head.repo = repo;
  cases.push({ name: 'missing/deleted head repo', live, expected: false });
}
for (const [name, change] of [
  ['stale head SHA', pr => { pr.head.sha = 'old-head'; }],
  ['renamed source', pr => { pr.head.ref = 'feature/old'; }],
  ['retargeted from main', pr => { pr.base.ref = 'main'; }],
  ['changed source repo', pr => { pr.head.repo = { full_name: 'fork/cutandmove' }; }],
]) {
  const live = fixture(), event = structuredClone(live);
  change(event);
  cases.push({ name, live, event, expected: false });
}
const main = fixture('main', 'develop'), oldBase = structuredClone(main);
oldBase.base.ref = 'develop';
cases.push({ name: 'retargeted from develop', live: main, event: oldBase, expected: false });
(async () => {
  for (const item of cases) {
    const failures = [];
    await vm.runInNewContext(`(async () => {\n${source}\n})()`, {
      github: { rest: { pulls: { get: async request => {
        assert.equal(request.pull_number, 42);
        return { data: item.live };
      } } } },
      context: { repo: { owner: 'ChiefInnovator', repo: 'cutandmove' }, issue: { number: 42 },
        payload: { pull_request: item.event ?? structuredClone(item.live) } },
      core: { setFailed: message => failures.push(message) },
    });
    assert.equal(failures.length === 0, item.expected, item.name);
  }
  console.log(`${cases.length} branch route, fork, deletion, and stale-event cases passed.`);
})().catch(error => { console.error(error); process.exitCode = 1; });
