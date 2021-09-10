# -----------------------------------------------------------------------------
# Manage Versions
# -----------------------------------------------------------------------------
terraform {
  required_version = "= 0.15.5"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "= 3.67.0"
    }
  }

  backend "gcs" {}
}

# -----------------------------------------------------------------------------
# Prepare Providers
# -----------------------------------------------------------------------------
provider "google" {
  credentials = file("../../.credentials/terraform-service-account.json")
  project     = var.project_id
  region      = var.region
}

# -----------------------------------------------------------------------------
# Enable APIs
# -----------------------------------------------------------------------------
resource "google_project_service" "project" {
  service            = "run.googleapis.com"
  project            = var.project_id
  disable_on_destroy = true
}

# -----------------------------------------------------------------------------
# Create Cloud Run
# -----------------------------------------------------------------------------
resource "google_cloud_run_service" "cloud_run" {
  name     = "cloudrun-service"
  location = var.region

  template {
    spec {
      containers {
        image = var.image_id
      }
      service_account_name = google_service_account.cloud_run.email
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }
}

# Cloud Runアクセス時のIAM認証を無効化
resource "google_cloud_run_service_iam_member" "cloud_run" {
  location = google_cloud_run_service.cloud_run.location
  project  = google_cloud_run_service.cloud_run.project
  service  = google_cloud_run_service.cloud_run.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

# Cloud Runに紐付けるサービスアカウント
resource "google_service_account" "cloud_run" {
  account_id   = "cloud-run"
  display_name = "Service Account"
}

# Cloud Runに紐付けるサービスアカウントにRoleを付与 
resource "google_service_account_iam_member" "cloud_run_run_invoker" {
  service_account_id = google_service_account.cloud_run.name
  role               = "roles/editor"
  member             = "serviceAccount:${google_service_account.cloud_run.email}"
}
