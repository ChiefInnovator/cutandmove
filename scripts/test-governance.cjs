// Guard privileged workflow boundaries independently of the validator truth table.
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const read = name => fs.readFileSync(path.join(__dirname, '../.github/workflows/', name), 'utf8');
const policy = read('branch-policy.yml');
assert.match(policy, /pull_request_target:/);
assert.match(policy, /types: \[opened, synchronize, reopened, edited, ready_for_review\]/);
assert.match(policy, /name: Branch source to \$\{\{ github.event.pull_request.base.ref \}\}/);
assert.doesNotMatch(policy, /actions\/checkout|contents: write|pull-requests: write/);
assert.match(policy, /github-script@[a-f0-9]{40}/);
const release = read('release-marketing.yml');
assert.match(release, /permissions:\n  contents: read\n/);
assert.doesNotMatch(release, /(?:contents|pages|pull-requests): write/);
assert.doesNotMatch(release, /git (?:push|commit)|pages\/builds|urllib|time\.sleep/);
assert.match(release, /ref: main/);
assert.match(release, /git diff --binary -- marketing.json index.html README.md llms.txt/);
assert.match(release, /if test -s .*release-marketing.patch/);
assert.match(release, /base-sha.txt/);
assert.match(release, /release-marketing\/release.json/);
assert.match(release, /if: steps.patch.outputs.changed == 'true'/);
assert.match(release, /upload-artifact@[a-f0-9]{40}/);
assert.match(release, /name: release-marketing\n/);
assert.match(release, /retention-days: 7/);
assert.match(release, /if-no-files-found: error/);
const marketing = read('marketing.yml');
for (const script of ['test-branch-policy.cjs', 'test-governance.cjs']) {
  assert.ok(marketing.includes(`node scripts/${script}`), `${script} must run in CI`);
}
console.log('Trusted branch-check and read-only release-artifact contracts passed.');
