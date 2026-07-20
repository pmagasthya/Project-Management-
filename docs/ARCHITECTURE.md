# Enterprise Project Management Platform - System Architecture

## Phase 1: Technology Stack & Microservices Architecture

### 1.1 Frontend Stack
```
Framework: Next.js 14 (React 18) with TypeScript
Styling: Tailwind CSS v3 + shadcn/ui
State Management: TanStack Query (React Query) + Zustand
Real-time: Socket.io Client + WebSocket
Charting: Recharts (Gantt visualization), react-beautiful-dnd (Kanban)
Rich Text: Lexical or TipTap
Testing: Vitest + React Testing Library
Build: Turbopack
```

### 1.2 Backend Stack
```
Runtime: Node.js 20 LTS
Framework: NestJS (TypeScript, enterprise-grade)
API: GraphQL (Apollo Server) + REST (OpenAPI 3.0)
Database ORM: TypeORM (PostgreSQL) + Prisma (fallback)
Message Queue: RabbitMQ or Apache Kafka
Cache: Redis
Authentication: JWT + OAuth2 (Google, GitHub, Microsoft)
File Storage: AWS S3 + Minio
Search: Elasticsearch + PostgreSQL Full-Text Search
```

### 1.3 Database
```
Primary: PostgreSQL 14+ (JSONB, Full-Text Search, Arrays)
Replicas: Read-only replicas for analytics
Cache Layer: Redis (session, real-time updates)
Time-Series: TimescaleDB extension (for burndown charts, metrics)
```

### 1.4 Real-Time Services
```
WebSocket Server: Socket.io or native WebSockets
Message Bus: Redis Pub/Sub for development, RabbitMQ/Kafka for production
Presence System: Redis or custom in-memory store
Collaboration Engine: Operational Transformation (OT) or CRDT (Yjs)
```

### 1.5 Deployment & Infrastructure
```
Containerization: Docker + Docker Compose
Orchestration: Kubernetes (optional scaling)
CI/CD: GitHub Actions + ArgoCD
Monitoring: Prometheus + Grafana + ELK Stack
CDN: CloudFront or Cloudflare
Service Mesh: Istio (optional, for advanced tracing)
```

---

## Phase 1.6: Microservices Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                          API Gateway (Kong/AWS ALB)                 │
│                     (Authentication, Rate Limiting)                 │
└──────────────┬────────────────┬────────────────┬────────────────────┘
               │                │                │
      ┌────────▼─────────┐ ┌───▼──────────────┐ ┌──▼───────────────┐
      │   Auth Service   │ │  Notification    │ │  File Service    │
      │  (JWT, OAuth)    │ │  Service         │ │  (S3 Upload,     │
      │                  │ │  (Real-time)     │ │   CAD Handling)  │
      └──────────────────┘ └──────────────────┘ └──────────────────┘

      ┌─────────────────────────────────────────────────────────────┐
      │           Task & Project Management Service                 │
      │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
      │  │ Kanban Ops   │  │ Gantt Ops    │  │ Task Deps    │      │
      │  │ (Sprints)    │  │ (Critical    │  │ (Graph DB)   │      │
      │  │              │  │  Path)       │  │              │      │
      │  └──────────────┘  └──────────────┘  └──────────────┘      │
      └─────────────────────────────────────────────────────────────┘

      ┌──────────────────────┐    ┌──────────────────────┐
      │  Document Service    │    │  Collaboration       │
      │  (Wiki, Full-Text    │    │  Service             │
      │   Search)            │    │  (Real-time Editing, │
      │                      │    │   Presence)          │
      └──────────────────────┘    └──────────────────────┘

      ┌──────────────────────┐    ┌──────────────────────┐
      │  Reporting Service   │    │  Hardware/BOM        │
      │  (Analytics, BI)     │    │  Service             │
      │                      │    │  (Procurement)       │
      └──────────────────────┘    └──────────────────────┘

