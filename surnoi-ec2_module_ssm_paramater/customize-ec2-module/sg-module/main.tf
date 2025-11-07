resource "aws_security_group" "this" {
  for_each = var.security_groups

  name        = each.value.name
  description = each.value.description
  vpc_id      = var.vpc_id

  # Combine defined ingress with SSH rules (from allowed IPs and Jenkins SG)
  dynamic "ingress" {
    for_each = concat(
      each.value.ingress,
      [
        {
          from_port   = 22
          to_port     = 22
          protocol    = "tcp"
          cidr_blocks = var.allowed_ips
        }
      ]
    )
    content {
      from_port        = ingress.value.from_port
      to_port          = ingress.value.to_port
      protocol         = ingress.value.protocol
      cidr_blocks      = lookup(ingress.value, "cidr_blocks", null)
      security_groups  = lookup(ingress.value, "security_groups", null)
    }
  }

  dynamic "egress" {
    for_each = each.value.egress
    content {
      from_port   = egress.value.from_port
      to_port     = egress.value.to_port
      protocol    = egress.value.protocol
      cidr_blocks = egress.value.cidr_blocks
    }
  }

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-${each.key}-sg"
  })
}
