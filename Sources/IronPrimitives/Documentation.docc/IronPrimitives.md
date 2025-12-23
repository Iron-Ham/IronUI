# ``IronPrimitives``

Basic building blocks for constructing interfaces in IronUI.

## Overview

IronPrimitives provides the foundational UI components that serve as the atomic building blocks for all IronUI interfaces. These components are designed with the Liquid Glass aesthetic and integrate seamlessly with the theming system.

@Row {
  @Column {
    ![Button variants showing filled, outlined, ghost, and elevated styles](iron-button-variants)
  }
  @Column {
    ![Text headline styles](iron-text-headlines)
  }
}

All primitives support:
- Dynamic Type scaling
- VoiceOver accessibility
- Light and dark mode
- Theme token integration

## Topics

### Buttons and Actions

Themed buttons with multiple variants, sizes, and icon support.

@Row {
  @Column(size: 2) {
    ![Button variants](iron-button-variants)
  }
}

- ``IronButton``

### Text and Typography

Typography components with 16 semantic styles.

- ``IronText``
- ``IronIcon``

### Form Controls

Styled form inputs with validation states.

@Row {
  @Column {
    ![TextField states](iron-textfield-states)
  }
  @Column {
    ![Toggle states](iron-toggle-states)
  }
}

- ``IronTextField``
- ``IronSecureField``
- ``IronCheckbox``
- ``IronToggle``
- ``IronRadio``

### Feedback and Status

Progress indicators, spinners, and contextual alerts.

@Row {
  @Column {
    ![Alert variants](iron-alert-variants)
  }
  @Column {
    ![Progress indicators](iron-progress-linear)
  }
}

- ``IronProgress``
- ``IronSpinner``
- ``IronAlert``
- ``IronBadge``

### Layout and Structure

Cards and dividers for organizing content.

- ``IronCard``
- ``IronDivider``
- ``IronContextLine``
