resource "domains_module_certificate" "demo" {
  # Real Ravion AwsAccount row id. api-go calls NewACMClientFromAwsAccount and
  # cross-account-assumes the role recorded on that row to issue the ACM cert.
  aws_account_id = "aws_cl4wla7bp00003u68ncsxkxz6"
  aws_region     = var.region
  domains        = [var.demo_domain]

  # Wire the listener so api-go's reconciler attaches the cert as an
  # additional SNI cert on this listener once ACM marks it ISSUED. The
  # listener itself is bootstrapped with a self-signed cert (see
  # bootstrap_cert.tf) — the auto-attach swap happens out-of-band, no
  # second `terraform apply` needed.
  listener_arn = aws_lb_listener.https.arn
}

output "ravion_demo_cert_arn" {
  value = domains_module_certificate.demo.cert_arn
}

output "ravion_demo_cert_status" {
  value = domains_module_certificate.demo.status
}
