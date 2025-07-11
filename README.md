# Atlantis on EKS – Project README

## Overview

This project deploys [Atlantis](https://www.runatlantis.io/) on AWS EKS using Terraform and Helm. Atlantis automates Terraform workflows by reacting to pull requests and comments in GitHub repositories.

## Prerequisites

- AWS account with permissions to create EKS clusters, IAM roles, and EBS volumes
- Configured AWS CLI and `kubectl`
- Terraform >= 0.13
- Helm >= 3.x
- GitHub account with Personal Access Token (PAT)

## Deployment Steps

1. **Clone this repository**
2. **Configure AWS credentials**  
   Run:  
   ```sh
   aws configure
   ```
3. **Review and update variables in `terraform.tfvars` as needed**
4. **Initialize and apply Terraform**
   ```sh
   terraform init
   terraform plan
   terraform apply
   ```
5. **Atlantis will be deployed via Helm with a LoadBalancer service on port 4528.**

## Exposing Atlantis

- Atlantis must be accessible to GitHub for webhook delivery.
- By default, it runs on port 4141, but you can change this in the Helm values.
- Use security groups or network policies to restrict access.

## GitHub Personal Access Token (PAT) Setup

Atlantis needs a GitHub PAT to interact with your repositories.  
**When creating your PAT, select the following minimum scopes:**

| Scope                 | Why Needed                                 |
|-----------------------|--------------------------------------------|
| `repo`                | Read/write access to code, PRs, comments   |
| `admin:repo_hook`     | Manage webhooks for PR notifications       |
| `read:org` (optional) | Read org membership for team-based access  |

**PAT Creation Steps:**
1. Go to GitHub → Settings → Developer settings → Personal access tokens.
2. Click "Generate new token".
3. Select:
   - `repo`
   - `admin:repo_hook`
   - (Optional) `read:org`
4. Set an expiration and copy the token securely.

## Configuration

- Store your PAT and webhook secret securely (e.g., in AWS Secrets Manager) for sake of simplicity now its stored in plain text and terraform state file.
- Reference these secrets in your Helm values or Terraform variables.

## References

- [Atlantis GitHub Integration Docs](https://www.runatlantis.io/docs/github.html)
- [GitHub PAT Scopes Documentation](https://docs.github.com/en/github/authenticating-to-github/creating-a-personal-access-token)
