# ``IronDataDisplay``

Components for visualizing structured data.

## Overview

IronDataDisplay provides rich components for presenting complex data in intuitive, interactive formats. These components support large datasets and provide built-in interactions like drag-and-drop, selection, and inline editing.

@Row {
  @Column {
    ![Timeline component](iron-timeline)
  }
  @Column {
    ![Kanban board](iron-kanban)
  }
}

## Topics

### Timeline

Display chronological events with customizable layouts.

![Timeline with leading layout](iron-timeline)

- ``IronTimeline``
- ``IronTimelineEntry``
- ``IronTimelineLayout``
- ``IronTimelineNodeSize``
- ``IronTimelineConnectorStyle``

### Kanban Board

Organize items into columns with drag-and-drop support.

![Kanban board with columns](iron-kanban)

- ``IronKanban``
- ``IronKanbanCard``
- ``IronKanbanPriority``
- ``IronKanbanSpacing``

### Database Tables

Notion-style database views with multiple column types.

![Database table](iron-database)

- ``IronDatabase``
- ``IronDatabaseTable``
- ``IronDatabaseCell``
