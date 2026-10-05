---
on:
  pull_request:
    types: [opened, synchronize]

permissions:
  copilot-requests: write 
  contents: read
  pull-requests: read

safe-outputs:
  add-comment:
    max: 1
  create-pull-request-review-comment:
    max: 10
  submit-pull-request-review:
    allowed-events: [COMMENT]
---

# Pull Request Review Assistant

Review the pull request diff for correctness, security, maintainability, and test coverage.

Create inline review comments only for specific problems or concrete improvements. Add one summary comment that groups findings by severity and notes anything that needs human follow-up. Do not restate unchanged code or provide style-only feedback.