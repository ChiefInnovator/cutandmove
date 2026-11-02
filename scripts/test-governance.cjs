// Guard privileged workflow boundaries independently of the validator truth table.
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const os = require('node:os');
const { execFileSync } = require('node:child_process');
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

// Execute the producer's actual shell in a disposable repository, including no-op.
const patchBlock = release.match(/- name: Prepare reviewable patch\n[\s\S]*?        run: \|\n([\s\S]*?)      - name: Upload release patch/);
assert.ok(patchBlock, 'Expected release patch producer');
const shell = patchBlock[1].split('\n').map(line => line.slice(10)).join('\n');
const temporary = fs.mkdtempSync(path.join(os.tmpdir(), 'cutandmove-governance-'));
try {
  const repository = path.join(temporary, 'repo'), runner = path.join(temporary, 'runner');
  fs.mkdirSync(repository);
  fs.mkdirSync(runner);
  const git = (...args) => execFileSync('git', args, { cwd: repository, encoding: 'utf8' }).trim();
  git('init', '-q', '--initial-branch=main');
  const generated = ['marketing.json', 'index.html', 'README.md', 'llms.txt'];
  for (const name of [...generated, 'unrelated.txt']) fs.writeFileSync(path.join(repository, name), 'original\n');
  git('add', '.');
  git('-c', 'user.name=Workflow Fixture', '-c', 'user.email=fixture@example.invalid', 'commit', '-qm', 'Fixture baseline');
  const baseline = git('rev-parse', 'HEAD');
  fs.writeFileSync(path.join(runner, 'release.json'), '{"tag_name":"v2.0.1"}\n');
  const output = path.join(temporary, 'output'), summary = path.join(temporary, 'summary');
  function runProducer() {
    fs.writeFileSync(output, '');
    fs.writeFileSync(summary, '');
    execFileSync('bash', ['-e', '-o', 'pipefail', '-c', shell], { cwd: repository,
      env: { ...process.env, RUNNER_TEMP: runner, GITHUB_OUTPUT: output, GITHUB_STEP_SUMMARY: summary } });
    assert.equal(git('rev-parse', 'HEAD'), baseline, 'Producer must never commit');
    assert.equal(git('branch', '--show-current'), 'main', 'Producer must not switch branches');
    return fs.readFileSync(output, 'utf8');
  }
  assert.equal(runProducer(), 'changed=false\n');
  assert.match(fs.readFileSync(summary, 'utf8'), /already current/);
  assert.equal(fs.statSync(path.join(runner, 'release-marketing/release-marketing.patch')).size, 0);
  assert.equal(fs.existsSync(path.join(runner, 'release-marketing/base-sha.txt')), false);
  for (const name of [...generated, 'unrelated.txt']) fs.writeFileSync(path.join(repository, name), 'updated\n');
  assert.equal(runProducer(), 'changed=true\n');
  const artifact = path.join(runner, 'release-marketing');
  assert.equal(fs.readFileSync(path.join(artifact, 'base-sha.txt'), 'utf8').trim(), baseline);
  assert.equal(fs.readFileSync(path.join(artifact, 'release.json'), 'utf8'), '{"tag_name":"v2.0.1"}\n');
  const patch = fs.readFileSync(path.join(artifact, 'release-marketing.patch'), 'utf8');
  for (const name of generated) assert.ok(patch.includes(`diff --git a/${name} b/${name}`));
  assert.ok(!patch.includes('unrelated.txt'), 'Artifact must contain only generated marketing files');
  git('restore', '--worktree', '.');
  git('apply', '--check', path.join(artifact, 'release-marketing.patch'));
  git('apply', path.join(artifact, 'release-marketing.patch'));
  for (const name of generated) assert.equal(fs.readFileSync(path.join(repository, name), 'utf8'), 'updated\n');
  assert.equal(fs.readFileSync(path.join(repository, 'unrelated.txt'), 'utf8'), 'original\n');
} finally {
  fs.rmSync(temporary, { recursive: true, force: true });
}
console.log('Workflow security contracts and actual release producer no-change/patch round trip passed.');
