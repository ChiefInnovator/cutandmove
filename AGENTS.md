# Cut & Move

- Keep the native SwiftUI/AppKit app and static marketing page as separate surfaces.
- Delivery route: same-repository `feature/*` → PR to `develop` → PR to `main`.
  Use merge commits, retain develop, and never bypass branch protections.
- Copilot reviews are automatic on develop. Never request/re-request reviews,
  create empty commits, or push no-op changes to trigger them.
- Use project-local `.agents/skills/egm-*` with `.agents/agents`, resources, and
  docs. Goldfish reviewers must use fresh contexts (`fork_turns: none`).
- Use `.agents/skills/impeccable/SKILL.md` for UI documentation and review.
  Read PRODUCT.md, DESIGN.md, and the matching surface brief before UI changes.
- Run `make marketing-check`, the Python marketing/release tests, and
  `node scripts/test-share.cjs` for website/release changes. Run `make test` for
  native changes; use unit-only xcodebuild when desktop UI control is unsuitable.
- `make test-finder` controls the desktop. Use disposable fixtures and never
  infer live Finder, signing, notarization, or release acceptance from unit tests.
- Never add agent rules to CLAUDE.md or tool-specific instruction files.
