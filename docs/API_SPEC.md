# API Specification

## Base URL
```
Production: https://api.projecthub.io/api/v1
Development: http://localhost:3001/api/v1
```

## Authentication

All endpoints (except `/auth/*`) require Bearer token in Authorization header:
```
Authorization: Bearer <jwt_token>
```

---

## Auth Endpoints

### POST /auth/register
Register new user

**Request**:
```json
{
  "email": "user@example.com",
  "password": "SecurePassword123!",
  "firstName": "John",
  "lastName": "Doe"
}
```

**Response** (201):
```json
{
  "id": "uuid",
  "email": "user@example.com",
  "firstName": "John",
  "lastName": "Doe",
  "token": "jwt_token",
  "refreshToken": "refresh_token"
}
```

### POST /auth/login
Authenticate user

**Request**:
```json
{
  "email": "user@example.com",
  "password": "SecurePassword123!"
}
```

**Response** (200):
```json
{
  "id": "uuid",
  "email": "user@example.com",
  "token": "jwt_token",
  "refreshToken": "refresh_token"
}
```

### POST /auth/refresh
Refresh JWT token

**Request**:
```json
{
  "refreshToken": "refresh_token"
}
```

**Response** (200):
```json
{
  "token": "new_jwt_token",
  "refreshToken": "new_refresh_token"
}
```

---

## Projects Endpoints

### GET /projects
List all projects

**Query Parameters**:
- `page` (number): Page number (default: 1)
- `limit` (number): Items per page (default: 20, max: 100)
- `status` (string): Filter by status (planning, active, on-hold, completed)
- `category` (string): Filter by category (software, hardware, manufacturing)
- `search` (string): Search by name or description

**Response** (200):
```json
{
  "data": [
    {
      "id": "uuid",
      "name": "Enterprise Platform 2024",
      "slug": "enterprise-platform-2024",
      "description": "Building next-gen platform",
      "category": "software",
      "status": "active",
      "owner": { /* User object */ },
      "startDate": "2024-01-01T00:00:00Z",
      "targetEndDate": "2024-12-31T00:00:00Z",
      "budget": 500000,
      "budgetCurrency": "USD",
      "createdAt": "2024-01-01T00:00:00Z",
      "updatedAt": "2024-01-15T10:30:00Z"
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 45,
    "totalPages": 3
  }
}
```

### POST /projects
Create new project

**Request**:
```json
{
  "name": "Enterprise Platform 2024",
  "description": "Building next-gen platform",
  "category": "software",
  "startDate": "2024-01-01",
  "targetEndDate": "2024-12-31",
  "budget": 500000,
  "budgetCurrency": "USD"
}
```

**Response** (201):
```json
{
  "id": "uuid",
  "name": "Enterprise Platform 2024",
  "slug": "enterprise-platform-2024",
  "status": "planning",
  "createdAt": "2024-01-15T10:30:00Z"
}
```

### GET /projects/:id
Get project details

**Response** (200):
```json
{
  "id": "uuid",
  "name": "Enterprise Platform 2024",
  "tasks": [ /* Array of tasks */ ],
  "sprints": [ /* Array of sprints */ ],
  "members": [ /* Array of team members */ ],
  "documents": [ /* Array of documents */ ]
}
```

### PUT /projects/:id
Update project

**Request**:
```json
{
  "name": "Enterprise Platform 2024 (Updated)",
  "status": "active",
  "budget": 550000
}
```

**Response** (200): Updated project object

### DELETE /projects/:id
Delete project (soft delete)

**Response** (204): No content

---

## Tasks Endpoints

### GET /projects/:projectId/tasks
List tasks for project

**Query Parameters**:
- `sprintId` (uuid): Filter by sprint
- `status` (string): Filter by status
- `priority` (string): Filter by priority
- `assignedTo` (uuid): Filter by assignee
- `page` (number): Pagination
- `limit` (number): Items per page

**Response** (200): Array of Task objects

### POST /projects/:projectId/tasks
Create new task

**Request**:
```json
{
  "title": "Design system foundation",
  "description": "Create core design tokens and components",
  "type": "feature",
  "priority": "high",
  "storyPoints": 13,
  "sprintId": "uuid",
  "assignedToId": "uuid",
  "startDate": "2024-01-15",
  "endDate": "2024-02-15"
}
```

**Response** (201): Created Task object

### PUT /projects/:projectId/tasks/:taskId
Update task

**Request**:
```json
{
  "status": "in-progress",
  "progressPercentage": 45,
  "actualHours": 12.5
}
```

**Response** (200): Updated Task object

### PATCH /projects/:projectId/tasks/:taskId
Partial update task

**Request**:
```json
{
  "status": "done"
}
```

**Response** (200): Updated Task object

### DELETE /projects/:projectId/tasks/:taskId
Delete task

**Response** (204): No content

---

## Sprints Endpoints

### GET /projects/:projectId/sprints
List sprints

**Response** (200): Array of Sprint objects

### POST /projects/:projectId/sprints
Create sprint

**Request**:
```json
{
  "name": "Sprint 1",
  "goal": "Core API development",
  "startDate": "2024-01-15",
  "endDate": "2024-01-29",
  "capacityHours": 160
}
```

**Response** (201): Created Sprint object

