-- ============================================================================
-- ENTERPRISE PROJECT MANAGEMENT PLATFORM - DATABASE SCHEMA
-- ============================================================================
-- PostgreSQL 14+
-- Run with: psql -U postgres < DATABASE_SCHEMA.sql

-- Enable extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";
CREATE EXTENSION IF NOT EXISTS "jsonb_agg";

-- ============================================================================
-- USERS & AUTHENTICATION
-- ============================================================================

CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  email VARCHAR(255) UNIQUE NOT NULL,
  username VARCHAR(100) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  first_name VARCHAR(100),
  last_name VARCHAR(100),
  avatar_url TEXT,
  role VARCHAR(50) DEFAULT 'member', -- admin, manager, engineer, viewer
  department VARCHAR(100), -- Software, Hardware, Manufacturing, etc.
  is_active BOOLEAN DEFAULT TRUE,
  last_login TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_username ON users(username);

-- ============================================================================
-- ORGANIZATIONS & TEAMS
-- ============================================================================

CREATE TABLE organizations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name VARCHAR(255) UNIQUE NOT NULL,
  slug VARCHAR(100) UNIQUE NOT NULL,
  description TEXT,
  logo_url TEXT,
  website TEXT,
  owner_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE teams (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  name VARCHAR(255) NOT NULL,
  description TEXT,
  lead_id UUID REFERENCES users(id),
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(organization_id, name)
);

CREATE TABLE team_members (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  team_id UUID NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  role VARCHAR(50) DEFAULT 'member', -- lead, member
  joined_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(team_id, user_id)
);

-- ============================================================================
-- PROJECTS (Engineering + Software)
-- ============================================================================

CREATE TABLE projects (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  name VARCHAR(255) NOT NULL,
  slug VARCHAR(100) NOT NULL,
  description TEXT,
  category VARCHAR(50) NOT NULL, -- 'software', 'hardware', 'manufacturing'
  status VARCHAR(50) DEFAULT 'planning', -- planning, active, on-hold, completed
  start_date DATE,
  target_end_date DATE,
  owner_id UUID NOT NULL REFERENCES users(id),
  lead_id UUID REFERENCES users(id),
  budget DECIMAL(15, 2),
  budget_currency VARCHAR(10) DEFAULT 'USD',
  visibility VARCHAR(50) DEFAULT 'private', -- private, internal, public
  metadata JSONB, -- Custom fields, CAD file refs, etc.
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(organization_id, slug)
);

CREATE INDEX idx_projects_organization ON projects(organization_id);
CREATE INDEX idx_projects_status ON projects(status);
CREATE INDEX idx_projects_owner ON projects(owner_id);

-- ============================================================================
-- TASKS & WORK ITEMS
-- ============================================================================

CREATE TABLE tasks (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  parent_task_id UUID REFERENCES tasks(id) ON DELETE CASCADE, -- Subtasks
  title VARCHAR(255) NOT NULL,
  description TEXT,
  type VARCHAR(50), -- 'feature', 'bug', 'task', 'milestone', 'epic'
  status VARCHAR(50) DEFAULT 'todo', -- todo, in-progress, in-review, done, blocked
  priority VARCHAR(50) DEFAULT 'medium', -- critical, high, medium, low
  
  -- Agile (Kanban)
  sprint_id UUID,
  kanban_column VARCHAR(50), -- for Kanban view
  story_points INT,
  
  -- Waterfall (Gantt)
  start_date DATE,
  end_date DATE,
  planned_duration_days INT,
  actual_duration_days INT,
  progress_percentage INT DEFAULT 0,
  
  -- Assignment
  assigned_to_id UUID REFERENCES users(id),
  created_by_id UUID NOT NULL REFERENCES users(id),
  
  -- Estimation & Tracking
  estimated_hours DECIMAL(10, 2),
  actual_hours DECIMAL(10, 2),
  
  -- Hardware/Manufacturing
  bom_id UUID, -- Bill of Materials reference
  cad_file_id UUID, -- File storage reference
  critical_path_flag BOOLEAN DEFAULT FALSE,
  
  -- Metadata
  tags JSONB, -- Array of tag strings
  custom_fields JSONB,
  
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  deleted_at TIMESTAMP -- Soft delete
);

