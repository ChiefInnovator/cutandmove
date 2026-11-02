# Branch policy

All changes follow `feature/<name>` → `develop` → `main`, using pull requests
and merge commits. Source branches must belong to this repository. Forks must
be imported into a local feature branch before integration.

Both integration branches require the target-specific GitHub Actions check (`Branch source to main` or
`Branch source to develop`),
resolved conversations, and a pull request. Direct pushes, force pushes, and
deletion are blocked. No bypass actors are configured. The owner can still
change repository settings; rules cannot prevent administrative policy changes.

Copilot automatic cloud review applies only to pull requests targeting
`develop`, including new pushes. It is advisory, subject to account eligibility
and availability; it does not count as a human approval. No human approval is
required because this is a solo-maintained repository. Never request reviews
manually or push empty commits to trigger them.

The source check runs on `pull_request_target`, reads live PR metadata, and
never executes or checks out feature code. Do not change emitted check names without
updating the corresponding required checks. Protect this workflow during review;
a repository writer who deliberately replaces trusted CI can undermine checks.

`develop` is retained after promotion. Start subsequent features from develop.
Promote with merge commits so both branches retain shared ancestry. Do not
squash or rebase promotions. Release marketing updates must use the same route;
the GitHub Actions bot has no direct-push exemption.

## Bootstrap and check-name migration

The bootstrap commit 96b288e installed a shared `Branch source` check before
creating/protecting develop. The current feature PR therefore runs the trusted
bootstrap check. After the new workflow lands on each base branch, switch that
branch's required context to its exact target-specific name (GitHub Actions app
15368). A real next PR can register the new name before switching; if no such PR
exists yet, installing the requirement is fail-closed until its first real run.
Never use an empty commit or no-op push to register a check. The job always runs;
there are no skipped inactive-target jobs that can accidentally count as passing.

The validator rejects live/event base ref, source ref, source repository, and head
SHA mismatches. `node scripts/test-branch-policy.cjs` exercises the actual trusted
inline script; `node scripts/test-governance.cjs` guards privileged workflow and
read-only patch boundaries. Live rule/check/review evidence belongs in
`docs/reviews/verification.md`; a local fixture is not a live GitHub rejection.

Repository ruleset IDs: main 26359272; develop 26359276. Both are active with no
bypass actors, zero required human approvals, and resolved conversations required.
Merge commits are the only allowed merge method. The owner authorized turning off
account-wide automatic review, and refreshed GitHub settings show it off. Personal
and ruleset automations are independent; re-enabling personal automatic review
would also review main PRs and defeat the develop-only review scope.
