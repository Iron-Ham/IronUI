# ADR-0003: Visual Identity

## Status

Accepted

## Context

IronUI needs a distinctive visual identity that sets it apart from generic component libraries. We want to be:

1. **Modern and stylish** - A bold, contemporary aesthetic
2. **Opinionated by default** - Ships with a distinctive, polished theme out of the box
3. **Themable and customizable** - Consumers can override tokens to match their brand
4. **Cutting-edge in motion design** - Delightful animations that respect accessibility
5. **Accessible** - Never sacrificing usability for aesthetics

## Decision

Adopt a design philosophy inspired by Family and Honkish, centered on five core principles:

### 1. Fluidity Over Statics

- Treat the UI as a constantly evolving space
- Seamless transitions between states (no jarring cuts)
- Elements morph, expand, and contract rather than appear/disappear
- Motion creates visible links between screens

### 2. Progressive Revelation

- Show complexity only when needed
- Dynamic trays and expanding containers
- Respect user's time and cognitive load

### 3. Delight Through Details

- Strategic micro-interactions (not everywhere)
- Delight-Impact Curve: less-used features get more magic
- Tactile, responsive feedback
- Easter eggs for discovery moments

### 4. Semantic Motion & Color

- Colors reinforce meaning (destructive = red feedback)
- Transitions communicate relationships
- Physics-based animations feel natural

### 5. Dimensional Awareness

- Contextual overlays rather than full displacement
- Spatial relationships maintained during navigation
- Depth through subtle shadows and layering

### Default Theme

Ship an opinionated, stylish default theme that embodies these principles:

- Bold, confident primary colors
- Spring-based animations by default
- Generous whitespace (8pt grid)
- Color-tinted shadows for depth
- Morphing transitions for labels/icons

## Consequences

### Positive

- Distinctive visual identity
- Delightful user experience
- Strong foundation for component design decisions
- Memorable brand association

### Negative

- Opinionated default may not suit all projects
- More complex animation implementation
- Higher bar for component quality

### Neutral

- Users can still create neutral themes
- Philosophy guides decisions but doesn't mandate specific implementations

## References

- [Family Values - Design Philosophy](https://benji.org/family-values)
- [Honkish - Design Breakdown](https://benji.org/honkish)