CREATE INDEX idx_tasks_project ON tasks(project_id);
CREATE INDEX idx_tasks_status ON tasks(status);
CREATE INDEX idx_tasks_assigned_to ON tasks(assigned_to_id);
CREATE INDEX idx_tasks_parent ON tasks(parent_task_id);
CREATE INDEX idx_tasks_sprint ON tasks(sprint_id);
CREATE INDEX idx_tasks_dates ON tasks(start_date, end_date);

-- ============================================================================
-- TASK DEPENDENCIES
-- ============================================================================

CREATE TABLE task_dependencies (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  source_task_id UUID NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
  target_task_id UUID NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
  dependency_type VARCHAR(50) NOT NULL, -- 'finish-to-start', 'start-to-start', 'finish-to-finish', 'start-to-finish'
  lag_days INT DEFAULT 0, -- Buffer days
  created_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(source_task_id, target_task_id, dependency_type),
  CHECK (source_task_id != target_task_id)
);

CREATE INDEX idx_task_deps_source ON task_dependencies(source_task_id);
CREATE INDEX idx_task_deps_target ON task_dependencies(target_task_id);

-- ============================================================================
-- SPRINTS (Agile)
-- ============================================================================

CREATE TABLE sprints (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  name VARCHAR(255) NOT NULL,
  goal TEXT,
  status VARCHAR(50) DEFAULT 'planning', -- planning, active, completed
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  capacity_hours INT,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(project_id, name)
);

CREATE INDEX idx_sprints_project ON sprints(project_id);
CREATE INDEX idx_sprints_status ON sprints(status);

-- ============================================================================
-- DOCUMENTS & KNOWLEDGE BASE
-- ============================================================================

CREATE TABLE documents (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  parent_doc_id UUID REFERENCES documents(id) ON DELETE CASCADE, -- Hierarchy
  title VARCHAR(255) NOT NULL,
  slug VARCHAR(100) NOT NULL,
  content TEXT,
  content_html TEXT,
  category VARCHAR(100), -- 'specification', 'guide', 'meeting-notes', 'cad-guide', etc.
  author_id UUID NOT NULL REFERENCES users(id),
  version_number INT DEFAULT 1,
  is_published BOOLEAN DEFAULT FALSE,
  
  -- Search optimization
  search_vector TSVECTOR,
  
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  published_at TIMESTAMP,
  UNIQUE(project_id, slug)
);

CREATE INDEX idx_documents_project ON documents(project_id);
CREATE INDEX idx_documents_category ON documents(category);
CREATE INDEX idx_documents_author ON documents(author_id);
CREATE INDEX idx_documents_search ON documents USING GIN(search_vector);

-- ============================================================================
-- DOCUMENT VERSIONS & REVISIONS
-- ============================================================================

CREATE TABLE document_versions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  document_id UUID NOT NULL REFERENCES documents(id) ON DELETE CASCADE,
  version_number INT NOT NULL,
  content TEXT NOT NULL,
  change_summary VARCHAR(500),
  author_id UUID NOT NULL REFERENCES users(id),
  created_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(document_id, version_number)
);

CREATE INDEX idx_doc_versions_document ON document_versions(document_id);

-- ============================================================================
-- FILES & ATTACHMENTS
-- ============================================================================

CREATE TABLE files (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  uploaded_by_id UUID NOT NULL REFERENCES users(id),
  
  file_name VARCHAR(255) NOT NULL,
  file_type VARCHAR(50), -- 'pdf', 'dwg', 'stp', 'jpg', etc.
  file_size_bytes BIGINT,
  s3_key VARCHAR(500) NOT NULL, -- S3 storage path
  s3_url TEXT,
  
  category VARCHAR(100), -- 'cad', 'specification', 'attachment', 'photo'
  description TEXT,
  
  -- CAD Metadata
  cad_metadata JSONB, -- { "format": "STEP", "dimensions": {...} }
  
  -- Versioning
  version_number INT DEFAULT 1,
  is_current BOOLEAN DEFAULT TRUE,
  
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  deleted_at TIMESTAMP
);

CREATE INDEX idx_files_project ON files(project_id);
CREATE INDEX idx_files_category ON files(category);
CREATE INDEX idx_files_uploaded_by ON files(uploaded_by_id);

