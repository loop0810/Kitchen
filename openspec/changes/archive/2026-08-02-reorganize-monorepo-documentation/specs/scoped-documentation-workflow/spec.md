## Purpose

Provide a scoped, traceable documentation workflow for a client-and-server monorepo so each task loads only relevant authority while completed server iterations remain useful as durable learning material.

## ADDED Requirements

### Requirement: Durable documentation has an explicit ownership class
The repository SHALL classify every durable project document as shared product guidance, a cross-platform contract, client implementation guidance, server implementation guidance, a learning record, or an architectural decision. Each class SHALL have an index that states its authority and intended readers.

#### Scenario: A contributor locates server guidance
- **WHEN** a contributor starts a server-only implementation task
- **THEN** the documentation index identifies the server guidance without requiring the contributor to read client implementation or visual-design documents

#### Scenario: A document spans client and server behavior
- **WHEN** a rule defines data exchanged by both applications
- **THEN** the rule is classified as a cross-platform contract rather than duplicated as independent client and server authority

### Requirement: Task scope determines the default reading route
The repository SHALL provide root, client, and server task-routing instructions that identify a minimal default reading set. Server-only work MUST NOT require loading client implementation documents by default, and client-only work MUST NOT require loading server implementation documents by default.

#### Scenario: Server task has no shared behavior change
- **WHEN** a server task changes only internal implementation or deployment behavior
- **THEN** its default route includes the relevant server index, active change artifacts, and affected server module guidance but excludes client and full product documentation

#### Scenario: Task changes a shared interface
- **WHEN** a task changes an HTTP payload, shared identifier, error semantic, or synchronization rule
- **THEN** its route includes the affected cross-platform contract and the relevant client and server boundaries

#### Scenario: Task changes product scope
- **WHEN** a task changes user-visible behavior or release scope
- **THEN** its route includes the relevant product requirement authority in addition to implementation guidance

### Requirement: Cross-platform contracts have one authoritative definition
Shared API payloads, identifiers, versioning rules, error semantics, and synchronization behavior SHALL have one authoritative contract definition. Client documents, server documents, and learning records SHALL link to that definition instead of reproducing a competing normative definition.

#### Scenario: Client and server describe the same field
- **WHEN** both projects use the same contract field
- **THEN** the field's normative name, type, optionality, and semantic meaning are defined once in the shared contract

#### Scenario: A contract changes during an iteration
- **WHEN** an iteration changes shared behavior
- **THEN** the OpenSpec delta and authoritative contract are updated together, and affected implementation documents reference the revised authority

### Requirement: Completed server iterations produce durable learning records
Each completed server development iteration SHALL produce a concise learning record that explains its goal, prerequisite concepts, architecture and data flow, implementation sequence, tests, encountered problems, code navigation, related decisions, and next learning step.

#### Scenario: A server change is completed
- **WHEN** all implementation and verification tasks for a server OpenSpec change are complete
- **THEN** a server learning record is added or updated before the change is archived

#### Scenario: A learner revisits an iteration
- **WHEN** the learner opens an iteration record after implementation
- **THEN** the record links to the relevant change artifacts, authoritative contracts, production entry points, migrations, and tests without copying large code listings or complete requirements

#### Scenario: An iteration has no useful learning delta
- **WHEN** a maintenance change introduces no new server concept, trade-off, failure lesson, or reusable workflow
- **THEN** the change records an explicit learning-note exemption instead of creating an empty or repetitive tutorial

### Requirement: Change planning uses one monorepo OpenSpec workspace
Client, server, shared-contract, and cross-cutting changes SHALL be discoverable from the repository's root OpenSpec workspace. The scope of each change SHALL be evident from its name, proposal, and affected capabilities.

#### Scenario: Contributor lists active changes from the repository root
- **WHEN** the contributor runs the OpenSpec change listing at the monorepo root
- **THEN** all active client, server, and shared changes are visible in the result

#### Scenario: Existing nested change history is consolidated
- **WHEN** a change is migrated from a nested OpenSpec workspace
- **THEN** its artifacts and history remain available under the root workspace without silently overwriting a change with the same name

### Requirement: Documentation migration preserves meaning and navigation
Reorganizing existing documents SHALL preserve their authoritative content, repair repository-relative links, and provide redirects or explicit mapping where a frequently referenced path changes. The migration MUST NOT silently alter product requirements.

#### Scenario: Existing requirement document is relocated
- **WHEN** a product or client document moves to its classified destination
- **THEN** its content remains semantically equivalent and all indexes and repository instructions point to the new location

#### Scenario: Migration reveals mixed ownership
- **WHEN** one existing document contains both client implementation rules and shared server-relevant behavior
- **THEN** the migration extracts a single authoritative shared contract and leaves project-specific implementation guidance in its corresponding scope

