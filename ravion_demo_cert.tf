resource "domains_module_certificate" "demo" {
  # Real Ravion AwsAccount row id. api-go calls NewACMClientFromAwsAccount and
  # cross-account-assumes the role recorded on that row to issue the ACM cert.
  aws_account_id = "aws_cl4wla7bp00003u68ncsxkxz6"
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