-- ============================================================================
-- FILE REFERENCES (Many-to-Many)
-- ============================================================================

CREATE TABLE file_references (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  file_id UUID NOT NULL REFERENCES files(id) ON DELETE CASCADE,
  referenced_by_type VARCHAR(50) NOT NULL, -- 'task', 'document', 'comment'
  referenced_by_id UUID NOT NULL,
  created_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(file_id, referenced_by_type, referenced_by_id)
);

-- ============================================================================
-- COMMENTS & DISCUSSIONS
-- ============================================================================

CREATE TABLE comments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  
  -- Polymorphic reference
  target_type VARCHAR(50) NOT NULL, -- 'task', 'document', 'file'
  target_id UUID NOT NULL,
  
  author_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  parent_comment_id UUID REFERENCES comments(id) ON DELETE CASCADE,
  
  content TEXT NOT NULL,
  content_html TEXT,
  
  is_pinned BOOLEAN DEFAULT FALSE,
  mention_user_ids JSONB, -- Array of user UUIDs mentioned
  
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  deleted_at TIMESTAMP
);

CREATE INDEX idx_comments_target ON comments(target_type, target_id);
CREATE INDEX idx_comments_author ON comments(author_id);
CREATE INDEX idx_comments_parent ON comments(parent_comment_id);

-- ============================================================================
-- ACTIVITY LOG & AUDIT TRAIL
-- ============================================================================

CREATE TABLE activity_log (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id),
  
  entity_type VARCHAR(50) NOT NULL, -- 'task', 'document', 'file', 'comment'
  entity_id UUID NOT NULL,
  action VARCHAR(50) NOT NULL, -- 'created', 'updated', 'deleted', 'moved', 'commented'
  
  change_details JSONB, -- { "field": "status", "from": "todo", "to": "in-progress" }
  
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_activity_project ON activity_log(project_id);
CREATE INDEX idx_activity_user ON activity_log(user_id);
CREATE INDEX idx_activity_entity ON activity_log(entity_type, entity_id);
CREATE INDEX idx_activity_created ON activity_log(created_at);

-- ============================================================================
-- NOTIFICATIONS
-- ============================================================================

CREATE TABLE notifications (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  
  title VARCHAR(255) NOT NULL,
  message TEXT,
  notification_type VARCHAR(50), -- 'task_assigned', 'comment_mention', 'task_due_soon', etc.
  
  target_type VARCHAR(50), -- 'task', 'document'
  target_id UUID,
  
  is_read BOOLEAN DEFAULT FALSE,
  read_at TIMESTAMP,
  
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_notifications_user ON notifications(user_id, is_read);
CREATE INDEX idx_notifications_created ON notifications(created_at);

-- ============================================================================
-- PROJECT PERMISSIONS
-- ============================================================================

CREATE TABLE project_permissions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  team_id UUID REFERENCES teams(id) ON DELETE CASCADE,
  
  can_view BOOLEAN DEFAULT FALSE,
  can_edit BOOLEAN DEFAULT FALSE,
  can_delete BOOLEAN DEFAULT FALSE,
  can_manage_access BOOLEAN DEFAULT FALSE,
  can_create_tasks BOOLEAN DEFAULT FALSE,
  can_create_documents BOOLEAN DEFAULT FALSE,
  
  granted_at TIMESTAMP DEFAULT NOW(),
  
  CHECK ((user_id IS NOT NULL AND team_id IS NULL) OR (user_id IS NULL AND team_id IS NOT NULL))
);

CREATE INDEX idx_permissions_project ON project_permissions(project_id);
CREATE INDEX idx_permissions_user ON project_permissions(user_id);
CREATE INDEX idx_permissions_team ON project_permissions(team_id);

-- ============================================================================
-- BILL OF MATERIALS (Hardware/Manufacturing)
-- ============================================================================

CREATE TABLE bill_of_materials (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  version_number INT DEFAULT 1,
  name VARCHAR(255) NOT NULL,
  description TEXT,
  
  created_by_id UUID NOT NULL REFERENCES users(id),
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(project_id, name, version_number)
);

