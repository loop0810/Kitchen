## 1. Update global Change Gate rules

- [x] 1.1 Update the global Harness entry rules and skill so Change creation is controlled by developer intent
  - Scope: Update `/Users/loop/.codex/AGENTS.md` and `/Users/loop/.codex/skills/harness/SKILL.md` with explicit `change` and `direct` paths, the low-risk default, the ambiguity/high-impact rule, and the lightweight validation boundary.
  - Out of Scope: Do not change OpenSpec CLI behavior, schemas, repository runtime code, or existing Change artifacts.
  - Acceptance Criteria: The global rules no longer require creating a Change solely because `openspec/` exists; explicit `change` preserves the full lifecycle; explicit `direct` and low-risk unspecified work can proceed without proposal/specs/tasks/reports/full-suite/device validation by default; expanded scope can be escalated to Change mode.
  - Validation Level: Structural
  - Reset / Verification: Re-read the edited sections with `sed`/`rg`; if the global files cannot be edited in the current sandbox, stop before modifying them and report the permission boundary.

## 2. Synchronize Kitchen Harness documentation

- [x] 2.1 Document the developer-controlled Change Gate and lightweight path in Kitchen guidance
  - Scope: Update the repository `AGENTS.md` and the relevant `docs/Harness/` routing, code-change, and validation documents so they distinguish Change mode from direct/lightweight mode and do not conflict with the global rules.
  - Out of Scope: Do not alter product requirements, implementation code, OpenSpec schema/configuration, or unrelated documentation.
  - Acceptance Criteria: Kitchen guidance states when full Change artifacts are required, permits explicitly scoped low-risk direct work, defines the minimum direct validation, and retains tasks/report requirements for Change mode.
  - Validation Level: Structural
  - Reset / Verification: Search for stale unconditional wording and inspect the edited documentation; run `git diff --check`.

## 3. Validate workflow compatibility

- [x] 3.1 Validate the new Change artifacts and cross-document consistency
  - Scope: Run strict OpenSpec validation for this Change, inspect links and Change status, and verify the global/repository rules agree on the two execution paths.
  - Out of Scope: Do not run the client/server test suites, device validation, screenshots, or modify unrelated active Changes.
  - Acceptance Criteria: Strict OpenSpec validation passes; no stale rule requires a Change for every repository modification; all required artifacts and task reports are present and accurate.
  - Validation Level: Structural
  - Reset / Verification: Record the exact commands and outcomes in Task Reports; leave existing unrelated worktree changes untouched.
