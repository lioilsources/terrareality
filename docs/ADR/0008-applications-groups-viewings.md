# ADR 0008: Applications, groups, roommate matching and viewings

Status: accepted (M5, 2026-10-14)

## Decisions

1. **Groups need explicit joining and per-application consent.** A group is created by one seeker
   who invites others by e-mail; an invitee becomes a member only by joining. A group application
   records a consent row for every joined member and stays `pending_consent` (invisible to the
   landlord) until all of them consent; the last consent submits it.
2. **Row-level security across parties.** Applications are visible to the applicant, the joined
   group members and the landlord's organization. Policies that must see a row inserted in the same
   statement (`INSERT … RETURNING`) use inline conditions; helper functions
   (`app_user_group_ids`, `app_user_application_ids`) serve the child tables. The landlord sees a
   group's name through `group_display_name()`; passport facts of applicants and slot capacity are
   read in system context after the caller's access was checked under RLS.
3. **Decisions from a code list.** Landlords invite, accept or reject; a rejection needs a reason
   from a fixed list (no free text, so protected characteristics cannot become a stated reason).
   Accepting one application rejects all other open ones with `other_applicant_chosen` and e-mails
   them automatically. Every decision is audited.
4. **No protected data, AI as a summary only.** Roommate profiles and applications do not collect
   age, sex, nationality, religion or health. The AI writes a neutral summary with strengths and
   gaps for the landlord, never a recommendation (ADR 0003); the mock is template based.
5. **Matching v0 is a scored filter.** Seeker-to-seeker: area overlap, budget ratio, move-in date,
   lifestyle tag overlap minus conflicting habits (smoker/non-smoker, pets/no pets, …). Seeker-to-room:
   budget against rent, area, house rules (pets, smoking). Profiles are visible to signed-in users only.
6. **Tenant Passport v0.** Verification level (from M1), an optional income proof (a file only the
   landlords one applies to can download, through short-lived links) and an insolvency check against
   the public ISIR web service of the Ministry of Justice by name and birth date from BankID, current
   proceedings only; the landlord sees `clear` or `record`. At most one check a day per user.
7. **Viewings.** Landlords publish slots with a capacity; applicants with an open application book
   one (a new booking replaces the previous one). Capacity is enforced with a row lock on the slot.
   Reminders are River jobs scheduled 24 h and 2 h before (e-mail, in-app, push).

## Deviations from the plan

- **Group chat is a simple group thread** (no masking: flatmates may share contacts), delivered in
  realtime through the members' user channels.
- **Reverse listing** ("looking for a flatmate") is the roommate profile list at `/spolubydleni`
  plus suggestions on the landlord's room listing; it is not indexed in the public search.
