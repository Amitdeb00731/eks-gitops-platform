# Remote state for prod. The bucket name and the state KMS key are supplied at
# init time, so no account-specific value is committed:
#   terraform init -backend-config="bucket=$TF_STATE_BUCKET" -backend-config="kms_key_id=$TF_STATE_KMS_KEY"
# Each environment has its own key, so environments never share state.
# use_lockfile enables S3 native state locking.
terraform {
  backend "s3" {
    key          = "envs/prod/terraform.tfstate"
    region       = "eu-north-1"
    encrypt      = true
    use_lockfile = true
  }
}
