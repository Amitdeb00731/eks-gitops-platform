# terraform/policy

The pre-apply policy gate. Checkov scans the Terraform before anything is applied,
and the pipeline fails on a violation.

This directory holds the Checkov configuration and records the baseline: which
checks run, and any check deliberately skipped, each with a reason. A skip is a
documented risk acceptance, not a silent exclusion.

Run locally:

```
checkov --directory ../ --download-external-modules true
```
