# ``IronComponents``

Composed UI elements for common interface patterns.

## Overview

IronComponents builds on IronPrimitives to provide higher-level UI patterns. These components combine multiple primitives into cohesive, reusable elements that solve common interface challenges.

@Row {
  @Column {
    ![Avatar with status badges](iron-avatar-badges)
  }
  @Column {
    ![Chip variants](iron-chip-variants)
  }
  @Column {
    ![Segmented control](iron-segmented-control)
  }
}

All components support:
- Dynamic Type scaling
- VoiceOver accessibility
- Light and dark mode
- Theme token integration

## Topics

### User Representation

Display user identity with images, initials, and status indicators.

![Avatar sizes and status badges](iron-avatar-sizes)

- ``IronAvatar``

### Selection and Filtering

Tags, chips, and segmented controls for selection interactions.

@Row {
  @Column {
    ![Chip variants](iron-chip-variants)
  }
  @Column {
    ![Segmented control](iron-segmented-control)
  }
}

- ``IronChip``
- ``IronSegmentedControl``

### Menus and Actions

Dropdown menus with sections and keyboard shortcuts.

![Menu trigger](iron-menu-trigger)

- ``IronMenu``
- ``IronMenuItem``
- ``IronMenuSection``

### Loading States

Skeleton placeholders with shimmer animation.

![Skeleton card loading state](iron-skeleton)

- ``IronSkeleton``
