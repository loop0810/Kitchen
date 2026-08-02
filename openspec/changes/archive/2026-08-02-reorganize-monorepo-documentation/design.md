## Context

The repository root now owns `.git`, while the existing Flutter project and its documentation live under `client/`. A new empty root OpenSpec workspace exists, but the previous client OpenSpec workspace still contains a change that is invisible to root-level `openspec list`. Existing documentation totals roughly ten thousand words and mixes product authority, client implementation constraints, future server responsibilities, visual design, and learning workflow guidance.

The design must preserve all existing product meaning and user work while creating a low-context path for future Vapor development. See `proposal.md` for motivation and `specs/scoped-documentation-workflow/spec.md` for required behavior.

## Goals / Non-Goals

**Goals:**

- Give every durable document one clear authority class and one navigable home.
- Let root, client, server, contract, and infrastructure tasks resolve a minimal reading set before loading detailed documents.
- Preserve a single source of truth for cross-platform behavior.
- Connect OpenSpec planning, implementation verification, and retrospective server learning without duplicating their content.
- Consolidate OpenSpec discovery at the monorepo root while retaining the existing client change.
- Make the migration reviewable in small, link-verifiable stages.

**Non-Goals:**

- Creating the Vapor project, API endpoints, database schema, or deployment stack.
- Rewriting or reprioritizing product requirements.
- Converting every existing Markdown statement into an OpenSpec requirement.
- Generating an OpenAPI document before a real HTTP contract is designed.
- Requiring a learning tutorial for trivial maintenance with no reusable lesson.

## Decisions

### 1. Use a hybrid ownership taxonomy

Durable documentation will be rooted at `docs/` and divided by authority:

```text
docs/
├── README.md
├── product/
├── contracts/
├── client/
├── server/
├── learning/server/iterations/
└── decisions/
```

Product and contracts are shared authority; client and server contain implementation guidance; learning contains retrospective teaching material; decisions contain cross-cutting rationale. This hybrid avoids two bad extremes: one flat directory that forces broad reading, and fully duplicated per-project documentation that lets shared contracts drift.

Files whose tools or scope require locality remain outside `docs/`: `AGENTS.md` stays next to governed code, OpenSpec artifacts stay under `openspec/`, and project entry READMEs stay with their projects.

Alternative considered: keep all client documentation under `client/docs` and create `server/docs`. This gives strong physical isolation but makes shared product and API ownership ambiguous and encourages duplicate rules.

### 2. Make indexes executable reading maps

`docs/README.md` and each major subdirectory `README.md` will state:

- what the directory is authoritative for;
- what it is not authoritative for;
- which task types require each document;
- which related documents are conditional rather than default reading.

The root `AGENTS.md` will route by affected area. `client/AGENTS.md` and `server/AGENTS.md` will define minimal project-specific reading sets and explicitly prohibit default traversal of unrelated documentation. Search-first discovery with `rg` is preferred when only a term or capability must be located.

Alternative considered: rely on filenames alone. Names aid discovery but cannot express authority, conditional reading, or cross-cutting triggers reliably.

### 3. Treat contracts as the bridge, not as summaries

`docs/contracts` will own only behavior relied upon by both sides: transport conventions, request and response schemas, stable identifiers, version negotiation, error semantics, idempotency, and synchronization behavior. A contract is not a condensed copy of product requirements and does not describe Vapor or Flutter implementation details.

During migration, mixed documents will be split by ownership. For example, local Drift caching remains client documentation, while remote revision identifiers and synchronization semantics become a shared personalization contract. Client and server documents then link to that contract.

Future machine-readable OpenAPI may become authoritative for HTTP structure, with Markdown retaining domain semantics and rationale. That transition is deferred until the first API is designed.

Alternative considered: add a short `SERVER_CONTEXT.md` summarizing all server-relevant product material. A manual summary is initially convenient but creates another authority that can drift; focused contracts provide a safer bounded context.

### 4. Separate planning records from learning records

OpenSpec artifacts remain the planning and acceptance trail:

```text
proposal → delta specs + design → tasks → implementation → archive
```

