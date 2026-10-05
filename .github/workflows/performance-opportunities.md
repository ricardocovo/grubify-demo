---
name: Performance Opportunities
description: review the code and identify the top performance improvement opportunities
on:
  workflow_dispatch:
permissions:
  copilot-requests: write
  contents: read
  issues: read
  actions: read
engine: copilot
strict: true
tools:
  github:
    mode: gh-proxy
    toolsets: [repos, issues, actions]
safe-outputs:
  create-issue:
    title-prefix: "[performance] "
    labels: [report, agentic-workflows]
    allowed-labels: [report, agentic-workflows]
    max: 1
  add-labels:
    allowed: [report, agentic-workflows]
    issues: true
    pull-requests: false
    required-title-prefix: "[performance] "
    target: "*"
    max: 1
timeout-minutes: 30
---

# Performance Improvement Opportunities

## Mission

For this manual run, find the repository's highest-value, actionable performance improvements and present the top five in one concise issue.

A successful run creates one labeled issue containing up to five distinct, repository-specific performance improvements ranked by expected impact, each grounded in concrete evidence and paired with a measurable validation method. Never invent findings to fill the list.

## Repository-Specific Scope

- The root README describes an Azure SRE Agent community hub. Review application code in `labs/` and reusable scripts, recipes, and infrastructure under `sreagent-templates/`.
- Read the relevant README, applicable `AGENTS.md`, `CONTRIBUTING.md`, package manifests, tests, and existing workflow checks before assessing a code path. There is no single root build or test command; use only commands documented for the affected subproject.
- Prioritize application runtime, database, I/O, memory, and script performance. Consider GitHub Actions speed only when recent run data shows a concrete, repeatable duration regression; do not infer a slowdown from workflow YAML alone.
- Distinguish normal application behavior from intentional lab faults, chaos exercises, `break-*`/`fix-*` scripts, seeded failures, and demo fixtures. Do not propose removing a teaching scenario as a performance fix.
- Exclude generated output, vendored code, dependencies, documentation-only changes, and generic best-practice suggestions without repository-specific evidence.

## Review Process

1. Inspect source, tests, existing benchmarks or profiling output, and relevant CI evidence. Use GitHub read tools for issue/PR context and, only when useful, recent Actions run durations.
2. Identify candidate bottlenecks with a concrete code path or repeated measured slowdown. Prefer measured profiles, timings, query plans, or existing test evidence. If evidence is only a code-level inference, label the impact as an estimate and state why the path is likely important.
3. Search open issues for the same performance report or already-tracked recommendations. Do not create a materially duplicate report.
4. Rank up to five distinct, untracked opportunities by expected user-visible performance impact, strength of evidence, and implementation effort. Do not state numeric speedups unless repository measurements support them.
5. For every finding, record:
   - Rank and concise title.
   - Evidence with a repository-relative path and relevant line, symbol, test, or measurement.
   - A specific change to consider and the likely affected workload or resource.
   - Impact and confidence, distinguishing measured results from estimates.
   - A measurable validation method, such as a relevant existing test, benchmark, profile, latency percentile, throughput, CPU/memory, or database-query measurement. If no benchmark exists, describe what to measure before and after without inventing a target.

Do not edit repository files, install dependencies, run deployments, provision Azure resources, or launch load/chaos tests. Do not expose secrets or copy credentials into the report.

## Publish One Report

If at least one actionable, sufficiently supported, untracked opportunity remains, create exactly one issue using the configured `create-issue` safe output. Put all ranked opportunities in that issue; do not create one issue per finding. Use a concise title after the configured `[performance] ` prefix and include the existing `report` and `agentic-workflows` labels.

Use `add-labels` only when an already-open issue with the `[performance] ` title prefix materially duplicates this report and is missing one of those existing labels. Target that known issue by its actual issue number; do not use a temporary ID or label unrelated issues. The repository has no dedicated performance label.

Format the issue body with `###` section headings:

- `### Summary` — scope reviewed and number of qualifying opportunities.
- `### Ranked opportunities` — ordered findings with evidence, proposed change, impact/confidence, effort, and validation method.
- `### Ranking method and caveats` — briefly explain how evidence and expected impact shaped the ranking; distinguish estimates from measured results.
- `### References` — relevant repository paths and measurements.

If fewer than five candidates meet the evidence bar, report only those candidates and say why the list is shorter. Use `noop` with a brief reason when no actionable candidate is supported, or when an open report already covers the same findings. If an existing duplicate needs only the approved labels, add those labels and do not create another issue.
