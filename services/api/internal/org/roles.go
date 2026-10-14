// Package org implements organizations, memberships, roles and invitations.
// Reads and writes of org data run in db.AsUser transactions, so row-level
// security limits them to the caller's organizations; role checks add the
// finer rules on top.
package org

// Roles, ordered from most to least privileged.
const (
	Owner       = "owner"
	Admin       = "admin"
	Agent       = "agent"
	Accountant  = "accountant"
	Maintenance = "maintenance"
	Viewer      = "viewer"
)

// Permission is an action within an organization.
type Permission string

// Permissions checked by services. Later milestones add their own.
const (
	PermOrgManage     Permission = "org.manage"     // rename, company details
	PermMembersManage Permission = "members.manage" // invite, change roles, remove
	PermAuditRead     Permission = "audit.read"
	PermCatalogRead   Permission = "catalog.read"
	PermCatalogWrite  Permission = "catalog.write" // properties, units, listings, media
	PermFinanceRead   Permission = "finance.read"
	PermFinanceWrite  Permission = "finance.write"
	PermMaintenance   Permission = "maintenance.write"
)

var grants = map[string][]Permission{
	Owner:       {PermOrgManage, PermMembersManage, PermAuditRead, PermCatalogRead, PermCatalogWrite, PermFinanceRead, PermFinanceWrite, PermMaintenance},
	Admin:       {PermOrgManage, PermMembersManage, PermAuditRead, PermCatalogRead, PermCatalogWrite, PermFinanceRead, PermFinanceWrite, PermMaintenance},
	Agent:       {PermCatalogRead, PermCatalogWrite},
	Accountant:  {PermCatalogRead, PermFinanceRead, PermFinanceWrite},
	Maintenance: {PermCatalogRead, PermMaintenance},
	Viewer:      {PermCatalogRead, PermFinanceRead},
}

// Can reports whether role has permission.
func Can(role string, p Permission) bool {
	for _, g := range grants[role] {
		if g == p {
			return true
		}
	}
	return false
}

// ValidRole reports whether r is a known role.
func ValidRole(r string) bool { _, ok := grants[r]; return ok }
