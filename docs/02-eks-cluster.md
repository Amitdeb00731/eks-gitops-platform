# Phase 2: EKS cluster and workload identity

**Tier:** built live, briefly. This is the one phase that brings up a real EKS
cluster. It is applied to dev only and destroyed the same day.

**Goal:** an EKS cluster with a managed node group, IAM roles for service
accounts (IRSA), and the AWS Load Balancer Controller, with the live evidence
captured and the cluster torn down.

**Risk and resilience framing:** least privilege at the workload layer. A pod
assumes its own narrowly scoped IAM role through IRSA rather than sharing the
node's credentials, so a compromised pod cannot reach what it was not granted.
Kubernetes secrets are envelope-encrypted with a dedicated KMS key, and the
control-plane audit log goes to CloudWatch.

## Cost, and the one rule

This phase spends money while the cluster exists: the EKS control plane
(about 0.10 USD an hour), two t3.medium nodes, one NAT gateway, and a load
balancer. A focused run of two to three hours costs roughly 2 to 4 USD. The rule
is **bring it up, capture the evidence, destroy it the same day.** Do not leave
it running overnight. The teardown section is not optional.

## What this phase adds

```
terraform/
  modules/
    eks/            the cluster, managed node group, OIDC provider, KMS secret
                    encryption and control-plane logging (wraps the community
                    EKS module, ADR 0006)
    irsa/           a reusable IAM role for one service account, OIDC-federated
                    trust pinned to a namespace and service account
  policy/
    lb-controller-iam-policy.json   the controller's own published policy (pinned)
  envs/dev/         now also calls the eks module and creates two IRSA roles:
                    one for the load balancer controller, one demonstration role
```

The dev network now has `enable_nat_gateway = true`, because the private nodes
need egress to pull images and reach the EKS API. Staging and production are
unchanged: they remain network-only until a later phase.

## Design choices

- **The cluster uses the community EKS module** (ADR 0006), wrapped thinly to set
  the platform's secure defaults. IRSA roles are our own native module, because
  the trust relationship is the security-critical part.
- **Access is through native EKS access entries**, not the aws-auth ConfigMap.
  The identity that applies this (AdminJITRole) is mapped to cluster admin, so no
  Kubernetes provider is needed in Terraform.
- **The API endpoint is public but CIDR-narrowed, plus private.** For a real
  deployment, set `endpoint_public_access_cidrs` to your own IP in `dev.tfvars`.
- **The load balancer controller policy is the controller's own published
  policy**, committed and pinned to release v3.6.1, not hand-maintained.

## Prerequisites

This phase creates IAM roles and a KMS key and a cluster, so it needs the
elevated role, not ContributorRole:

```
source ../cloud-iam-lab-aws/scripts/assume-role.sh <6-digit-MFA-code> AdminJITRole
aws sts get-caller-identity
```

Also install `kubectl` and `helm` (`winget install Kubernetes.kubectl` and
`winget install Helm.Helm`).

## Step 1: validate, plan and apply (dev)

From `terraform/envs/dev`, with the backend variables from Phase 1 still set:

```
terraform init -backend-config="bucket=$TF_STATE_BUCKET" -backend-config="kms_key_id=$TF_STATE_KMS_KEY"
terraform validate
terraform plan -var-file=dev.tfvars -out=dev.tfplan
```

The plan adds the network (now with the NAT gateway), the cluster and node group,
the two IRSA roles and the load balancer controller policy. Review it, then:

```
terraform apply dev.tfplan
```

The cluster takes about 15 minutes. When it finishes, keep the outputs:

```
terraform output
export LBC_ROLE_ARN=$(terraform output -raw lb_controller_role_arn)
export DEMO_ROLE_ARN=$(terraform output -raw irsa_demo_role_arn)
export CLUSTER_NAME=$(terraform output -raw cluster_name)
```

## Step 2: reach the cluster

```
aws eks update-kubeconfig --name "$CLUSTER_NAME" --region eu-north-1
kubectl get nodes
```

Both nodes should be `Ready`. That is the first evidence capture.

## Step 3: prove IRSA (least privilege, made visible)

Create the service account the demo role trusts, annotate it, and run a pod that
uses it:

