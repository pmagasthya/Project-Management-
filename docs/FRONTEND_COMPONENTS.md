# Frontend Components Documentation

## Overview

This document describes the core React components used in the Project Management Platform's Command Center dashboard.

## Layout Components

### Sidebar

**Location**: `src/components/Sidebar.tsx`

**Purpose**: Main navigation component with collapsible functionality.

**Features**:
- Navigation to dashboard, projects, kanban, gantt, documents, collaboration
- Collapsible sidebar for extra screen space
- Settings link in footer
- Responsive design (mobile-friendly)

**Props**: None (uses global store)

**State**:
- `sidebarCollapsed` from Zustand store

**Example**:
```tsx
import { Sidebar } from '@/components/Sidebar';

<Sidebar />
```

### Header

**Location**: `src/components/Header.tsx`

**Purpose**: Top navigation with search, notifications, and user menu.

**Features**:
- Full-text search bar
- Notification bell with dropdown
- User profile menu with logout
- Settings access
- Responsive positioning based on sidebar state

**Props**: None (uses global store)

**Example**:
```tsx
import { Header } from '@/components/Header';

<Header />
```

## Feature Components

### SummaryWidget

**Location**: `src/components/SummaryWidget.tsx`

**Purpose**: Display key project metrics in card format.

**Features**:
- Completed tasks count with trend
- In-progress tasks count
- Blocked tasks count
- Overall completion percentage
- Team size
- Color-coded stat cards

**Props**:
```typescript
interface SummaryWidgetProps {
  project: Project | null;
  metrics: {
    totalTasks: number;
    completedTasks: number;
    inProgressTasks: number;
    blockedTasks: number;
    teamMembers: number;
    completionPercentage: number;
  };
}
```

**Example**:
```tsx
import { SummaryWidget } from '@/components/SummaryWidget';

const metrics = {
  totalTasks: 50,
  completedTasks: 15,
  inProgressTasks: 20,
  blockedTasks: 2,
  teamMembers: 8,
  completionPercentage: 30,
};

<SummaryWidget project={currentProject} metrics={metrics} />
```

### KanbanBoard

**Location**: `src/components/KanbanBoard.tsx`

**Purpose**: Visual Kanban board with 4 columns and drag-and-drop support.

**Features**:
- 4 columns: To Do, In Progress, In Review, Done
- Task cards with priority color coding
- Task count per column
- Draggable task cards (foundation for future DnD implementation)
- Story points display
- Assignee avatars
- Click handlers for task details

**Columns**:
- **To Do** (gray)
- **In Progress** (blue)
- **In Review** (yellow)
- **Done** (green)

**Priority Colors**:
- Critical: Red left border
- High: Orange left border
- Medium: Yellow left border
- Low: Gray left border

**Props**:
```typescript
interface KanbanBoardProps {
  tasks: Task[];
  onTaskUpdate?: (taskId: string, updates: Partial<Task>) => void;
  onTaskClick?: (task: Task) => void;
}
```

**Example**:
```tsx
import { KanbanBoard } from '@/components/KanbanBoard';

<KanbanBoard 
  tasks={tasks}
  onTaskClick={(task) => console.log(task)}
/>
```

### GanttChart

**Location**: `src/components/GanttChart.tsx`

**Purpose**: Timeline-based task visualization with dependency tracking.

**Features**:
- Month/week/day granularity
- Task bars with custom colors based on status
- Critical path highlighting (orange)
- Blocked tasks visualization (red with stripes)
- Task dependencies (foundation)
- Hover tooltips with task title
- Left sidebar with task names and status indicators
- Horizontal scrolling timeline

**Color Coding**:
- **Blue**: Normal tasks in progress
- **Green**: Completed tasks
- **Orange**: Critical path tasks
- **Red (striped)**: Blocked tasks

**Props**:
```typescript
interface GanttChartProps {
  tasks: Task[];
  startDate: Date;
  endDate: Date;
  granularity: 'month' | 'week' | 'day';
  onTaskClick?: (task: Task) => void;
}
```

