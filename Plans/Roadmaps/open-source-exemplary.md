# IronUI Open-Source Excellence Roadmap

## Goals

- Ship a cohesive, beautiful, and accessible design system.
- Provide unified, high-quality documentation and tutorials.
- Establish reliable CI and testing coverage across all modules.
- Deliver a standout showcase app aligned with the visual identity.

## Non-Goals

- Backwards compatibility for older OS versions.
- Rewriting existing components without a clear quality gap.

## Milestones

1. Documentation Unification
   - Align DocC outputs across modules.
   - Ensure a single navigation experience and unified tutorials.
2. Accessibility & Quality Gates
   - Add automated accessibility audits to CI.
   - Publish accessibility guidance and component-level checklists.
3. Testing Coverage
   - Unit tests for all modules.
   - Snapshot test baselines for interactive states and Dynamic Type.
4. Showcase & Examples
   - A curated demo app with Family/Honkish-inspired flows.
   - Tutorial-driven examples in DocC.

## Risks

- DocC multi-module limitations may require custom tooling.
- Snapshot tests may be brittle across OS/Xcode versions.

## Next Actions

- Build a DocC unification plan (see `Plans/Workstreams/docc-unification.md`).
- Audit test coverage and list missing suites per module.
- Identify missing docs/tutorials for each module.