```
kubectl create serviceaccount irsa-demo
kubectl annotate serviceaccount irsa-demo eks.amazonaws.com/role-arn=$DEMO_ROLE_ARN

kubectl run irsa-demo --rm -it --restart=Never \
  --image=amazon/aws-cli --overrides='{"spec":{"serviceAccount":"irsa-demo"}}' \
  -- sts get-caller-identity
```

The ARN returned is the `dev-irsa-demo` role, not the node role. For the
contrast, run the same image with no service account:

```
kubectl run node-identity --rm -it --restart=Never \
  --image=amazon/aws-cli -- sts get-caller-identity
```

That one returns the node group's role. The two outputs side by side are the
least-privilege evidence: identity follows the pod, not the host.

## Step 4: the load balancer controller and a test service

Install the controller with Helm, pointing its service account at the IRSA role
Terraform created:

```
helm repo add eks https://aws.github.io/eks-charts
helm repo update

helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=$CLUSTER_NAME \
  --set region=eu-north-1 \
  --set vpcId=$(terraform output -raw vpc_id) \
  --set serviceAccount.create=true \
  --set serviceAccount.name=aws-load-balancer-controller \
  --set serviceAccount.annotations."eks\.amazonaws\.com/role-arn"=$LBC_ROLE_ARN

kubectl -n kube-system rollout status deployment/aws-load-balancer-controller
```

The committed policy is pinned to controller release v3.6.1. If Helm installs a
newer controller that needs a newer policy, update
`terraform/policy/lb-controller-iam-policy.json` from the matching release tag
and re-apply.

Deploy a small app behind an internet-facing load balancer:

```
kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v3.6.1/docs/examples/echo_server.yaml
```

If the example is not reachable, use any Deployment plus this Service:

```
kubectl expose deployment echoserver --type=LoadBalancer --port=80 \
  --overrides='{"metadata":{"annotations":{"service.beta.kubernetes.io/aws-load-balancer-scheme":"internet-facing","service.beta.kubernetes.io/aws-load-balancer-type":"external","service.beta.kubernetes.io/aws-load-balancer-nlb-target-type":"ip"}}}'

kubectl get service echoserver -w
```

When `EXTERNAL-IP` shows a load balancer hostname, `curl` it. A reply is the
evidence that the controller, using its IRSA role, provisioned the load balancer.

## Step 5: evidence to capture (into `evidence/phase2/`)

- `kubectl get nodes` with both nodes Ready.
- The two `sts get-caller-identity` outputs: the IRSA role from the annotated pod,
  the node role from the unannotated pod.
- The load balancer hostname and a successful `curl` of the test service.
- The teardown output and the post-destroy sweep (Step 6).

## Step 6: teardown (run before you leave the cluster)

Order matters. The controller created the load balancer, Terraform did not own
it, so the Kubernetes objects come down first:

```
kubectl delete service echoserver
kubectl delete -f https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v3.6.1/docs/examples/echo_server.yaml --ignore-not-found
helm uninstall aws-load-balancer-controller -n kube-system
```

Wait a minute for the load balancer to disappear, then destroy:

```
terraform destroy -var-file=dev.tfvars
```

Sweep for anything left behind (the Build 2 lesson):

```
aws elbv2 describe-load-balancers --region eu-north-1 --query 'LoadBalancers[].LoadBalancerName'
aws ec2 describe-volumes --region eu-north-1 --filters Name=status,Values=available --query 'Volumes[].VolumeId'
aws ec2 describe-addresses --region eu-north-1 --query 'Addresses[?AssociationId==null].AllocationId'
```

Delete anything these list. Confirm the budget shows no ongoing charge the next
day. Only the Phase 1 state bucket and its KMS key remain, by design.

## Done checklist

_Operator runbook for a reader reproducing the phase; the as-built result lives
in the evidence files._

- [ ] Cluster applied to dev, both nodes Ready
- [ ] IRSA proven: the pod shows the IRSA role, the node role differs
- [ ] Load balancer controller installed on its IRSA role
- [ ] Test service served through the load balancer
- [ ] Cluster destroyed the same day, sweep clean
- [ ] Evidence saved under `evidence/phase2/`

**Next, Phase 3:** deliver to the cluster through GitLab CI and ArgoCD.
