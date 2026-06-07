---
name: code-style
description: "Code style preferences for writing, editing, refactoring, or testing code in any language. Use whenever an agent writes code, changes implementation, adds tests, or chooses abstractions, files, modules, or packages."
---

# Code Style

Write idiomatic code that fits the existing project first. Prefer local conventions, existing tooling, and ordinary language idioms over new patterns.

## Guidelines

- Prefer concrete code until repeated use proves the shape of an abstraction.
- Accept minor duplication when it keeps behavior obvious. Do not split code into many tiny helpers just to remove small repetition.
- Treat each new file, package, module, class, or component boundary as an abstraction. Create one only when it clarifies ownership, reduces real complexity, or matches established project structure.
- Keep implementation close to the behavior it supports. Prefer readable control flow and explicit data movement over clever generic plumbing.
- Make the smallest clear change that leaves future abstraction easy once the pattern is proven.

## Tests

- Test broad application behavior and user-visible outcomes before minor implementation details.
- Prefer integration, feature, or workflow tests when the application lacks coverage at that level.
- Avoid tests for tiny private helpers unless they protect a meaningful, bug-prone contract.
