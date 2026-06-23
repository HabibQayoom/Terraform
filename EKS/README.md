# Terraform — Amazon EKS (Multi-Environment)

Modular Terraform that provisions a production-ready Amazon EKS cluster on AWS.
Separate environments for **dev**, **staging**, and **prod** — each with its own
state, sizing, and node group config.

---

## What Gets Created

Every environment provisions:

- **VPC** — public + private subnets across multiple AZs, NAT Gateways, Internet
  Gateway, and route tables with the correct Kubernetes subnet tags
- **IAM roles** — cluster service role, node instance role (with Worker / CNI / ECR
  policies attached)
- **EKS cluster** — KMS-encrypted Kubernetes secrets, CloudWatch control-plane logs,
  OIDC provider for IRSA
- **Node groups** — autoscaling managed node groups (on-demand or spot, fully
  configurable per environment via tfvars)
- **Managed addons** — CoreDNS, kube-proxy, vpc-cni, EBS CSI driver (with its own
  IRSA role), Pod Identity Agent
- **Cluster access** — IAM user access via EKS access entries (no manual `aws-auth`
  ConfigMap editing)

---

## Prerequisites

Install these before you start:

| Tool | Install |
|---|---|
| Terraform ≥ 1.5 | https://developer.hashicorp.com/terraform/downloads |
| AWS CLI v2 | https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html |
| kubectl | https://kubernetes.io/docs/tasks/tools/ |
| git | https://git-scm.com/downloads |

Verify everything is installed:

```bash
terraform version   # must be >= 1.5
aws --version
kubectl version --client
```

---

## Step 1 — Clone the Repo

```bash
git clone https://github.com/HabibQayoom/terraform-eks.git
cd terraform-eks
```

---

## Step 2 — Configure AWS Credentials

You need an IAM user or role with permissions to create VPCs, EKS clusters,
IAM roles, and KMS keys.

**Option A — environment variables (recommended for CI/CD):**

```bash
export AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE
export AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
export AWS_DEFAULT_REGION=us-east-1
```

**Option B — AWS CLI profile (recommended for local use):**

```bash
aws configure
# Enter: Access Key ID, Secret Access Key, region, output format (json)
```

Verify it works:

```bash
aws sts get-caller-identity
# Should print your account ID and user/role ARN — no errors
```

---

## Step 3 — Bootstrap Remote State (one time only)

Terraform needs an S3 bucket to store state and a DynamoDB table for locking.
Run this script once — you never need to run it again.

```bash
chmod +x scripts/bootstrap-remote-state.sh
./scripts/bootstrap-remote-state.sh us-east-1
```

The script will print something like:

```
Done. Update each environments/<env>/backend.tf with:
  bucket         = "tf-eks-state-1234567"
  region         = "us-east-1"
  dynamodb_table = "terraform-lock"
```

Copy that bucket name and open **all three** backend files:

```
environments/dev/backend.tf
environments/staging/backend.tf
environments/prod/backend.tf
```

In each file, replace `REPLACE_WITH_YOUR_BUCKET_NAME` with your actual bucket name:

```hcl
terraform {
  backend "s3" {
    bucket         = "tf-eks-state-1234567"   # <-- your bucket
    key            = "dev/eks.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-lock"
  }
}
```

> **Quick local test (skip remote state):** Comment out the entire
> `backend "s3" { ... }` block in `backend.tf`. Terraform will use a local
> `terraform.tfstate` file instead. Just don't commit that file.

---

## Step 4 — Customise Your Environment

Open `environments/dev/terraform.tfvars` (or staging/prod).
Everything you need to change is here — no other files need editing.

```hcl
aws_region         = "us-east-1"      # change to your region
vpc_name           = "eks-dev-vpc"
vpc_cidr           = "10.1.0.0/16"
availability_zones = ["us-east-1a", "us-east-1b"]
public_subnets     = ["10.1.1.0/24", "10.1.2.0/24"]
private_subnets    = ["10.1.10.0/24", "10.1.20.0/24"]

cluster_name    = "eks-dev"
cluster_version = "1.30"

node_groups = {
  general = {
    instance_types = ["t3.small"]
    min_size       = 1
    max_size       = 2
    desired_size   = 1
    disk_size      = 20
    ami_type       = "AL2_x86_64"
    capacity_type  = "SPOT"       # SPOT saves cost; use ON_DEMAND for prod
    labels         = { env = "dev", role = "general" }
    taints         = []
  }
}
```

**Common things you might want to change:**

| What | Where | Example |
|---|---|---|
| AWS region | `aws_region` | `"ap-southeast-1"` |
| Instance size | `instance_types` | `["t3.medium"]` |
| Number of nodes | `min_size` / `max_size` | `1` / `5` |
| Spot vs on-demand | `capacity_type` | `"SPOT"` or `"ON_DEMAND"` |
| Kubernetes version | `cluster_version` | `"1.31"` |
| Add a second node pool | Add another entry to `node_groups` | see prod tfvars |

**Check available Kubernetes versions for your region:**

```bash
aws eks describe-addon-versions \
  --query 'addons[0].addonVersions[*].compatibilities[*].clusterVersion' \
  --output text | tr '\t' '\n' | sort -u
```

---

## Step 5 — Deploy (dev first)

Always deploy dev first to confirm everything works before touching prod.

