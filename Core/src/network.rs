use anyhow::{anyhow, Result};
use cidr::IpCidr;
use hickory_resolver::{config::*, TokioAsyncResolver};
use std::net::IpAddr;
use std::str::FromStr;
use tracing::{debug, warn};

pub async fn resolve_target(target: &str) -> Result<Vec<IpAddr>> {
    let mut ips = Vec::new();

    // Check if it's already an IP address
    if let Ok(ip) = IpAddr::from_str(target) {
        ips.push(ip);
        return Ok(ips);
    }

    // Check if it's a CIDR notation
    if target.contains('/') {
        return resolve_cidr(target);
    }

    // Try to resolve as hostname
    match resolve_hostname(target).await {
        Ok(resolved_ips) => ips.extend(resolved_ips),
        Err(e) => {
            warn!("Failed to resolve hostname {}: {}", target, e);
            return Err(anyhow!("Could not resolve target: {}", target));
        }
    }

    Ok(ips)
}

async fn resolve_hostname(hostname: &str) -> Result<Vec<IpAddr>> {
    let resolver = TokioAsyncResolver::tokio(ResolverConfig::default(), ResolverOpts::default());

    let mut ips = Vec::new();

    // Try IPv4 resolution
    match resolver.ipv4_lookup(hostname).await {
        Ok(ipv4_response) => {
            for ipv4 in ipv4_response.iter() {
                ips.push(IpAddr::V4(ipv4.0));
            }
        }
        Err(e) => debug!("IPv4 resolution failed for {}: {}", hostname, e),
    }

    // Try IPv6 resolution
    match resolver.ipv6_lookup(hostname).await {
        Ok(ipv6_response) => {
            for ipv6 in ipv6_response.iter() {
                ips.push(IpAddr::V6(ipv6.0));
            }
        }
        Err(e) => debug!("IPv6 resolution failed for {}: {}", hostname, e),
    }

    if ips.is_empty() {
        return Err(anyhow!("No IP addresses found for hostname: {}", hostname));
    }

    Ok(ips)
}

fn resolve_cidr(cidr_str: &str) -> Result<Vec<IpAddr>> {
    let cidr = IpCidr::from_str(cidr_str).map_err(|e| anyhow!("Invalid CIDR notation: {}", e))?;

    let mut ips = Vec::new();

    match cidr {
        IpCidr::V4(v4_cidr) => {
            for addr in v4_cidr.iter() {
                ips.push(IpAddr::V4(addr.address()));
                // Limit to prevent memory issues with large ranges
                if ips.len() >= 65536 {
                    warn!("CIDR range too large, limiting to first 65536 addresses");
                    break;
                }
            }
        }
        IpCidr::V6(v6_cidr) => {
            // IPv6 ranges can be enormous, so we're more conservative
            let mut count = 0;
            for addr in v6_cidr.iter() {
                ips.push(IpAddr::V6(addr.address()));
                count += 1;
                if count >= 1024 {
                    warn!("IPv6 CIDR range too large, limiting to first 1024 addresses");
                    break;
                }
            }
        }
    }

    Ok(ips)
}

pub fn parse_port_range(ports_str: &str) -> Result<Vec<u16>> {
    let mut ports = Vec::new();

    for part in ports_str.split(',') {
        let part = part.trim();

        if part.contains('-') {
            // Range like "80-90"
            let range_parts: Vec<&str> = part.split('-').collect();
            if range_parts.len() != 2 {
                return Err(anyhow!("Invalid port range format: {}", part));
            }

            let start: u16 = range_parts[0]
                .parse()
                .map_err(|_| anyhow!("Invalid start port: {}", range_parts[0]))?;
            let end: u16 = range_parts[1]
                .parse()
                .map_err(|_| anyhow!("Invalid end port: {}", range_parts[1]))?;

            if start > end {
                return Err(anyhow!(
                    "Start port {} is greater than end port {}",
                    start,
                    end
                ));
            }

            for port in start..=end {
                ports.push(port);
            }
        } else {
            // Single port
            let port: u16 = part
                .parse()
                .map_err(|_| anyhow!("Invalid port number: {}", part))?;
            ports.push(port);
        }
    }

    // Remove duplicates and sort
    ports.sort_unstable();
    ports.dedup();

    Ok(ports)
}

pub fn get_common_ports() -> Vec<u16> {
    vec![
        21, 22, 23, 25, 53, 80, 110, 111, 135, 139, 143, 443, 993, 995, 1723, 3306, 3389, 5432,
        5900, 8080,
    ]
}

pub fn get_all_ports() -> Vec<u16> {
    (1..=65535).collect()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[tokio::test]
    async fn test_resolve_ip() {
        let result = resolve_target("127.0.0.1").await.unwrap();
        assert_eq!(result.len(), 1);
        assert!(matches!(result[0], IpAddr::V4(_)));
    }

    #[test]
    fn test_parse_single_port() {
        let ports = parse_port_range("80").unwrap();
        assert_eq!(ports, vec![80]);
    }

    #[test]
    fn test_parse_port_range() {
        let ports = parse_port_range("80-82").unwrap();
        assert_eq!(ports, vec![80, 81, 82]);
    }

    #[test]
    fn test_parse_mixed_ports() {
        let ports = parse_port_range("22,80-82,443").unwrap();
        assert_eq!(ports, vec![22, 80, 81, 82, 443]);
    }

    #[test]
    fn test_parse_cidr() {
        let ips = resolve_cidr("192.168.1.0/30").unwrap();
        assert_eq!(ips.len(), 4);
    }
}
