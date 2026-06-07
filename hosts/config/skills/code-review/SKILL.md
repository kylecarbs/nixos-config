---
name: code-review
description: "Code review workflow for evaluating changes, implementations, and tests. Use when reviewing code, validating functionality, checking a diff, preparing merge feedback, or deciding whether an implementation meets project style and quality expectations."
---

# Code Review

Review for correctness first, then maintainability. Prefer concrete, actionable findings tied to observable risk.

## Process

- Understand the intended behavior and the affected user-facing or system-facing workflows.
- Inspect the implementation in context, not only the diff. Run relevant tests or checks when practical.
- For non-trivial changes, use independent subagents or parallel review agents when available. Give each agent a concrete validation target and avoid leaking your conclusions so their pass can catch missed functionality or style issues.
- Apply the standards from `code-style`. Push back on premature abstractions, unnecessary files or package boundaries, tiny helper sprawl, and narrow tests that miss broad application behavior.
- Treat missing broad tests as a higher risk than missing tests for small private helpers.

## Findings

- Lead with bugs, regressions, broken workflows, missing broad tests, and maintainability risks.
- Include file and line references when possible.
- Separate confirmed issues from questions, assumptions, or optional improvements.
