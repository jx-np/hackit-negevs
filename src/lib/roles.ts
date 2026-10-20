import type { UserRole } from '../types';

/** True for the roles that can use the staff console (`moderator` or `admin`). */
export function isStaffRole(role?: UserRole | null): boolean {
  return role === 'moderator' || role === 'admin';
}

/** True only for full administrators. */
export function isAdminRole(role?: UserRole | null): boolean {
  return role === 'admin';
}

/** Human-readable labels for role badges/selects. */
export const ROLE_LABELS: Record<UserRole, string> = {
  resident: 'Resident',
  helper: 'Helper',
  moderator: 'Moderator',
  admin: 'Admin',
};
