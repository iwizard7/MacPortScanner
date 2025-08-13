use serde::{Deserialize, Serialize};
use std::time::Duration;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ScanConfig {
    /// Number of ports to scan concurrently
    pub batch_size: usize,

    /// Timeout for each port connection attempt
    pub timeout: Duration,

    /// Maximum number of retry attempts for each port
    pub max_retries: u8,

    /// Delay between retry attempts
    pub retry_delay: Duration,

    /// Delay between batches to be respectful to target
    pub delay_between_batches: Duration,

    /// Whether to perform service detection
    pub detect_services: bool,

    /// Whether to scan UDP ports (TCP is always scanned)
    pub scan_udp: bool,

    /// Whether to randomize port order
    pub randomize_ports: bool,

    /// Whether to resolve hostnames
    pub resolve_hostnames: bool,

    /// Maximum number of IPs to scan from CIDR ranges
    pub max_ips_from_cidr: usize,
}

impl Default for ScanConfig {
    fn default() -> Self {
        Self {
            batch_size: 1000,
            timeout: Duration::from_millis(3000),
            max_retries: 1,
            retry_delay: Duration::from_millis(100),
            delay_between_batches: Duration::from_millis(10),
            detect_services: true,
            scan_udp: false,
            randomize_ports: false,
            resolve_hostnames: true,
            max_ips_from_cidr: 1024,
        }
    }
}

impl ScanConfig {
    pub fn fast() -> Self {
        Self {
            batch_size: 2000,
            timeout: Duration::from_millis(1000),
            max_retries: 1,
            retry_delay: Duration::from_millis(50),
            delay_between_batches: Duration::from_millis(5),
            ..Default::default()
        }
    }

    pub fn thorough() -> Self {
        Self {
            batch_size: 500,
            timeout: Duration::from_millis(5000),
            max_retries: 3,
            retry_delay: Duration::from_millis(200),
            delay_between_batches: Duration::from_millis(50),
            detect_services: true,
            scan_udp: true,
            ..Default::default()
        }
    }

    pub fn stealth() -> Self {
        Self {
            batch_size: 100,
            timeout: Duration::from_millis(10000),
            max_retries: 1,
            retry_delay: Duration::from_millis(500),
            delay_between_batches: Duration::from_millis(1000),
            randomize_ports: true,
            ..Default::default()
        }
    }

    pub fn validate(&self) -> Result<(), String> {
        if self.batch_size == 0 {
            return Err("Batch size must be greater than 0".to_string());
        }

        if self.batch_size > 10000 {
            return Err("Batch size too large (max 10000)".to_string());
        }

        if self.timeout < Duration::from_millis(100) {
            return Err("Timeout too small (min 100ms)".to_string());
        }

        if self.timeout > Duration::from_secs(60) {
            return Err("Timeout too large (max 60s)".to_string());
        }

        if self.max_retries > 10 {
            return Err("Too many retries (max 10)".to_string());
        }

        Ok(())
    }

    pub fn optimize_for_system(&mut self) {
        // Get system information and optimize settings
        #[cfg(target_os = "macos")]
        {
            use std::process::Command;

            // Check available file descriptors
            if let Ok(output) = Command::new("ulimit").arg("-n").output() {
                if let Ok(limit_str) = String::from_utf8(output.stdout) {
                    if let Ok(limit) = limit_str.trim().parse::<usize>() {
                        // Use 80% of available file descriptors
                        let optimal_batch = (limit * 4 / 5).clamp(100, 5000);
                        self.batch_size = optimal_batch;
                    }
                }
            }

            // Check system load and adjust accordingly
            if let Ok(output) = Command::new("sysctl").arg("hw.ncpu").output() {
                if let Ok(cpu_str) = String::from_utf8(output.stdout) {
                    if let Some(cpu_count_str) = cpu_str.split(':').nth(1) {
                        if let Ok(cpu_count) = cpu_count_str.trim().parse::<usize>() {
                            // Adjust batch size based on CPU count
                            self.batch_size = (self.batch_size * cpu_count / 4).max(100);
                        }
                    }
                }
            }
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PresetConfig {
    pub name: String,
    pub description: String,
    pub config: ScanConfig,
}

impl PresetConfig {
    pub fn get_presets() -> Vec<PresetConfig> {
        vec![
            PresetConfig {
                name: "Fast".to_string(),
                description: "Quick scan with minimal timeouts".to_string(),
                config: ScanConfig::fast(),
            },
            PresetConfig {
                name: "Default".to_string(),
                description: "Balanced speed and accuracy".to_string(),
                config: ScanConfig::default(),
            },
            PresetConfig {
                name: "Thorough".to_string(),
                description: "Comprehensive scan with service detection".to_string(),
                config: ScanConfig::thorough(),
            },
            PresetConfig {
                name: "Stealth".to_string(),
                description: "Slow and careful to avoid detection".to_string(),
                config: ScanConfig::stealth(),
            },
        ]
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_default_config() {
        let config = ScanConfig::default();
        assert!(config.validate().is_ok());
    }

    #[test]
    fn test_fast_config() {
        let config = ScanConfig::fast();
        assert!(config.validate().is_ok());
        assert!(config.timeout < ScanConfig::default().timeout);
    }

    #[test]
    fn test_config_validation() {
        let mut config = ScanConfig::default();
        config.batch_size = 0;
        assert!(config.validate().is_err());
    }
}
