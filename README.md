# Agentic_job_seeker_Terraform

Terraform for the AWS stack of [Agentic_job_seeker](https://github.com/YashJadhav1023/Agentic_job_seeker):
one EC2 instance + Elastic IP, security group, SSM instance role, SSM Parameter Store (secrets and config) and a monthly budget.
Remote state lives in S3 (`ajs-tfstate-<account-id>`, created by the workflow on first run).

## Run it
Actions > Terraform (AWS) > Run workflow: `plan` (preview), `apply` (create/update), `destroy` (delete everything).
A push to `main` touching `infra/` runs fmt + validate + plan only; apply and destroy are manual.

IAM policy for the deployer user: `iam/deployer-policy.json`.

Needs repository secrets `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` and repository variable `BUDGET_EMAIL`.

After the first apply, set the real value of `/agentic-job-seeker/secret/JOBHUB_SECRET_GMAIL_APP_PASSWORD` in Parameter Store.
The instance clones the app repo on first boot and runs its `deploy/bootstrap-env.sh`; later app deploys are done by that repo's Deploy workflow.

Local check: `cd infra/terraform && terraform init -backend=false && terraform validate` (Terraform >= 1.10).
