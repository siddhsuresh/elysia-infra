# Bootstrap self-signed cert. Exists only so the HTTPS listener can be created
# at all — AWS ELBv2 rejects PENDING_VALIDATION certs at listener-create time
# with `UnsupportedCertificate`. Once domains_module_certificate.demo issues
# the real cert (after the user adds the ACM validation CNAMEs to their DNS),
# api-go's reconciler attaches it to the listener as an additional SNI cert
# via the listener_arn wired on that resource.
#
# This lingering self-signed cert is harmless — ALB serves it only for SNI
# requests that don't match the real cert's domain. Delete it manually after
# verifying the real cert is bound.
resource "tls_private_key" "bootstrap" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_self_signed_cert" "bootstrap" {
  private_key_pem = tls_private_key.bootstrap.private_key_pem

  subject {
    common_name  = "bootstrap.${var.demo_domain}"
    organization = "Ravion bootstrap (replace with domains_module_certificate.demo once issued)"
  }

  validity_period_hours = 24 * 365
  early_renewal_hours   = 24 * 30

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}

resource "aws_acm_certificate" "bootstrap" {
  private_key      = tls_private_key.bootstrap.private_key_pem
  certificate_body = tls_self_signed_cert.bootstrap.cert_pem

  lifecycle {
    create_before_destroy = true
  }
}
