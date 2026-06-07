---
name: update-docs
description: "Documentation maintenance workflow for project agent guidance. Use after modifying code or project structure, when creating or updating AGENTS.md, or when documenting workflows, gotchas, project architecture, scope, objectives, and durable conventions."
---

# Update Docs

Keep agent-facing project documentation small, durable, and useful.

## Process

- After a code or project-structure change, decide whether agent-facing documentation needs to change. For small changes, update documentation yourself. For larger or cross-cutting changes, delegate an independent documentation pass to a subagent with these guidelines.
- Create an `AGENTS.md` when a project does not have one and recurring project guidance would help future agents.
- Update the nearest applicable `AGENTS.md` when a change reveals durable project architecture, scope, objectives, workflows, or gotchas.
- Keep `AGENTS.md` concise. Capture abstract project ideologies and architecture, not brittle file-by-file intent.
- Avoid bespoke instructions tied to current filenames or implementation details unless they represent stable project structure.
- Document common workflows and gotchas that future agents are likely to miss.

## What To Document

- Project purpose, scope, and architectural principles.
- Non-obvious commands, verification steps, setup requirements, and deployment workflows.
- Stable conventions, constraints, and gotchas that affect future work.
- Cleanup or migration notes only when they remain relevant after the current change.

## What To Avoid

- Do not document temporary implementation details, file intent, or one-off task context.
- Do not expand `AGENTS.md` with instructions that are obvious from project tooling or standard language practice.
- Do not leave outdated documentation in place after a change makes it obsolete.