**Example**:
```tsx
import { GanttChart } from '@/components/GanttChart';
import { subMonths, addMonths } from 'date-fns';

<GanttChart
  tasks={tasks}
  startDate={subMonths(new Date(), 1)}
  endDate={addMonths(new Date(), 6)}
  granularity="week"
  onTaskClick={(task) => console.log(task)}
/>
```

## Page Components

### Dashboard Layout

**Location**: `src/app/dashboard/layout.tsx`

**Purpose**: Main layout wrapper for dashboard pages.

**Structure**:
```
DashboardLayout
├── Sidebar
├── Header
└── MainContent
    └── {children}
```

**Features**:
- Responsive grid layout
- Sidebar collapse integration
- Fixed header
- Scrollable content area
- Safe area padding

### Dashboard Page

**Location**: `src/app/dashboard/page.tsx`

**Purpose**: Main command center with split Kanban/Gantt view.

**Features**:
- View mode selection (Kanban, Gantt, Split)
- Summary metrics display
- Kanban and Gantt side-by-side in split mode
- Mock data loading
- Real-time metric calculation

**View Modes**:
- **Kanban**: Full-width Kanban board
- **Gantt**: Full-width Gantt chart
- **Split**: 50/50 split (or 60/40 optimized)

**Example**:
```tsx
// Uses mock data for demonstration
import Dashboard from '@/app/dashboard/page';

<Dashboard />
```

## Utility Components

### TaskCard

**Purpose**: Individual task card within Kanban.

**Features**:
- Priority-based left border
- Task title and description
- Task type badge
- Story points display
- Assignee avatar
- Click handler

## Custom Hooks (Future)

### useProject

```typescript
const { project, tasks, loading } = useProject(projectId);
```

### useTasks

```typescript
const { tasks, isLoading, refetch } = useTasks(projectId, filters);
```

### useWebSocket

```typescript
const { isConnected, emit, on } = useWebSocket();
```

## Styling Strategy

### Tailwind CSS

- **Colors**: Enterprise blue palette
- **Spacing**: 4px base unit
- **Borders**: 1px solid gray-200
- **Shadows**: sm, md, lg levels
- **Typography**: Inter font family

### Component Theming

```typescript
const clsx = (...classes) => classes.filter(Boolean).join(' ');

const buttonClass = clsx(
  'rounded-lg px-4 py-2 font-medium transition-colors',
  'bg-primary-600 text-white hover:bg-primary-700'
);
```

## Performance Considerations

### Memoization
- Components with expensive renders use `React.memo`
- Tasks list uses `useMemo` for sorting/filtering
- Kanban columns memoized to prevent re-renders

### Lazy Loading
- Heavy components (Gantt) could use `React.lazy`
- Document list with virtual scrolling (future)

### Code Splitting
- Dashboard page separate from other routes
- Components tree-shaken by Next.js

## Accessibility

- Semantic HTML tags
- ARIA labels for icons
- Keyboard navigation support
- Color contrast compliance
- Focus indicators

## Testing

### Unit Tests
```typescript
test('KanbanBoard renders 4 columns', () => {
  render(<KanbanBoard tasks={[]} />);
  expect(screen.getByText('To Do')).toBeInTheDocument();
});
```

### Integration Tests
```typescript
test('Task click handler fires', () => {
  const mockClick = jest.fn();
  render(<KanbanBoard tasks={mockTasks} onTaskClick={mockClick} />);
  fireEvent.click(screen.getByText('Sample Task'));
  expect(mockClick).toHaveBeenCalled();
});
```

## Future Enhancements

- [ ] Drag-and-drop task reordering (DnD Kit)
- [ ] Task detail modal
- [ ] Inline task editing
- [ ] Bulk operations
- [ ] Custom columns
- [ ] Automated workflows
- [ ] Advanced filtering
- [ ] Export to PDF/CSV
- [ ] Mobile-optimized views
- [ ] Dark mode support

---

**Last Updated**: July 20, 2026
**Component Version**: 1.0.0
