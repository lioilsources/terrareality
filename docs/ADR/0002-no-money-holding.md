# ADR 0002: The platform never holds money

- Status: accepted (2026-10-14)
- Context: scope v0.3, sections 8.9 and 13 (decision 2).

## Decision

TerraReality does not receive, hold, forward or pay out funds. Rent, deposits and service charges go
directly from tenant to landlord. The platform only:

1. generates payment instructions (Czech QR "SPD" payments, Revolut payment links created on the landlord's
   own merchant account),
2. reads the landlord's bank transactions through a licensed AIS provider (PSD2 account information, read only),
3. matches transactions to obligations and shows debt.

Co-ownership distributions (phase 3) follow the same rule: the system computes splits and produces payment
instructions; it never moves money.

## Consequences

- No payment institution licence, no AML programme of our own, no safeguarding accounts.
- Escrow, rent collection and crypto are out of scope until a licensed partner is integrated (phase 4+).
- Any code path that would create a balance owned by the platform is a bug. Reviewers reject it.
