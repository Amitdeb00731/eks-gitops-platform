# Phase 2: EKS cluster and workload identity

**Tier:** built live, briefly. This is the one phase that brings up a real EKS
cluster. It is destroyed the same day.

**Goal:** an EKS cluster with managed node groups, IAM roles for service accounts
(IRSA), and the AWS load balancer controller, with the live evidence captured.

**Risk and resilience framing:** least privilege at the workload layer. A pod
assumes its own narrowly scoped IAM role through IRSA rather than sharing the
node's credentials, so a compromised pod cannot reach what it was not granted.

## Steps

1. **EKS module.** Add an `eks` module wrapping `terraform-aws-modules/eks/aws`
   (pinned), consuming the network module's private subnets. Enable the cluster
   OIDC provider, which IRSA depends on. Keep the node group small (two
   `t3.medium` on demand, or Spot for the evidence run) and short-lived.
2. **Apply to dev only.** `terraform apply` the dev environment. Confirm the
   cluster is reachable (`aws eks update-kubeconfig`, then `kubectl get nodes`).
3. **IRSA.** Create an IAM role with a trust policy scoped to one service account
   via the cluster OIDC provider. Annotate the service account with the role ARN.
   From a pod using it, `aws sts get-caller-identity` returns the IRSA role, not
   the node role. That contrast is the least-privilege evidence.
4. **Load balancer controller.** Install `aws-load-balancer-controller` with Helm,
   using its own IRSA role. Deploy a test Service of type `LoadBalancer` and
   confirm an application load balancer is created and serves the pod.

## Teardown (run before leaving the cluster)

1. Delete every Kubernetes Service of type `LoadBalancer` first, so the
   controller removes the load balancers it created (Terraform does not own
   them).
2. `terraform destroy` the dev environment.
3. Sweep for leftovers: orphaned load balancers, target groups, volumes, elastic
   IPs, and CloudWatch log groups. Remove any found.
4. Confirm the budget shows no ongoing charge.

## Evidence to capture (into `evidence/phase2/`)

- `kubectl get nodes` with nodes Ready.
- `aws sts get-caller-identity` from a pod, showing the IRSA role.
- The load balancer serving the test Service.
- The teardown confirmation and the post-destroy sweep result.

## Done checklist

_Operator runbook for a reader reproducing the phase; the as-built result lives
in the evidence files._

- [ ] EKS module written and applied to dev
- [ ] Nodes Ready, cluster reachable
- [ ] IRSA proven from a pod
- [ ] Load balancer serving a test Service
- [ ] Cluster torn down the same day, sweep clean

**Next, Phase 3:** deliver to the cluster through GitLab CI and ArgoCD.
