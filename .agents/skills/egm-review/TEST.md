# Test Plan: EGM Review & Subagents

Frontmatter and link checks run with `pytest tests/unit` from a full upstream EGM source checkout, not this consuming application. See the [upstream testing guide](https://github.com/google/elephant-goldfish-model/blob/403d8881d62022490637d740657b33f01e321ea8/TESTING.md) and [source checkout instructions](../../README.md).

## Protocol Verification Checklist

When evaluating or exploring `egm-review` interactively in chat, verify:

-   **Step 1 (Intake):** Gathers `TargetFile` and optional `GoldfishContext`.
-   **Step 2 (Preset Selection):** Offers the four review presets (interactive,
    consolidated, feature spec only, implementation plan only), or maps an
    explicit `Step` argument to its corresponding preset or individual stage subflow.
-   **Step 3 (Semantic Split):** Discovers the split line between Feature Spec
    and Detailed Implementation Plan.
-   **Subflows:** Properly delegates Zoom Out, Comprehension, Critic Review, and Readiness Test.
