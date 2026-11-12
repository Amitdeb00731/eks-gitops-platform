# cost

Cost optimisation automation (Phase 7).

A scheduled function that scans the account for waste: idle EC2 instances,
unattached EBS volumes, and unassociated Elastic IPs. It tags each finding,
estimates the monthly saving, and reports the summary to Slack. It reports and
tags; it does not delete, so a human decides what is actually removed.

This directory holds the function code, its IAM policy (scoped to read and tag,
never to terminate), and the schedule that runs it.