CREATE TABLE bom_items (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  bom_id UUID NOT NULL REFERENCES bill_of_materials(id) ON DELETE CASCADE,
  
  part_number VARCHAR(100),
  part_name VARCHAR(255) NOT NULL,
  description TEXT,
  category VARCHAR(100), -- 'pcb', 'connector', 'fastener', 'material'
  
  quantity INT NOT NULL,
  unit VARCHAR(50), -- 'pcs', 'kg', 'meter'
  unit_cost DECIMAL(15, 4),
  currency VARCHAR(10) DEFAULT 'USD',
  
  supplier VARCHAR(255),
  lead_time_days INT,
  is_critical BOOLEAN DEFAULT FALSE,
  
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_bom_items_bom ON bom_items(bom_id);

-- ============================================================================
-- CREATE TRIGGERS FOR AUDIT & SEARCH
-- ============================================================================

-- Update search vector on document changes
CREATE OR REPLACE FUNCTION document_search_update() RETURNS TRIGGER AS $$
BEGIN
  NEW.search_vector := to_tsvector('english', COALESCE(NEW.title, '') || ' ' || COALESCE(NEW.content, ''));
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER document_search_trigger
BEFORE INSERT OR UPDATE ON documents
FOR EACH ROW EXECUTE FUNCTION document_search_update();

-- Auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_timestamp() RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER users_update_timestamp BEFORE UPDATE ON users FOR EACH ROW EXECUTE FUNCTION update_timestamp();
CREATE TRIGGER projects_update_timestamp BEFORE UPDATE ON projects FOR EACH ROW EXECUTE FUNCTION update_timestamp();
CREATE TRIGGER tasks_update_timestamp BEFORE UPDATE ON tasks FOR EACH ROW EXECUTE FUNCTION update_timestamp();
CREATE TRIGGER documents_update_timestamp BEFORE UPDATE ON documents FOR EACH ROW EXECUTE FUNCTION update_timestamp();

-- ============================================================================
-- VIEWS FOR COMMON QUERIES
-- ============================================================================

-- View: Project Summary
CREATE VIEW project_summary AS
SELECT 
  p.id,
  p.name,
  p.status,
  COUNT(DISTINCT t.id) as total_tasks,
  COUNT(DISTINCT CASE WHEN t.status = 'done' THEN t.id END) as completed_tasks,
  COUNT(DISTINCT CASE WHEN t.status = 'in-progress' THEN t.id END) as in_progress_tasks,
  COUNT(DISTINCT CASE WHEN t.status = 'blocked' THEN t.id END) as blocked_tasks,
  AVG(t.progress_percentage) as avg_progress,
  p.updated_at
FROM projects p
LEFT JOIN tasks t ON p.id = t.project_id AND t.deleted_at IS NULL
GROUP BY p.id, p.name, p.status, p.updated_at;

-- View: User Task Load
CREATE VIEW user_task_load AS
SELECT 
  u.id,
  u.username,
  u.email,
  COUNT(DISTINCT t.id) as assigned_tasks,
  COUNT(DISTINCT CASE WHEN t.status != 'done' THEN t.id END) as active_tasks,
  SUM(COALESCE(t.estimated_hours, 0)) as total_estimated_hours,
  SUM(COALESCE(t.actual_hours, 0)) as total_actual_hours
FROM users u
LEFT JOIN tasks t ON u.id = t.assigned_to_id AND t.deleted_at IS NULL AND t.status != 'done'
GROUP BY u.id, u.username, u.email;

-- ============================================================================
-- PERFORMANCE INDEXES
-- ============================================================================

CREATE INDEX idx_tasks_status_assigned ON tasks(status, assigned_to_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_tasks_project_status ON tasks(project_id, status) WHERE deleted_at IS NULL;
CREATE INDEX idx_sprints_project_status ON sprints(project_id, status);
CREATE INDEX idx_documents_published ON documents(project_id, is_published);

-- ============================================================================
-- END OF SCHEMA
-- ============================================================================

COMMENT ON TABLE projects IS 'Unified projects for software and hardware/manufacturing';
COMMENT ON TABLE tasks IS 'Work items supporting both Agile (Kanban/Sprint) and Waterfall (Gantt) methodologies';
COMMENT ON TABLE task_dependencies IS 'Critical path analysis for Gantt charts';
COMMENT ON TABLE documents IS 'Knowledge base with full-text search support';
COMMENT ON TABLE bill_of_materials IS 'Hardware components and procurement tracking';
