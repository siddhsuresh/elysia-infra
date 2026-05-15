# base_url and api_key intentionally omitted. The provider falls back to
# RAVION_BASE_URL and RAVION_API_KEY env vars (see
# packages/terraform-provider-domains/internal/provider/provider.go), which
# tower-go injects into the runner for any module-system pipeline run.
provider "domains" {}
