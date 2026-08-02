## 1. Inventory and Migration Safety

- [x] 1.1 Inventory every existing durable Markdown document, its current authority, inbound repository references, and proposed destination as move unchanged, split, merge, or retain locally.
- [x] 1.2 Inventory root and nested OpenSpec changes and configuration, verify change-name collisions, and record the safe migration action for each item.
- [x] 1.3 Capture a pre-migration validation baseline for repository-relative documentation links, OpenSpec listing/status, and Git rename visibility.

## 2. Documentation Taxonomy and Navigation

- [x] 2.1 Create the root `docs` directory structure for product, contracts, client, server, server learning iterations, and decisions.
- [x] 2.2 Create `docs/README.md` with authority boundaries and a task-to-document reading matrix that distinguishes default and conditional context.
- [x] 2.3 Create focused README indexes for each documentation class describing what it owns, what it excludes, and its intended readers.
- [x] 2.4 Add the server learning-iteration template, naming convention, completion trigger, and explicit no-learning-delta exemption rule.

## 3. Mechanical Document Relocation

- [x] 3.1 Move product and release-scope documents into `docs/product` without semantic edits, then update their index and repository-relative links.
- [x] 3.2 Move client architecture, service, workflow, naming, and visual-design documents into their classified `docs/client` destinations without semantic edits.
- [x] 3.3 Move durable architectural decisions into `docs/decisions` and repair all references to the decision log.
- [x] 3.4 Compare relocated documents against their source content and review Git rename detection to confirm the mechanical phase did not alter requirements.

## 4. Shared Contract Extraction

- [x] 4.1 Review mixed service documents and identify only behavior jointly relied upon by client and server, including personalization revisions, identifiers, synchronization, idempotency, errors, AI requests, backup, and entitlement semantics.
- [x] 4.2 Extract each confirmed shared behavior into one focused contract authority under `docs/contracts`, leaving Flutter, local-database, and future Vapor implementation details in their owning scopes.
- [x] 4.3 Replace duplicated normative statements in client and server guidance with links to the corresponding shared contract while preserving explanatory implementation context.
- [x] 4.4 Verify every contract index entry declares its scope and that no conflicting authoritative definition remains elsewhere in durable documentation.

## 5. Scoped Contributor Instructions

- [x] 5.1 Create the root `AGENTS.md` as a concise scope router covering client, server, shared contract, product, infrastructure, and cross-cutting escalation triggers.
- [x] 5.2 Update `client/AGENTS.md` to use the new client documentation routes and to load server implementation guidance only for an affected shared boundary.
- [x] 5.3 Add server-scoped contributor instructions that default to the active change, server index, affected module, and relevant contracts while excluding client and full product documentation.
- [x] 5.4 Verify representative client-only, server-only, shared-contract, and product-scope tasks each resolve to the intended minimal reading set.

## 6. OpenSpec Workspace Consolidation

- [x] 6.1 Migrate the existing nested client change artifacts intact into the root OpenSpec workspace according to the collision inventory.
- [x] 6.2 Update documentation and contributor instructions to reference the single root OpenSpec workflow and clear client, server, and shared change naming.
- [x] 6.3 Confirm root OpenSpec listing, status, and validation can discover the migrated client change before removing the obsolete nested OpenSpec root.

## 7. Final Verification

- [x] 7.1 Scan the repository for stale documentation and nested OpenSpec paths, repair remaining references, and validate all local Markdown links.
- [x] 7.2 Run strict OpenSpec validation for this change and status/validation checks for the migrated existing change.
- [x] 7.3 Review the final Git diff separately for path moves and semantic edits, confirming that no product behavior, application code, dependency, or deployment configuration changed.
- [x] 7.4 Walk through the server-iteration completion flow and confirm it produces either a linked learning record or a documented exemption before archive.
