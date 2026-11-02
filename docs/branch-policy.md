# Branch policy

All changes follow `feature/<name>` → `develop` → `main`, using pull requests
and merge commits. Source branches must belong to this repository. Forks must
be imported into a local feature branch before integration.

Both integration branches require the `Branch source` GitHub Actions check,
resolved conversations, and a pull request. Direct pushes, force pushes, and
deletion are blocked. No bypass actors are configured. The owner can still
change repository settings; rules cannot prevent administrative policy changes.

Copilot automatic cloud review applies only to pull requests targeting
`develop`, including new pushes. It is advisory, subject to account eligibility
and availability; it does not count as a human approval. No human approval is
required because this is a solo-maintained repository. Never request reviews
manually or push empty commits to trigger them.

The source check runs on `pull_request_target`, reads live PR metadata, and
never executes or checks out feature code. Do not change its job name without
updating the required check in both rulesets. Protect this workflow during review;
a repository writer who deliberately replaces trusted CI can undermine checks.

`develop` is retained after promotion. Start subsequent features from develop.
Promote with merge commits so both branches retain shared ancestry. Do not
squash or rebase promotions. Release marketing updates must use the same route;
the GitHub Actions bot has no direct-push exemption.
