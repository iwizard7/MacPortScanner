use std::collections::HashMap;
use std::net::{IpAddr, SocketAddr};
use std::sync::Arc;
use std::time::{Duration, Instant};
use tokio::net::TcpStream;
use tokio::time::timeout;
use futures::stream::{FuturesUnordered, StreamExt};
use serde::{Deserialize, Serialize};
use anyhow::{Result, anyhow};
use tracing::{debug, info, warn};

use crate::network::{resolve_target, parse_port_range};
use crate::results::{ScanResult, PortStatus, ScanStatistics};
use crate::config::ScanConfig;

#[derive(Debug, Clone)]
pub struct Scanner {
    config: ScanConfig,
    stats: Arc<tokio::sync::Mutex<ScanStatistics>>,
}

impl Scanner {
    pub fn new() -> Self {
        Self {
            config: ScanConfig::default(),
            stats: Arc::new(tokio::sync::Mutex::new(ScanStatistics::new())),
        }
    }

    pub fn with_config(config: ScanConfig) -> Self {
        Self {
            config,
            stats: Arc::new(tokio::sync::Mutex::new(ScanStatistics::new())),
        }
    }

    pub async fn scan_target(&mut self, target: &str, ports: &str) -> Result<ScanResult> {
        let start_time = Instant::now();
        
        // Resolve target to IP addresses
        let ips = resolve_target(target).await?;
        if ips.is_empty() {
            return Err(anyhow!("Could not resolve target: {}", target));
        }

        // Parse port range
        let port_list = parse_port_range(ports)?;
        if port_list.is_empty() {
            return Err(anyhow!("No valid ports specified"));
        }

        info!("Scanning {} IPs with {} ports", ips.len(), port_list.len());

        let mut all_results = HashMap::new();
        
        for ip in ips {
            let ip_results = self.scan_ip(ip, &port_list).await?;
            all_results.insert(ip, ip_results);
        }

        let duration = start_time.elapsed();
        
        // Update statistics
        {
            let mut stats = self.stats.lock().await;
            stats.total_scans += 1;
            stats.total_ports_scanned += port_list.len() as u64;
            stats.total_time += duration;
        }

        Ok(ScanResult {
            target: target.to_string(),
            results: all_results,
            duration,
            timestamp: chrono::Utc::now(),
            scan_config: self.config.clone(),
        })
    }

    async fn scan_ip(&self, ip: IpAddr, ports: &[u16]) -> Result<Vec<PortStatus>> {
        let mut futures = FuturesUnordered::new();
        let mut results = Vec::new();

        // Create batches to avoid overwhelming the system
        for chunk in ports.chunks(self.config.batch_size) {
            for &port in chunk {
                let socket_addr = SocketAddr::new(ip, port);
                futures.push(self.scan_port(socket_addr));
            }

            // Process current batch
            while let Some(result) = futures.next().await {
                results.push(result);
            }

            // Small delay between batches to be respectful
            if self.config.delay_between_batches > Duration::ZERO {
                tokio::time::sleep(self.config.delay_between_batches).await;
            }
        }

        Ok(results)
    }

    async fn scan_port(&self, socket_addr: SocketAddr) -> PortStatus {
        let start_time = Instant::now();
        
        for attempt in 1..=self.config.max_retries {
            match timeout(self.config.timeout, TcpStream::connect(socket_addr)).await {
                Ok(Ok(stream)) => {
                    drop(stream); // Close connection immediately
                    debug!("Port {} open on {}", socket_addr.port(), socket_addr.ip());
                    
                    return PortStatus {
                        port: socket_addr.port(),
                        is_open: true,
                        service: self.identify_service(socket_addr.port()),
                        response_time: start_time.elapsed(),
                        attempts: attempt,
                    };
                }
                Ok(Err(e)) => {
                    debug!("Port {} closed on {} (attempt {}): {}", 
                           socket_addr.port(), socket_addr.ip(), attempt, e);
                }
                Err(_) => {
                    debug!("Port {} timeout on {} (attempt {})", 
                           socket_addr.port(), socket_addr.ip(), attempt);
                }
            }

            // Small delay between retries
            if attempt < self.config.max_retries && self.config.retry_delay > Duration::ZERO {
                tokio::time::sleep(self.config.retry_delay).await;
            }
        }

        PortStatus {
            port: socket_addr.port(),
            is_open: false,
            service: None,
            response_time: start_time.elapsed(),
            attempts: self.config.max_retries,
        }
    }

    fn identify_service(&self, port: u16) -> Option<String> {
        // Common port to service mapping
        match port {
            21 => Some("FTP".to_string()),
            22 => Some("SSH".to_string()),
            23 => Some("Telnet".to_string()),
            25 => Some("SMTP".to_string()),
            53 => Some("DNS".to_string()),
            80 => Some("HTTP".to_string()),
            110 => Some("POP3".to_string()),
            143 => Some("IMAP".to_string()),
            443 => Some("HTTPS".to_string()),
            993 => Some("IMAPS".to_string()),
            995 => Some("POP3S".to_string()),
            3389 => Some("RDP".to_string()),
            5432 => Some("PostgreSQL".to_string()),
            3306 => Some("MySQL".to_string()),
            1433 => Some("MSSQL".to_string()),
            6379 => Some("Redis".to_string()),
            27017 => Some("MongoDB".to_string()),
            _ => None,
        }
    }

    pub async fn get_statistics(&self) -> ScanStatistics {
        self.stats.lock().await.clone()
    }

    pub fn update_config(&mut self, config: ScanConfig) {
        self.config = config;
    }
}

impl Default for Scanner {
    fn default() -> Self {
        Self::new()
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use tokio::test;

    #[test]
    async fn test_scanner_creation() {
        let scanner = Scanner::new();
        assert_eq!(scanner.config.batch_size, 1000);
    }

    #[test]
    async fn test_localhost_scan() {
        let mut scanner = Scanner::new();
        let result = scanner.scan_target("127.0.0.1", "80,443").await;
        assert!(result.is_ok());
    }
}