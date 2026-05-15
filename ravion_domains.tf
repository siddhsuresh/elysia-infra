# --------------------------------------------------------------------------
# Ravion-managed HTTPS — plug-and-play
# --------------------------------------------------------------------------
# `domains_alb_attachment` does the whole dance in one resource:
#   1. Allocates an FQDN under the platform apex (auto-domain).
#   2. Issues the cluster wildcard ACM cert (idempotent per AWS account;
#      blocks until ISSUED, ~30-90s).
#   3. Writes the A-ALIAS pointing the auto-domain at this ALB.
#   4. Issues per-custom-domain ACM certs (sit PENDING_VALIDATION until the
#      user adds the ACM CNAMEs from the Domains tab to their DNS provider).
#
# The user wires the listener default cert from `default_cert_arn` and
# attaches custom certs as SNI via `aws_lb_listener_certificate` for_each
# below. No bootstrap cert, no JSON-encoded ALIAS targets, no manual
# attachment plumbing.
# --------------------------------------------------------------------------

resource "domains_alb_attachment" "main" {
  aws_account_id = "aws_cl4wla7bp00003u68ncsxkxz6"
  aws_region     = var.region
  alb_dns_name   = aws_lb.main.dns_name
  alb_zone_id    = aws_lb.main.zone_id
  custom_domains = var.demo_domain == "" ? [] : [var.demo_domain]
}

# Custom-domain SNI attachments — stock AWS provider primitive driving off
# the cert-arns map our resource exposes. Empty map = zero attachments.
resource "aws_lb_listener_certificate" "ravion_custom" {
  for_each        = domains_alb_attachment.main.custom_domain_cert_arns
  listener_arn    = aws_lb_listener.https.arn
  certificate_arn = each.value
}

output "ravion_default_url" {
  description = "Auto-provisioned default URL for the service. HTTPS works immediately."
  value       = domains_alb_attachment.main.default_url
}

output "ravion_default_cert_arn" {
  value = domains_alb_attachment.main.default_cert_arn
}

output "ravion_custom_domain_cert_arns" {
  description = "Per-custom-domain ACM cert ARNs. PENDING_VALIDATION until the user adds the ACM CNAMEs (visible in the Domains tab) to their DNS provider."
  value       = domains_alb_attachment.main.custom_domain_cert_arns
}
