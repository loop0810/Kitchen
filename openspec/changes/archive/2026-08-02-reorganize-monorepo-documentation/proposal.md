## Why

The repository is becoming a monorepo for a Flutter client and a Swift server, while its current documentation and nested OpenSpec layout still reflect a client-only project. Without explicit ownership and reading routes, server iterations would repeatedly load unrelated client requirements, waste context, and produce learning notes that drift from authoritative requirements.

## What Changes

- Establish a root documentation taxonomy that separates shared product rules, cross-platform contracts, client implementation, server implementation, server learning records, and architectural decisions.
- Add task-oriented documentation indexes and scoped `AGENTS.md` routing so client and server work reads only the relevant context by default.
- Define a server iteration learning workflow that turns each completed OpenSpec change into a concise retrospective learning record with code and test navigation.
- Make cross-platform contracts the single source of truth for API payloads, shared models, error semantics, and synchronization behavior instead of duplicating them in client and server documents.
- Consolidate change planning under the root OpenSpec workspace so client, server, and cross-platform changes are visible from one project root.
- Reclassify and relocate the existing client documentation without changing product behavior or creating the Vapor server application.

## Capabilities

### New Capabilities

- `scoped-documentation-workflow`: Defines documentation ownership, task-based reading routes, cross-platform contract authority, and the server iteration learning-record lifecycle for the monorepo.

### Modified Capabilities

None.

## Impact

- Affects the root documentation layout, root and project-scoped `AGENTS.md` files, documentation links, and OpenSpec change placement.
- Existing product requirements remain behaviorally unchanged; files may move and links must be repaired.
- The existing nested `client/openspec` content requires deliberate migration into the root OpenSpec workspace without losing history.
- No application code, API behavior, database schema, production dependency, or deployment configuration is introduced by this change.
