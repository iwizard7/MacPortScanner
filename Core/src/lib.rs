use std::ffi::{CStr, CString};
use std::os::raw::c_char;

pub mod scanner;
pub mod network;
pub mod config;
pub mod results;
pub mod bridge;

pub use scanner::*;
pub use network::*;
pub use config::*;
pub use results::*;

// C-compatible interface for Swift
#[no_mangle]
pub extern "C" fn scanner_create() -> *mut Scanner {
    let scanner = Box::new(Scanner::new());
    Box::into_raw(scanner)
}

#[no_mangle]
pub extern "C" fn scanner_destroy(scanner: *mut Scanner) {
    if !scanner.is_null() {
        unsafe {
            let _ = Box::from_raw(scanner);
        }
    }
}

#[no_mangle]
pub extern "C" fn scanner_scan_async(
    scanner: *mut Scanner,
    target: *const c_char,
    ports: *const c_char,
    callback: extern "C" fn(*const c_char),
) -> bool {
    if scanner.is_null() || target.is_null() {
        return false;
    }

    let target_str = unsafe { CStr::from_ptr(target).to_string_lossy().to_string() };
    
    let ports_str = if ports.is_null() {
        "1-65535".to_string()
    } else {
        unsafe { CStr::from_ptr(ports).to_string_lossy().to_string() }
    };

    std::thread::spawn(move || {
        let rt = tokio::runtime::Runtime::new().unwrap();
        rt.block_on(async {
            let mut scanner = Scanner::new();
            match scanner.scan_target(&target_str, &ports_str).await {
                Ok(results) => {
                    let json = serde_json::to_string(&results).unwrap_or_default();
                    let c_string = CString::new(json).unwrap_or_default();
                    callback(c_string.as_ptr());
                }
                Err(e) => {
                    let error_json = format!(r#"{{"error": "{}"}}"#, e);
                    let c_string = CString::new(error_json).unwrap_or_default();
                    callback(c_string.as_ptr());
                }
            }
        });
    });

    true
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_scanner_creation() {
        let scanner = Scanner::new();
        assert_eq!(scanner.config.batch_size, 1000);
    }

    #[test]
    fn test_config_validation() {
        let config = ScanConfig::default();
        assert!(config.validate().is_ok());
    }
}