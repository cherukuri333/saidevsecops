
# **Terraform ECR Drift – Practical Guide**

---

## **1️⃣ Overview**

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

I can generate this **as a ready-to-use Word or PDF with embedded diagrams** (ECR Drift and Flow), so you just open it and share with your team.

Do you want me to create that full **document with images** next?

