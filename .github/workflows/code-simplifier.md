---
name: Code Simplifier
description: Reviews the entire codebase for behavior-preserving simplifications and reports actionable changes in an issue
intent: Identify repository-wide opportunities to simplify code without changing behavior.
on:
  workflow_dispatch:

network: defaults

permissions:
  copilot-requests: write
  contents: read
  issues: read

tracker-id: code-simplifier

imports:
  - shared/formatting.md
  - shared/reporting.md

safe-outputs:
  create-issue:
    title-prefix: "[code-simplifier] "
    labels: [refactoring, code-quality, automation]
    max: 1

tools:
  github:
    toolsets: [repos, issues]

timeout-minutes: 30
---

# Code Simplifier

Review the entire repository and create one concise issue describing worthwhile code simplifications. Do not edit files or create a pull request.

## Review

1. Read the project guidance, manifests, source code, and relevant tests.
2. Inspect all maintained source code, regardless of when it was last changed.
3. Exclude generated files, vendored dependencies, lock files, and build output.
4. Look for behavior-preserving improvements such as:
   - reducing unnecessary complexity or nesting;
   - removing duplication or redundant abstractions;
   - improving unclear names and control flow;
   - replacing non-idiomatic patterns with established project conventions.
5. Keep only specific, actionable findings supported by repository evidence.
6. Search open issues and omit findings that are already tracked.

Favor clarity over fewer lines. Do not recommend changes that alter public APIs, behavior, or intentional abstractions.

## Publish

If useful findings remain, create exactly one issue using `create-issue`.

Use this compact format:

```markdown
## Summary
[One short paragraph.]

## Suggested changes

### 1. [Title]
- **Where:** `path/to/file` and symbol or line
- **Change:** [Specific simplification]
- **Why:** [Clarity or maintainability benefit]
- **Validate:** [Relevant tests or checks]
```

Order findings by impact. Include only the sections above and keep each finding brief.

Use `noop` with a short reason if there are no worthwhile untracked simplifications.
