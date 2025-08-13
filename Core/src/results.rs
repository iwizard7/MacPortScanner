use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::net::IpAddr;
use std::time::Duration;
use uuid::Uuid;

use crate::config::ScanConfig;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ScanResult {
    pub id: String,
    pub target: String,
    pub results: HashMap<IpAddr, Vec<PortStatus>>,
    pub duration: Duration,
    pub timestamp: DateTime<Utc>,
    pub scan_config: ScanConfig,
}

impl ScanResult {
    pub fn new(target: String, scan_config: ScanConfig) -> Self {
        Self {
            id: Uuid::new_v4().to_string(),
            target,
            results: HashMap::new(),
            duration: Duration::ZERO,
            timestamp: Utc::now(),
            scan_config,
        }
    }

    pub fn get_open_ports(&self) -> Vec<(IpAddr, u16)> {
        let mut open_ports = Vec::new();
        for (ip, ports) in &self.results {
            for port in ports {
                if port.is_open {
                    open_ports.push((*ip, port.port));
                }
            }
        }
        open_ports.sort_by_key(|(_, port)| *port);
        open_ports
    }

    pub fn get_total_ports_scanned(&self) -> usize {
        self.results.values().map(|ports| ports.len()).sum()
    }

    pub fn get_total_open_ports(&self) -> usize {
        self.results
            .values()
            .flat_map(|ports| ports.iter())
            .filter(|port| port.is_open)
            .count()
    }

    pub fn get_services(&self) -> HashMap<String, Vec<(IpAddr, u16)>> {
        let mut services = HashMap::new();

        for (ip, ports) in &self.results {
            for port in ports {
                if port.is_open {
                    if let Some(service) = &port.service {
                        services
                            .entry(service.clone())
                            .or_insert_with(Vec::new)
                            .push((*ip, port.port));
                    }
                }
            }
        }

        services
    }

    pub fn to_json(&self) -> Result<String, serde_json::Error> {
        serde_json::to_string_pretty(self)
    }

    pub fn to_csv(&self) -> String {
        let mut csv = String::from("IP,Port,Status,Service,ResponseTime,Attempts\n");

        for (ip, ports) in &self.results {
            for port in ports {
                csv.push_str(&format!(
                    "{},{},{},{},{},{}\n",
                    ip,
                    port.port,
                    if port.is_open { "Open" } else { "Closed" },
                    port.service.as_deref().unwrap_or("Unknown"),
                    port.response_time.as_millis(),
                    port.attempts
                ));
            }
        }

        csv
    }

    pub fn to_xml(&self) -> String {
        let mut xml = String::from("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n");
        xml.push_str("<scan_result>\n");
        xml.push_str(&format!("  <id>{}</id>\n", self.id));
        xml.push_str(&format!("  <target>{}</target>\n", self.target));
        xml.push_str(&format!(
            "  <timestamp>{}</timestamp>\n",
            self.timestamp.to_rfc3339()
        ));
        xml.push_str(&format!(
            "  <duration_ms>{}</duration_ms>\n",
            self.duration.as_millis()
        ));

        xml.push_str("  <results>\n");
        for (ip, ports) in &self.results {
            xml.push_str(&format!("    <host ip=\"{}\">\n", ip));
            for port in ports {
                xml.push_str(&format!(
                    "      <port number=\"{}\" status=\"{}\" service=\"{}\" response_time_ms=\"{}\" attempts=\"{}\"/>\n",
                    port.port,
                    if port.is_open { "open" } else { "closed" },
                    port.service.as_deref().unwrap_or("unknown"),
                    port.response_time.as_millis(),
                    port.attempts
                ));
            }
            xml.push_str("    </host>\n");
        }
        xml.push_str("  </results>\n");
        xml.push_str("</scan_result>\n");

        xml
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PortStatus {
    pub port: u16,
    pub is_open: bool,
    pub service: Option<String>,
    pub response_time: Duration,
    pub attempts: u8,
}

impl PortStatus {
    pub fn new(port: u16) -> Self {
        Self {
            port,
            is_open: false,
            service: None,
            response_time: Duration::ZERO,
            attempts: 0,
        }
    }

    pub fn open(port: u16, service: Option<String>, response_time: Duration, attempts: u8) -> Self {
        Self {
            port,
            is_open: true,
            service,
            response_time,
            attempts,
        }
    }

    pub fn closed(port: u16, response_time: Duration, attempts: u8) -> Self {
        Self {
            port,
            is_open: false,
            service: None,
            response_time,
            attempts,
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ScanStatistics {
    pub total_scans: u64,
    pub total_ports_scanned: u64,
    pub total_open_ports: u64,
    pub total_time: Duration,
    pub average_scan_time: Duration,
    pub fastest_scan: Duration,
    pub slowest_scan: Duration,
}

impl ScanStatistics {
    pub fn new() -> Self {
        Self {
            total_scans: 0,
            total_ports_scanned: 0,
            total_open_ports: 0,
            total_time: Duration::ZERO,
            average_scan_time: Duration::ZERO,
            fastest_scan: Duration::MAX,
            slowest_scan: Duration::ZERO,
        }
    }

    pub fn update(&mut self, scan_result: &ScanResult) {
        self.total_scans += 1;
        self.total_ports_scanned += scan_result.get_total_ports_scanned() as u64;
        self.total_open_ports += scan_result.get_total_open_ports() as u64;
        self.total_time += scan_result.duration;

        if scan_result.duration < self.fastest_scan {
            self.fastest_scan = scan_result.duration;
        }

        if scan_result.duration > self.slowest_scan {
            self.slowest_scan = scan_result.duration;
        }

        self.average_scan_time = self.total_time / self.total_scans as u32;
    }

    pub fn ports_per_second(&self) -> f64 {
        if self.total_time.as_secs_f64() > 0.0 {
            self.total_ports_scanned as f64 / self.total_time.as_secs_f64()
        } else {
            0.0
        }
    }

    pub fn success_rate(&self) -> f64 {
        if self.total_ports_scanned > 0 {
            self.total_open_ports as f64 / self.total_ports_scanned as f64 * 100.0
        } else {
            0.0
        }
    }
}

impl Default for ScanStatistics {
    fn default() -> Self {
        Self::new()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_scan_result_creation() {
        let config = ScanConfig::default();
        let result = ScanResult::new("127.0.0.1".to_string(), config);
        assert!(!result.id.is_empty());
        assert_eq!(result.target, "127.0.0.1");
    }

    #[test]
    fn test_port_status() {
        let port = PortStatus::open(80, Some("HTTP".to_string()), Duration::from_millis(100), 1);
        assert!(port.is_open);
        assert_eq!(port.service, Some("HTTP".to_string()));
    }

    #[test]
    fn test_statistics() {
        let mut stats = ScanStatistics::new();
        let config = ScanConfig::default();
        let mut result = ScanResult::new("127.0.0.1".to_string(), config);
        result.duration = Duration::from_secs(1);

        stats.update(&result);
        assert_eq!(stats.total_scans, 1);
    }
}
