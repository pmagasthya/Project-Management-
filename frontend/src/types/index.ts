export interface User {
  id: string;
  email: string;
  username: string;
  firstName: string;
  lastName: string;
  avatarUrl?: string;
  role: 'admin' | 'manager' | 'engineer' | 'viewer';
  department?: string;
  isActive: boolean;
}

export interface Organization {
  id: string;
  name: string;
  slug: string;
  description?: string;
  logoUrl?: string;
  owner: User;
  createdAt: Date;
}

export type ProjectStatus = 'planning' | 'active' | 'on-hold' | 'completed';

export interface Project {
  id: string;
  organizationId: string;
  name: string;
  slug: string;
  description?: string;
  category: 'software' | 'hardware' | 'manufacturing';
  status: ProjectStatus;
  startDate?: Date;
  targetEndDate?: Date;
  owner: User;
  budget?: number;
  budgetCurrency: string;
  visibility: 'private' | 'internal' | 'public';
  createdAt: Date;
  updatedAt: Date;
}

export type TaskStatus = 'todo' | 'in-progress' | 'in-review' | 'done' | 'blocked';
export type TaskPriority = 'critical' | 'high' | 'medium' | 'low';

export interface Task {
  id: string;
  projectId: string;
  parentTaskId?: string;
  title: string;
  description?: string;
  type: string;
  status: TaskStatus;
  priority: TaskPriority;
  sprintId?: string;
  kanbanColumn?: string;
  storyPoints?: number;
  startDate?: Date;
  endDate?: Date;
  plannedDurationDays?: number;
  progressPercentage: number;
  assignedTo?: User;
  createdBy: User;
  estimatedHours?: number;
  actualHours?: number;
  criticalPathFlag: boolean;
  createdAt: Date;
  updatedAt: Date;
}
