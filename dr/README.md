# dr

Disaster recovery and backup automation (Phase 8).

- Velero for scheduled backups of cluster state, with a defined retention
  window.
- Database backup automation and the cross-region copy that makes a regional
  failure survivable.
- The restore drill: a documented, rehearsed recovery into a second region,
  with the measured time to restore recorded as evidence rather than assumed.

This directory holds the backup schedules, the restore procedure, and the
runbook an on-call engineer follows under pressure. A backup that has never
been restored is not a backup, so the drill is part of the deliverable, not an
afterthought.
