# DocC Unification Workstream

## Goals

- Provide a single, unified documentation site for all modules.
- Preserve module-specific tutorials and resources.
- Avoid manual file merging where possible.

## Current State

- `Scripts/generate-docs.sh` runs DocC per module and merges output folders.
- Navigation and tutorial data are manually copied into `docs/`.

## Forum Findings (Quick Summary)

- Combined docs are experimental and enabled via
  `swift package generate-documentation --enable-experimental-combined-documentation`.
- The combined navigation and package-level landing page require the latest
  Swift-DocC Plugin and (currently) a Swift development toolchain.
- `preview-documentation` does not support the combined-docs flag yet.
- To view combined docs locally, host the output with a simple HTTP server
  (for example `python -m http.server -d <doc-output>`).
- SPI appears to use the preview/documentation pipeline, which can omit
  re-exported symbols without the experimental combined docs flag.

## Proposed Approach

1. Research combined documentation support in DocC
   - Evaluate Swift forums guidance for multi-module docs.
   - Determine if combined docs can replace manual merging.
2. Prototype
   - Create a minimal multi-target DocC build in a temporary branch.
   - Validate sidebar navigation and inter-module links.
3. Decide
   - If combined docs are viable, replace the merge script.
   - If not, formalize the existing merge process and document it.

## Risks

- Combined docs may not support all module metadata or tutorials.
- Static hosting might require custom transforms.

## Next Actions

- Review the Swift forums threads on combined DocC documentation.
- Identify any gaps in current manual merging (missing images, tutorials).
- Draft a short ADR with the chosen approach.
- Prototype combined docs with:
  `swift package generate-documentation --enable-experimental-combined-documentation --target IronCore --target IronPrimitives --target IronComponents --target IronLayouts --target IronNavigation --target IronForms --target IronDataDisplay --target IronUI --output-path docs`

## Prototype Results (2025-12-23)

- Command used:
  `swift package generate-documentation --enable-experimental-combined-documentation --target IronCore --target IronPrimitives --target IronComponents --target IronLayouts --target IronNavigation --target IronForms --target IronDataDisplay --target IronUI --disable-indexing --transform-for-static-hosting --hosting-base-path IronUI --output-path /tmp/ironui-docs-combined`
- Output produced a single combined site with 8 modules in the index.
- Local hosting works with:
  `python -m http.server -d /tmp/ironui-docs-combined`
- Warnings surfaced for missing `@Image` directives in tutorial `@Chapter` blocks:
  `Sources/IronNavigation/Documentation.docc/Tutorials/IronNavigationTutorials.tutorial`
  `Sources/IronDataDisplay/Documentation.docc/Tutorials/IronDataDisplayTutorials.tutorial`
- Attempting to write output inside the repo path returned a permission error.
  Outputting to `/tmp` succeeded.
