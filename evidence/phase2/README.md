# Evidence: Phase 2, EKS cluster and workload identity

Guide: [docs/02-eks-cluster.md](../../docs/02-eks-cluster.md).

Tier: built live, briefly. The cluster was brought up in the workload account
(eu-north-1) for a single evidence run on 2026-11-18, every control proven, then
destroyed the same day. These notes summarise the running system; the raw
terminal captures are under `raw/`, which is git-ignored.

## The run

| Stage | What it proves |
| --- | --- |
| Cluster and nodes | A managed node group of two t3.medium nodes joined the cluster and reached `Ready` on Kubernetes 1.33 (Amazon Linux 2023), in the private subnets. |
| IRSA, least privilege | A pod using the annotated service account assumed its own role (`dev-irsa-demo`) and listed S3 buckets. An identical pod with no service account received no credentials at all, because the nodes restrict the instance metadata service. Identity follows the pod, not the host. |
| Load Balancer Controller | The AWS Load Balancer Controller (v3.6.3) installed on its IRSA role and rolled out two replicas. |
| Live load balancer | A test deployment was exposed through a `LoadBalancer` service. The controller, using its IRSA role, provisioned an internet-facing Network Load Balancer, and the application answered over the public internet. |
| Teardown | `terraform destroy` removed all 70 resources. A sweep for load balancers, unattached volumes, unassociated Elastic IPs and clusters came back empty. Only the Phase 1 state bucket and KMS key remain, by design. |

## IRSA, the key output

The annotated pod returned its own role and could read:

```
Arn: arn:aws:sts::<account-id>:assumed-role/dev-irsa-demo/botocore-session-...
(followed by a successful s3 ls)
```

The pod with no service account returned nothing:

```
Unable to locate credentials
```

The two side by side are the least-privilege evidence. A workload gets exactly the
identity it was granted through IRSA, and nothing by default from the host.

## The load balancer

The controller provisioned an internet-facing NLB
(`k8s-default-echoserv-....elb.eu-north-1.amazonaws.com`) and a `curl` of it
returned the application's page. That confirms the controller, running on its IRSA
role, held the permissions in the committed policy and could create a real load
balancer.

## Root cause of note: VPC Block Public Access

The first node group failed to join (`NodeCreationFailure`). This is recorded
because the Terraform was correct throughout. Working from the NAT gateway's
CloudWatch metrics, packets were leaving the VPC (`PacketsOutToDestination`
non-zero) but none returned (`PacketsInFromDestination` zero), while the routes,
the internet gateway, the security groups, the network ACLs, DNS and the Elastic
IP binding were all verified correct.

The cause was an account-level control: VPC Block Public Access, set to
`block-bidirectional`, enabled during the earlier Build 2 security hardening. It
blocks all internet gateway traffic for the whole region, independent of any VPC
configuration, and it is a data-plane control, which a Service Control Policy is
not. The fix was a scoped, reversible exclusion for this one VPC. The guardrail
stayed in force everywhere else, and the exclusion was removed at teardown, so the
account finished exactly as it began.
