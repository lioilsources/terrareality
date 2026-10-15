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
	Investor    = "investor" // co-owner, bank or accountant outside the team: reads the portfolio only
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
	PermMessages      Permission = "messages.write"  // answer seekers, reply templates
	PermLeases        Permission = "leases.write"    // leases, payment schedule, bank matching
	PermPortfolioRead Permission = "portfolio.read"  // rent roll, risk, dashboard
	PermPortfolio     Permission = "portfolio.write" // groups, rules per municipality/group, risk weights
)

var grants = map[string][]Permission{
	Owner:       {PermOrgManage, PermMembersManage, PermAuditRead, PermCatalogRead, PermCatalogWrite, PermFinanceRead, PermFinanceWrite, PermMaintenance, PermMessages, PermLeases, PermPortfolioRead, PermPortfolio},
	Admin:       {PermOrgManage, PermMembersManage, PermAuditRead, PermCatalogRead, PermCatalogWrite, PermFinanceRead, PermFinanceWrite, PermMaintenance, PermMessages, PermLeases, PermPortfolioRead, PermPortfolio},
	Agent:       {PermCatalogRead, PermCatalogWrite, PermMessages, PermLeases, PermPortfolioRead},
	Accountant:  {PermCatalogRead, PermFinanceRead, PermFinanceWrite, PermLeases, PermPortfolioRead},
	Maintenance: {PermCatalogRead, PermMaintenance},
	Viewer:      {PermCatalogRead, PermFinanceRead, PermPortfolioRead},
	Investor:    {PermPortfolioRead},
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