```bash
cd environments/dev

terraform init        # downloads providers, sets up backend
terraform plan        # shows what will be created — read this carefully
terraform apply       # creates everything (takes ~15 minutes)
```

When `apply` finishes you'll see outputs like:

```
cluster_name             = "eks-dev"
cluster_endpoint         = "https://ABCDE123.gr7.us-east-1.eks.amazonaws.com"
get_credentials_command  = "aws eks update-kubeconfig --region us-east-1 --name eks-dev"
```

---

## Step 6 — Connect kubectl

Run the command from the Terraform output:

```bash
aws eks update-kubeconfig --region us-east-1 --name eks-dev
```

Verify the cluster is up:

```bash
kubectl get nodes
# Should show your node(s) in Ready state

kubectl get pods -n kube-system
# Should show CoreDNS, kube-proxy, vpc-cni pods all Running
```

---

## Step 7 — Deploy Staging and Prod

Once dev works, deploy the other environments the same way:

```bash
# Staging
cd ../staging
terraform init
terraform plan
terraform apply

# Prod
cd ../prod
terraform init
terraform plan
terraform apply
```

Each environment has its own state file in S3 (`dev/eks.tfstate`,
`staging/eks.tfstate`, `prod/eks.tfstate`) so they are completely independent.

---

## How to Add More Users to the Cluster

Open the tfvars for the environment and add ARNs:

```hcl
# Give a user full admin access
direct_user_access = [
  {
    arn        = "arn:aws:iam::YOUR_ACCOUNT_ID:user/your-username"
    username   = "your-username"
    policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  }
]
```

Then run `terraform apply`. No need to edit `aws-auth` ConfigMap manually.

---

## How to Add a Second Node Group

In your tfvars, add another entry to `node_groups`:

```hcl
node_groups = {
  general = {
    instance_types = ["t3.large"]
    min_size       = 2
    max_size       = 5
    desired_size   = 2
    disk_size      = 20
    ami_type       = "AL2_x86_64"
    capacity_type  = "ON_DEMAND"
    labels         = { role = "general" }
    taints         = []
  }

  spot = {
    instance_types = ["t3.medium", "t3.large"]
    min_size       = 0
    max_size       = 4
    desired_size   = 0
    disk_size      = 20
    ami_type       = "AL2_x86_64"
    capacity_type  = "SPOT"
    labels         = { role = "spot" }
    taints         = []
  }
}
```

Run `terraform apply` — Terraform will create the new node group without
touching the existing one.

---

## How to Upgrade Kubernetes Version

1. Check the new version is available: `aws eks describe-addon-versions ...` (see Step 4)
2. Change `cluster_version` in tfvars
3. Run `terraform plan` to see what changes
4. Run `terraform apply` — EKS upgrades the control plane first, then
   node groups are replaced rolling one node at a time

---

## How to Tear Down

```bash
cd environments/dev
terraform destroy
# Type "yes" when prompted
```

> **Warning:** This deletes everything including the VPC and all data.
> Your S3 bucket and DynamoDB table are NOT deleted — they are not managed
> by these environments. Delete them manually if you no longer need them.

---

## Repo Layout

```
.
├── modules/
│   ├── vpc/                # VPC, subnets, NAT, IGW, route tables
│   ├── iam/                # Cluster + node IAM roles and policy attachments
│   ├── eks/                # EKS cluster, KMS, OIDC, node groups, core addons
│   ├── iam_oidc/           # IRSA role for the EBS CSI driver
│   └── iam_cluster_access/ # EKS access entries for IAM users
├── environments/
│   ├── dev/                # Spot t3.small, 2 AZs, minimal cost
│   ├── staging/            # On-demand t3.medium, 3 AZs
│   └── prod/               # On-demand t3.large, 3 AZs, optional spot pool
└── scripts/
    └── bootstrap-remote-state.sh
```

The only files you should ever need to edit are the `terraform.tfvars` files
inside each environment folder and the `backend.tf` bucket name.
The modules are shared — changes there affect all environments.

---

## Troubleshooting

**`Error: configuring Terraform AWS Provider: no valid credential sources found`**
→ Your AWS credentials are not set. Run `aws configure` or export the environment
variables in Step 2.

**`Error acquiring the state lock`**
→ A previous run crashed and left a lock. Check DynamoDB for a stuck lock entry
and delete it, or run `terraform force-unlock <LOCK_ID>`.

**Node group creation fails with IAM error**
→ Make sure your IAM user/role has `iam:CreateRole`, `iam:AttachRolePolicy`,
and `eks:*` permissions. Ask your AWS admin to attach `AdministratorAccess`
temporarily for the first deploy, then scope it down.

**Nodes stuck in `NotReady`**
→ Usually a CNI issue. Check: `kubectl describe node <node-name>` and
`kubectl logs -n kube-system -l k8s-app=aws-node`. The vpc-cni addon needs
a moment after node join.

**`terraform plan` shows addon version changes on every run**
→ Add `addon_version = null` to let AWS manage the version, or pin to the
exact version string shown in the plan output.

---

## Security Notes

- KMS encryption is enabled for Kubernetes secrets in all environments
- Worker nodes are in private subnets — they are not directly reachable from the internet
- The public API endpoint is open by default (`0.0.0.0/0`); restrict it in prod by
  setting `cluster_endpoint_public_access_cidrs = ["YOUR_OFFICE_IP/32"]`
- Never commit real credentials, `.tfstate` files, or `.terraform/` directories —
  all are git-ignored