┌──────────────────────────────────────────────────────────────────────┐
│                    Shared Services                                   │
│  ┌─────────────────┐ ┌──────────────┐ ┌──────────────────────┐     │
│  │  PostgreSQL     │ │   Redis      │ │  Elasticsearch       │     │
│  │  (Primary DB)   │ │  (Cache/RT)  │ │  (Full-Text Search)  │     │
│  └─────────────────┘ └──────────────┘ └──────────────────────┘     │
│  ┌─────────────────┐ ┌──────────────┐ ┌──────────────────────┐     │
│  │  RabbitMQ/      │ │   AWS S3     │ │  Message Queue       │     │
│  │  Kafka          │ │   (Files)    │ │  (Job Scheduling)    │     │
│  └─────────────────┘ └──────────────┘ └──────────────────────┘     │
└──────────────────────────────────────────────────────────────────────┘
```

---

## Phase 2: Database Schema Highlights

### Key Relationships:
- **Users ↔ Organizations ↔ Teams ↔ Projects**
- **Projects ↔ Tasks** (with hierarchy via parent_task_id)
- **Tasks ↔ Sprints** (Agile tracking)
- **Tasks ↔ Task Dependencies** (Gantt/Critical Path)
- **Projects ↔ Documents** (Knowledge base)
- **Projects ↔ Files** (CAD, specs, attachments)
- **Tasks ↔ Comments** (Discussion threads)

### Critical Design Patterns:
1. **Soft Deletes**: `deleted_at` column prevents data loss
2. **JSONB Metadata**: Flexible custom fields without schema migration
3. **Full-Text Search**: PostgreSQL `tsvector` for document search
4. **Audit Trail**: `activity_log` table tracks all changes
5. **Polymorphic References**: Comments can link to tasks, documents, or files

---

## Phase 3: Frontend Architecture

### Layout & Component Structure:
```
CommandCenter (Main Layout)
├── Sidebar (Navigation + Collapsed Mode)
├── Header (User, Org Switcher, Notifications)
├── TopSummaryWidget (KPIs, Quick Stats)
├── MainContent
│   ├── KanbanView (Left Panel, 60% width)
│   │   ├── Columns: Todo, In Progress, In Review, Done
│   │   ├── Cards: Draggable task cards with priority colors
│   │   └── Sprint filter
│   └── GanttView (Right Panel, 40% width)
│       ├── Timeline (Months/Weeks/Days)
│       ├── Task Bars with dependencies
│       ├── Critical Path highlighting
│       └── Resource allocation
└── Footer (Collaboration hints)
```

### Responsive Strategy:
- **Sidebar**: Collapsible for mobile/tablet
- **Kanban/Gantt**: Stack vertically on screens < 1600px
- **Full width**: > 2560px (ultra-wide monitors optimized)

---

## Phase 4: Backend API Structure

### REST Endpoints (Primary):
```
Projects:
  GET    /api/v1/projects
  POST   /api/v1/projects
  GET    /api/v1/projects/:id
  PUT    /api/v1/projects/:id
  DELETE /api/v1/projects/:id

Tasks:
  GET    /api/v1/projects/:id/tasks
  POST   /api/v1/projects/:id/tasks
  PUT    /api/v1/tasks/:id
  PATCH  /api/v1/tasks/:id (partial updates)
  DELETE /api/v1/tasks/:id

Sprints:
  GET    /api/v1/projects/:id/sprints
  POST   /api/v1/projects/:id/sprints/:sprintId/start
  POST   /api/v1/projects/:id/sprints/:sprintId/close

Documents:
  GET    /api/v1/projects/:id/documents
  POST   /api/v1/projects/:id/documents
  PUT    /api/v1/documents/:id
  GET    /api/v1/documents/search?q=query
```

### GraphQL Schema (Supplementary):
```graphql
type Project {
  id: ID!
  name: String!
  tasks: [Task!]!
  sprints: [Sprint!]!
  documents: [Document!]!
}

type Task {
  id: ID!
  title: String!
  status: TaskStatus!
  dependencies: [Task!]!
  assignedTo: User
  ganttData: GanttData
}
```

---

## Phase 5: Real-Time Features

### WebSocket Events:
```javascript
// Client listens:
socket.on('task:created', (task) => {})
socket.on('task:updated', (task) => {})
socket.on('task:drag', (payload) => {})
socket.on('document:editing', (user) => {})
socket.on('user:presence', (user) => {})

// Client emits:
socket.emit('task:move', { taskId, column, position })
socket.emit('document:change', { docId, delta })
socket.emit('presence:update', { cursorPosition })
```

---

## Phase 6: Scaling Considerations

1. **Horizontal Scaling**: Services behind load balancer
2. **Database Sharding**: By organization_id for massive datasets
3. **Caching Strategy**: Redis for frequently accessed projects/tasks
4. **CDN**: Static assets + document previews
5. **Rate Limiting**: Per-user and per-org quotas
6. **Async Jobs**: Background tasks (reporting, notifications, exports)
7. **Analytics**: Separate read replicas for BI queries

---

## Getting Started

See the following documents:
- **DATABASE_SCHEMA.sql**: Complete PostgreSQL schema
- **Phase3_Frontend_Boilerplate**: React/Next.js dashboard code
- **Architecture_Diagrams**: Visual system overview
- **API_Specification.md**: Detailed REST/GraphQL endpoints
