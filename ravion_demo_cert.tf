resource "domains_module_certificate" "demo" {
  # Empty aws_account_id makes api-go fall back to RuntimeAwsCredentials
  # (its own IAM identity) rather than assuming a cross-account role.
  # See packages/api-go/server/setup/dns_control_plane.go:loadAwsAccountForFactory.
  aws_account_id = ""
  aws_region     = var.region
  domains        = [var.demo_domain]

  # No listener_arn — alb.tf consumes cert_arn directly so no bootstrap cert
  # is needed. Trade-off: skips testing the listener_arn auto-attach path
  # (used for cert rotation / SNI add-cert flows).
}

output "ravion_demo_cert_arn" {
  value = domains_module_certificate.demo.cert_arn
}

output "ravion_demo_cert_status" {
  value = domains_module_certificate.demo.status
}