### POST /projects/:projectId/sprints/:sprintId/start
Start sprint

**Response** (200): Updated Sprint object with status "active"

### POST /projects/:projectId/sprints/:sprintId/close
Close sprint

**Response** (200): Updated Sprint object with status "completed"

---

## Documents Endpoints

### GET /projects/:projectId/documents
List documents

**Query Parameters**:
- `category` (string): Filter by category
- `isPublished` (boolean): Filter published status
- `search` (string): Full-text search

**Response** (200): Array of Document objects

### POST /projects/:projectId/documents
Create document

**Request**:
```json
{
  "title": "API Design Guidelines",
  "content": "Markdown content...",
  "category": "specification",
  "isPublished": false
}
```

**Response** (201): Created Document object

### GET /projects/:projectId/documents/search
Search documents (full-text)

**Query Parameters**:
- `q` (string, required): Search query
- `limit` (number): Max results (default: 20)

**Response** (200):
```json
{
  "results": [
    {
      "id": "uuid",
      "title": "API Design Guidelines",
      "snippet": "...matching context...",
      "score": 0.95
    }
  ]
}
```

### PUT /projects/:projectId/documents/:docId
Update document

**Request**:
```json
{
  "title": "API Design Guidelines v2",
  "content": "Updated markdown...",
  "isPublished": true
}
```

**Response** (200): Updated Document object

### DELETE /projects/:projectId/documents/:docId
Delete document

**Response** (204): No content

---

## Files Endpoints

### POST /files/upload
Upload file

**Content-Type**: multipart/form-data

**Form Fields**:
- `file` (File): File to upload
- `projectId` (uuid): Associated project
- `category` (string): File category (cad, specification, attachment)
- `description` (string, optional): File description

**Response** (201):
```json
{
  "id": "uuid",
  "fileName": "design.step",
  "fileSize": 2048576,
  "s3Url": "https://s3.amazonaws.com/...",
  "createdAt": "2024-01-15T10:30:00Z"
}
```

### GET /files/:fileId/download
Download file

**Response** (200): File stream

### DELETE /files/:fileId
Delete file

**Response** (204): No content

---

## Error Responses

### 400 Bad Request
```json
{
  "statusCode": 400,
  "message": "Validation failed",
  "errors": [
    {
      "field": "email",
      "message": "Invalid email format"
    }
  ]
}
```

### 401 Unauthorized
```json
{
  "statusCode": 401,
  "message": "Unauthorized - Invalid or missing token"
}
```

### 403 Forbidden
```json
{
  "statusCode": 403,
  "message": "Forbidden - Insufficient permissions"
}
```

### 404 Not Found
```json
{
  "statusCode": 404,
  "message": "Resource not found"
}
```

### 409 Conflict
```json
{
  "statusCode": 409,
  "message": "Resource already exists"
}
```

### 429 Too Many Requests
```json
{
  "statusCode": 429,
  "message": "Rate limit exceeded",
  "retryAfter": 60
}
```

### 500 Internal Server Error
```json
{
  "statusCode": 500,
  "message": "Internal server error",
  "requestId": "req-uuid"
}
```

---

## WebSocket Events

### Real-Time Task Updates

**Server → Client**:
```javascript
socket.on('task:created', (task) => {})
socket.on('task:updated', (task) => {})
socket.on('task:deleted', (taskId) => {})
socket.on('task:moved', (payload) => {}) // { taskId, column, position }
```

**Client → Server**:
```javascript
socket.emit('task:update', task)
socket.emit('task:move', { taskId, column, position })
```

### Presence Tracking

**Server → Client**:
```javascript
socket.on('presence:changed', (users) => {})
```

**Client → Server**:
```javascript
socket.emit('presence:update', {
  projectId: 'uuid',
  position: { x: 100, y: 200 }
})
```

### Document Collaboration

**Server → Client**:
```javascript
socket.on('document:changed', (delta) => {})
socket.on('document:user:joined', (user) => {})
socket.on('document:user:left', (userId) => {})
```

**Client → Server**:
```javascript
socket.emit('document:change', { docId, delta })
```

---

## Rate Limiting

Rate limits per user:
- **GET requests**: 1000/hour
- **POST requests**: 500/hour
- **PUT/PATCH requests**: 500/hour
- **DELETE requests**: 100/hour
- **File uploads**: 50/hour

Rate limit headers in response:
```
X-RateLimit-Limit: 1000
X-RateLimit-Remaining: 999
X-RateLimit-Reset: 1705334400
```

---

## Pagination

All list endpoints support pagination:

**Query Parameters**:
- `page` (number, default: 1)
- `limit` (number, default: 20, max: 100)
- `sortBy` (string): Field to sort by
- `sortOrder` (string): 'asc' or 'desc'

**Response Format**:
```json
{
  "data": [ /* Items */ ],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 150,
    "totalPages": 8,
    "hasNextPage": true,
    "hasPrevPage": false
  }
}
```

---

## Version History

- **v1.0.0** (2024-01-15): Initial API specification
- **v1.1.0** (planned): GraphQL support
- **v2.0.0** (planned): Advanced features (AI insights, plugins)

---

**Last Updated**: July 20, 2026
**Specification Version**: 1.0.0
**Status**: Live
