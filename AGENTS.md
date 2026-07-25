# Kitchen Notes repository instructions

## Product context

- This repository is a learning-oriented Flutter application for collecting,
  organizing, searching, and cooking from personal recipes.
- Read `docs/MVP_REQUIREMENTS.md` before changing product behavior.
- Read `docs/CODEX_WORKFLOW.md` when the task is intended to teach a Codex
  workflow.
- The working product name and bundle identifiers are temporary unless the user
  explicitly finalizes them.

## Learning objective

- Treat architecture decisions as part of the deliverable. In the final
  response, briefly explain the boundary, pattern, or Flutter mechanism that the
  change demonstrates.
- Prefer a small, reviewable implementation that teaches one concept clearly.
- Do not hide meaningful architecture behind generated boilerplate.

## Target component architecture

The repository is migrating from the current single-package feature-first
structure to a multi-package Flutter workspace. Keep dependencies directed:

```text
app
├── feature_* ──> recipe_domain
├── recipe_data ─> recipe_domain
├── design_system
└── app_core
```

Target packages:

- `app_core`: shared result types, failures, logging abstractions, and utilities.
- `design_system`: themes, tokens, reusable presentational components, and
  accessibility conventions.
- `recipe_domain`: entities, repository contracts, use cases, and domain events.
- `recipe_data`: Drift tables, migrations, mappers, OCR/AI adapters, and
  repository implementations.
- `feature_home`
- `feature_recipe_library`
- `feature_recipe_editor`
- `feature_import`
- `feature_cooking`
- The app package is the composition root and owns routing, dependency wiring,
  and cross-feature coordination.

### Boundary rules

- A feature package must not import another feature package.
- Presentation code must not import Drift-generated rows or database classes.
- Domain packages must not depend on Flutter, Drift, platform plugins, or HTTP
  clients.
- Data packages implement interfaces declared by the domain package.
- Reusable visual components belong in `design_system`; feature-specific
  widgets stay inside their feature.
- Keep package public APIs small. Export only intentional entry points from a
  package-level library file.
- Do not introduce a global event bus. Communicate through:
  - callbacks for local widget interactions;
  - Riverpod providers for scoped application state and dependency injection;
  - domain use cases and repository streams for business data;
  - typed navigation intents coordinated by the app package;
  - explicit domain events only for asynchronous workflows that truly cross
    feature boundaries.

## State and data rules

- Keep the application local-first. Core recipe browsing and cooking must work
  without a network connection.
- Preserve original imported text and user-edited data separately.
- User edits always take precedence over later AI extraction.
- Cloud AI must be accessed through an abstraction and never directly from a
  widget.
- Never place service API keys in the Flutter client.
- Do not edit generated files such as `*.g.dart` manually.
- When changing Drift tables:
  1. increase the schema version;
  2. add or update a migration;
  3. regenerate code;
  4. add a migration or database test.

## UI rules

- Support both scrapbook and minimal presentation styles without duplicating
  business screens.
- Use design tokens instead of hard-coded feature colors, spacing, typography,
  or radii.
- Keep cooking-mode content highly legible, with large targets and no ads.
- Use Chinese user-facing copy unless the product requirements specify another
  locale.
- Avoid gender-exclusive wording or imagery even though women are the primary
  audience.
- New interactive elements must have meaningful semantics or tooltips where
  appropriate.

## Verification

Run the smallest relevant checks during iteration and all of these before
handing off a completed code change:

```sh
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
```

After changing Drift declarations:

```sh
dart run build_runner build
```

For platform-facing changes, also build or run the affected platform when the
local toolchain is available.

## Change discipline

- Preserve unrelated user changes.
- Do not add a production dependency without explaining what boundary it serves
  and why an existing dependency is insufficient.
- Keep behavior changes and architecture refactors in separate commits when
  practical.
- Update `docs/MVP_REQUIREMENTS.md` when an accepted product requirement changes.
- Update `README.md` when setup, tooling, or top-level structure changes.
- Never commit secrets, signing material, generated build directories, or local
  environment paths.