A server learning record is created near completion and captures only retrospective learning value:

```text
goal
prerequisite concepts
architecture/data flow
implementation sequence and rationale
database or contract changes
verification approach
problems and corrections
code/test navigation
related OpenSpec and decisions
next learning step
```

It links rather than copies requirements, tasks, or large code blocks. The final server iteration checklist requires either a learning record or a stated exemption explaining why the change has no meaningful learning delta.

Alternative considered: use archived OpenSpec artifacts as the tutorial. Those artifacts explain intended change and acceptance, but they do not reliably capture misconceptions, debugging lessons, or a learner-oriented route through the final code.

### 5. Use one root OpenSpec workspace

All future changes will live under root `openspec/changes`. Scope is communicated through clear names such as `client-*`, `server-*`, or `shared-*` where helpful, plus proposal impact and capability names. Cross-platform changes can therefore plan contract and both adapters together.

The existing nested client change will be inventoried before migration. If no root name collision exists, its directory is moved intact to the root changes area and validated there. If a collision exists, migration stops for an explicit rename decision. The nested workspace is removed only after root listing, status, validation, and link checks succeed.

Alternative considered: retain independent OpenSpec roots. That reduces local listings but hides cross-platform changes, requires explicit store/root selection, and has already made the existing client change invisible from the monorepo root.

### 6. Migrate in phases with an explicit classification map

Before moving files, create a source-to-destination inventory classifying every current document as move unchanged, split, merge, or retain locally. Initial expected ownership is:

- product requirements and release scope → `docs/product`;
- Figma and client visual guidance → `docs/client/design`;
- Flutter naming, package architecture, local data, local import, and template rendering → `docs/client`;
- cross-platform personalization, backup/sync, AI request, and entitlement semantics → relevant contracts, with server implementation guidance deferred until implementation exists;
- durable architectural decisions → `docs/decisions`;
- Codex learning workflow → project workflow guidance, separate from server iteration records.

Moves should preserve content first; splitting mixed documents happens only after destinations and links are stable. This makes semantic changes visible during review.

## Risks / Trade-offs

- **[Risk] Moving many files obscures accidental content edits** → Perform mechanical moves before any ownership split, review rename detection, and compare content independently from paths.
- **[Risk] Contracts become another broad dumping ground** → Require contract indexes to define accepted topics and keep product rationale and project implementation out.
- **[Risk] Scoped routing omits context needed for a cross-cutting change** → Define explicit escalation triggers for shared interfaces, user-visible behavior, release scope, security, and data migration.
- **[Risk] Learning records duplicate tasks or become burdensome** → Use a concise template, link to authority and code, and permit a reasoned no-learning-delta exemption.
- **[Risk] Nested OpenSpec migration loses history or overwrites work** → Inventory names, preserve directories intact, validate before deleting the nested root, and stop on collisions.
- **[Trade-off] One root OpenSpec list is broader** → Consistent naming and capability scope make filtering easier, while preserving visibility for cross-platform work.
- **[Trade-off] Root `docs/` is physically shared** → Routing indexes and scoped `AGENTS.md` provide logical isolation without duplicating authority.

## Migration Plan

1. Inventory all existing durable documents, links, `AGENTS.md` rules, and nested OpenSpec changes; create the classification and collision map.
2. Establish the root documentation skeleton, indexes, authority descriptions, and learning-record template.
3. Move documents mechanically into product, client, and decision destinations; update indexes and links without changing their meaning.
4. Analyze mixed service documents, extract genuinely cross-platform contracts, and leave project implementation guidance in its owning area.
5. Add root and scoped `AGENTS.md` task routes, including escalation triggers and explicit non-default areas.
6. Consolidate the nested OpenSpec change into the root workspace and validate discovery and artifacts before removing the nested root.
7. Verify links, search for stale paths, validate OpenSpec, and compare moved content for unintended semantic changes.

Rollback is path-based: retain the migration map, reverse moves if validation fails, and keep the nested OpenSpec workspace until root consolidation is proven. No application or user data migration is involved.
