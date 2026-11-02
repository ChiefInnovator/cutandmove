# Stage 6: Comprehension

Fresh-context reviewer: goldfish_comprehension. No standard, per protocol.

**What this proposes**

The repository will enforce same-repository feature branches merging into develop,
followed by develop promotion PRs into main, with branch-source checks and automatic
Copilot reviews. It installs local design/review tooling, documents the current
product, runs fresh reviews, and implements bounded findings while preserving
current interface and file-move safety. Verification distinguishes source checks
and builds from rendered UI, Finder behavior, signed-package acceptance, deployment.

**How the existing system works, per this document**

A macOS menu-bar utility monitors Finder keyboard shortcuts and invokes Finder's
native move command. The Finder extension exchanges local request/status files
with the host, which validates and executes moves while sharing pending-cut state.
The static download site and release/marketing automation formerly allowed direct
main updates.

## Findings

C1 — Major. Goals lines 28–32; implementation steps 2–4 and 6, lines 157–176.
EGM, Goldfish, and Impeccable are undefined and lack explicit documentation links.
A reader cannot determine stages 5–9, their personas/standards, or the meanings
of extension tokens, surface context, surface briefs, and separate modes.
Remedy: define each framework, link exact local pipeline/schema documents, and
explain those record terms inline.

No Blocker findings; both ranges can be paraphrased coherently.
Read in full: .agents/agents/comprehension.md and design_draft.md (1–213).
No standards, external references, history, memory, execution, or writes.
