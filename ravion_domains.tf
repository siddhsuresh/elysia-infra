# --------------------------------------------------------------------------
# Ravion-managed HTTPS — plug-and-play
# --------------------------------------------------------------------------
# `domains_alb_attachment` does the whole dance in one resource:
#   1. Allocates an FQDN under the platform apex (auto-domain).
#   2. Issues the cluster wildcard ACM cert (idempotent per AWS account;
#      blocks until ISSUED, ~30-90s) — wired into the listener default.
#   3. Writes the A-ALIAS pointing the auto-domain at this ALB.
#   4. Issues per-custom-domain ACM certs. Once each cert reaches ISSUED,
#      api-go's reconciler discovers the listener via the cluster cert's
#      ACM `InUseBy` and attaches the cert as an additional SNI cert —
#      no `aws_lb_listener_certificate` plumbing in user TF, no TF apply
#      blocked on customer DNS.
#   5. Once a custom domain is fully live (cert ISSUED + routing record
#      MATCHED), the auto-domain DNS record is retired automatically so
#      there's one canonical URL.
# --------------------------------------------------------------------------

resource "domains_alb_attachment" "main" {
  aws_account_id = "aws_cl4wla7bp00003u68ncsxkxz6"
  aws_region     = var.region
  alb_dns_name   = aws_lb.main.dns_name
  alb_zone_id    = aws_lb.main.zone_id
  custom_domains = var.demo_domain == "" ? [] : [var.demo_domain]
}

output "ravion_default_url" {
  description = "Auto-provisioned default URL for the service. HTTPS works immediately. Retired automatically once a custom domain goes live."
  value       = domains_alb_attachment.main.default_url
}

output "ravion_default_cert_arn" {
  value = domains_alb_attachment.main.default_cert_arn
}

output "ravion_custom_domain_cert_arns" {
  description = "Per-custom-domain ACM cert ARNs. PENDING_VALIDATION until the user adds the ACM CNAMEs (visible in the Domains tab) to their DNS provider."
  value       = domains_alb_attachment.main.custom_domain_cert_arns
}
