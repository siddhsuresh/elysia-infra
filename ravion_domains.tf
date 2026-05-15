# --------------------------------------------------------------------------
# Ravion-managed default URL — auto-provisioned at apply time
# --------------------------------------------------------------------------
# A subdomain under the Ravion-controlled apex (flightcontrol-development.com)
# is allocated, the cluster wildcard cert covering it is issued + DNS-validated
# automatically (Ravion writes the validation CNAMEs into its own Route53),
# and an A-ALIAS record points the allocated FQDN at the ALB. The user gets a
# working HTTPS URL out of the box without touching any DNS.
# --------------------------------------------------------------------------

# 1. Allocate a subdomain. The FQDN is deterministic from
#    (module_instance_id, slot) so re-runs are idempotent.
resource "domains_app_domain" "default" {
  slot     = "public_alb"
  wildcard = false
}

# 2. One-per-cluster wildcard cert covering the platform apex. The apex is
#    resolved server-side from the cluster's platform config — the user
#    doesn't need to know or pin it. Provider Create blocks until ACM
#    marks it ISSUED (typically 30-90s).
resource "domains_cluster_certificate" "default" {
  aws_account_id = "aws_cl4wla7bp00003u68ncsxkxz6"
  aws_region     = var.region
}

# 3. Point the allocated FQDN at the ALB via A-ALIAS. ALB requires aliasing
#    (not CNAME) at the apex of the allocated name; ALIAS works for both
#    the apex and subdomains.
resource "domains_dns_record" "default_alb" {
  domain_id = domains_app_domain.default.id
  name      = ""
  type      = "ALIAS"
  value = jsonencode({
    dns_name = aws_lb.main.dns_name
    zone_id  = aws_lb.main.zone_id
  })
}

# --------------------------------------------------------------------------
# Customer custom domain (optional, opt-in via demo_domain variable)
# --------------------------------------------------------------------------
# Issues a per-instance ACM cert for the user's chosen FQDN. The user must
# add the ACM validation CNAMEs to their own DNS provider — until then the
# cert sits PENDING_VALIDATION. Once ACM ISSUEs, api-go's reconciler attaches
# it to the listener as an additional SNI cert (via listener_arn).
resource "domains_module_certificate" "custom" {
  aws_account_id = "aws_cl4wla7bp00003u68ncsxkxz6"
  aws_region     = var.region
  domains        = [var.demo_domain]
  listener_arn   = aws_lb_listener.https.arn
}

output "ravion_default_domain" {
  description = "Auto-provisioned default URL for the service. HTTPS works immediately."
  value       = "https://${domains_app_domain.default.domain}"
}

output "ravion_cluster_cert_arn" {
  value = domains_cluster_certificate.default.cert_arn
}

output "ravion_custom_cert_status" {
  description = "PENDING_VALIDATION until the user adds the ACM CNAMEs to their DNS; then ISSUED."
  value       = domains_module_certificate.custom.status
}
