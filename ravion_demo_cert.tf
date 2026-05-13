resource "ravion_module_certificate" "demo" {
  # Empty aws_account_id makes api-go fall back to RuntimeAwsCredentials
  # (its own IAM identity) rather than assuming a cross-account role.
  # See packages/api-go/server/setup/dns_control_plane.go:loadAwsAccountForFactory.
  aws_account_id = ""
  aws_region     = var.region
  domains        = [var.demo_domain]

  # HTTPS listener from alb.tf. Declared with count = var.certificate_arn != "" ? 1 : 0,
  # so this reference requires certificate_arn to already be set to a (placeholder)
  # ACM ARN before applying — the Ravion-issued cert then auto-attaches once ISSUED.
  listener_arn = aws_lb_listener.https[0].arn
}

output "ravion_demo_cert_arn" {
  value = ravion_module_certificate.demo.cert_arn
}

output "ravion_demo_cert_status" {
  value = ravion_module_certificate.demo.status
}
