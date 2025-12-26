**Terraform Drift** occurs when the **real AWS resource differs from Terraform state**.

**Why it matters for ECR:**

* Tag mutability changed manually → risk of image overwrite
* Scan-on-push disabled → security blind spot
* Repo deleted manually → Terraform recreates

**Terraform sources:**

```
Terraform Config (.tf)   ← Desired state
Terraform State (.tfstate)  ← Last known state
AWS ECR Repository       ← Actual infrastructure
```

---

## **2️⃣ ECR Drift Example Diagram**

![ECR Drift Diagram](https://i.imgur.com/y8hT5vF.png)
*Diagram shows state, AWS, and configuration drift detection, with fix vs accept paths.*

---

## **3️⃣ Terraform Code – Create ECR**

```hcl
provider "aws" {
  region = "us-east-1"
}

resource "aws_ecr_repository" "demo" {
  name                 = "terraform-drift-demo"
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Environment = "dev"
    Owner       = "platform-team"
  }
}
```

---

## **4️⃣ Terraform Commands**

| Action            | Command                         |
| ----------------- | ------------------------------- |
| Init              | `terraform init`                |
| Apply             | `terraform apply`               |
| Detect drift      | `terraform plan`                |
| Detect drift only | `terraform plan -refresh-only`  |
| Accept drift      | `terraform apply -refresh-only` |
| Fix drift         | `terraform apply`               |
| Show state        | `terraform show`                |

---

## **5️⃣ Drift Lab Steps**

1. `terraform init && terraform apply` → Create ECR repo
2. Verify repo in AWS Console
3. Make a manual change (e.g., `image_tag_mutability = MUTABLE`)
4. Run `terraform plan` → Drift detected
5. Run `terraform plan -refresh-only` → Detect drift without changing AWS
6. Decide:

   * Fix drift → `terraform apply` → AWS updated
   * Accept drift → `terraform apply -refresh-only` → State updated

---

## **6️⃣ Drift Flow Diagram**

![Drift Flow Diagram](https://i.imgur.com/JtQb6I5.png)
*Shows Terraform config → state → AWS, manual change, detection, and fix/accept paths.*

---

## **7️⃣ Best Practices for Platform Teams**

* Use `prevent_destroy` for critical repos
* Use `ignore_changes` for AWS-added tags
* Run `refresh-only` in CI/CD to detect drift safely
* Treat Terraform as the **source of truth**, unless adopting manual changes intentionally

---

## **8️⃣ Key Takeaways**

* Drift = **State ≠ Real Infrastructure**
* `plan` detects drift + config changes
* `plan -refresh-only` detects **drift only**
* Fix drift = enforce Terraform config
* Accept drift = adopt manual changes into state

---

Perfect! Let’s dive deep into **Terraform Execution Graph & Dependency Resolution** with **practical clarity**, diagrams, and examples. This is a key concept for understanding **how Terraform decides the order of resource creation, updates, and deletion**.

---

# **Terraform Execution Graph & Dependency Resolution**

---

## **1️⃣ What is the Execution Graph?**

Terraform **does not execute resources line by line**. Instead:

* It builds a **Directed Acyclic Graph (DAG)** of all resources
* Determines **dependencies automatically**
* Runs **independent resources in parallel** for speed
* Ensures **dependent resources execute in the correct order**

💡 Think of it like a **flow chart**: Terraform analyzes what depends on what, then executes safely.

---
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
## **2️⃣ Dependency Types**

### 2.1 Implicit Dependencies

Automatically detected when you reference another resource:

```hcl
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "subnet1" {
  vpc_id     = aws_vpc.main.id   # ← Implicit dependency
  cidr_block = "10.0.1.0/24"
}
```

* Terraform knows **subnet1 depends on VPC**
* Subnet will be created **after VPC**

---

### 2.2 Explicit Dependencies

Sometimes you need to **force dependencies** using `depends_on`:

```hcl
resource "aws_iam_role_policy_attachment" "example" {
  role       = aws_iam_role.myrole.name
  policy_arn = aws_iam_policy.mypolicy.arn

  depends_on = [aws_instance.demo]
}
```

* Ensures **IAM attachment happens only after EC2 instance**
* Useful when Terraform cannot infer dependency

---

## **3️⃣ Execution Graph Example (Simple AWS Setup)**

### Resources

* VPC → Subnet → Security Group → EC2 Instance

```hcl
resource "aws_vpc" "main" { ... }

resource "aws_subnet" "subnet1" {
  vpc_id = aws_vpc.main.id
}

resource "aws_security_group" "sg" {
  vpc_id = aws_vpc.main.id
}

resource "aws_instance" "demo" {
  subnet_id = aws_subnet.subnet1.id
  vpc_security_group_ids = [aws_security_group.sg.id]
}
```

### Execution Graph (ASCII)

```
aws_vpc.main
     │
 ┌───┴───┐
 │       │
aws_subnet.subnet1
aws_security_group.sg
     │
     ▼
aws_instance.demo
```

* **VPC** first
* **Subnet & Security Group** next (parallel)
* **EC2 Instance** last

---

## **4️⃣ Plan Output & Graph**

Run:

```bash
terraform plan
```

Plan shows:

```
aws_vpc.main          + create
aws_subnet.subnet1    + create
aws_security_group.sg + create
aws_instance.demo     + create
```

💡 Terraform **determines execution order automatically** using the graph.

---

## **5️⃣ Parallelism in Execution**

Terraform can create **independent resources in parallel**:

```bash
terraform apply -parallelism=5
```

* Default: 10
* Independent resources are applied simultaneously → faster applies
* Dependent resources are still sequential

---

## **6️⃣ Refresh & Dependency**

* During `plan` or `apply`, Terraform **refreshes state first**
* Dependencies are resolved on **actual current state**
* Drift may affect dependency order (if a dependent resource is deleted manually)

---

## **7️⃣ Execution Graph Visualization (Diagram)**

```
           ┌───────────────┐
           │  aws_vpc.main │
           └───────┬───────┘
                   │
      ┌────────────┴─────────────┐
      │                          │
┌──────────────┐          ┌──────────────┐
│ aws_subnet   │          │ aws_sg       │
└──────────────┘          └──────────────┘
      │                          │
      └────────────┬─────────────┘
                   │
           ┌───────────────┐
           │ aws_instance  │
           └───────────────┘
```

* **Arrows = dependencies**
* Parallel resources = side by side
* Sequential = top to bottom

---

## **8️⃣ Real-World Notes**

* Terraform **always builds this DAG internally**
* Changing a resource **may trigger dependent updates**
* Understanding the graph helps in:

  * Debugging apply errors
  * Optimizing parallelism
  * Predicting which resources will be recreated

---

## **9️⃣ Practical Tip**

To **see a real graph**, you can run:

```bash
terraform graph | dot -Tpng > graph.png
```

* Requires `Graphviz` installed (`dot`)
* Produces a **visual dependency graph**
* Very useful in large infra

---
