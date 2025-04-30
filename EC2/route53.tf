resource "aws_route53_zone" "main" {
  name = "abd.pp.ua"

  tags = {
    Name = "r53-zone-abd.pp.ua"
  }
}

resource "aws_route53_record" "app" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "app.abd.pp.ua"
  type    = "A"

  alias {
    name                   = aws_lb.nginx.dns_name
    zone_id                = aws_lb.nginx.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "www" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "www.abd.pp.ua"
  type    = "CNAME"
  ttl     = 300
  records = ["abd.pp.ua"]
}

resource "aws_route53_record" "apex" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "abd.pp.ua"
  type    = "A"

  alias {
    name                   = aws_lb.nginx.dns_name
    zone_id                = aws_lb.nginx.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "mx" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "abd.pp.ua"
  type    = "MX"
  ttl     = 300
  records = [
    "10 mail.abd.pp.ua",
    "20 backup-mail.abd.pp.ua"
  ]
}

resource "aws_route53_record" "txt" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "abd.pp.ua"
  type    = "TXT"
  ttl     = 300
  records = ["v=spf1 include:_spf.abd.pp.ua ~all"]
}

output "name_servers" {
  value       = aws_route53_zone.main.name_servers
  description = "The name servers for the Route 53 hosted zone"
}

