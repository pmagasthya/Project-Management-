import { create } from 'zustand';
import { User, Project, Organization } from '@/types';

interface AppState {
  // Auth
  currentUser: User | null;
  isAuthenticated: boolean;
  setCurrentUser: (user: User | null) => void;
  
  // Organization & Project
  currentOrganization: Organization | null;
  setCurrentOrganization: (org: Organization | null) => void;
  currentProject: Project | null;
  setCurrentProject: (project: Project | null) => void;
  
  // UI State
  sidebarCollapsed: boolean;
  setSidebarCollapsed: (collapsed: boolean) => void;
  viewMode: 'kanban' | 'gantt' | 'split';
  setViewMode: (mode: 'kanban' | 'gantt' | 'split') => void;
  
  // Filtering
  selectedSprintId: string | null;
  setSelectedSprintId: (sprintId: string | null) => void;
  taskFilterStatus: string[];
  setTaskFilterStatus: (statuses: string[]) => void;
  taskFilterPriority: string[];
  setTaskFilterPriority: (priorities: string[]) => void;
  taskFilterAssignedTo: string | null;
  setTaskFilterAssignedTo: (userId: string | null) => void;
  
  // Gantt Settings
  ganttGranularity: 'month' | 'week' | 'day';
  setGanttGranularity: (granularity: 'month' | 'week' | 'day') => void;
}

export const useAppStore = create<AppState>((set) => ({
  // Auth
  currentUser: null,
  isAuthenticated: false,
  setCurrentUser: (user) => set({ 
    currentUser: user, 
    isAuthenticated: !!user 
  }),
  
  // Organization & Project
  currentOrganization: null,
  setCurrentOrganization: (org) => set({ currentOrganization: org }),
  currentProject: null,
  setCurrentProject: (project) => set({ currentProject: project }),
  
  // UI State
  sidebarCollapsed: false,
  setSidebarCollapsed: (collapsed) => set({ sidebarCollapsed: collapsed }),
  viewMode: 'split',
  setViewMode: (mode) => set({ viewMode: mode }),
  
  // Filtering
  selectedSprintId: null,
  setSelectedSprintId: (sprintId) => set({ selectedSprintId: sprintId }),
  taskFilterStatus: [],
  setTaskFilterStatus: (statuses) => set({ taskFilterStatus: statuses }),
  taskFilterPriority: [],
  setTaskFilterPriority: (priorities) => set({ taskFilterPriority: priorities }),
  taskFilterAssignedTo: null,
  setTaskFilterAssignedTo: (userId) => set({ taskFilterAssignedTo: userId }),
  
  // Gantt Settings
  ganttGranularity: 'week',
  setGanttGranularity: (granularity) => set({ ganttGranularity: granularity }),
}));
