use std::ffi::{CStr, CString};
use std::os::raw::c_char;
use std::sync::Arc;
use tokio::sync::Mutex;
use serde_json;

use crate::{Scanner, ScanConfig, ScanResult};

// Global scanner instance for C interface
static mut SCANNER_INSTANCE: Option<Arc<Mutex<Scanner>>> = None;

#[no_mangle]
pub extern "C" fn init_scanner() -> bool {
    unsafe {
        SCANNER_INSTANCE = Some(Arc::new(Mutex::new(Scanner::new())));
    }
    true
}

#[no_mangle]
pub extern "C" fn cleanup_scanner() {
    unsafe {
        SCANNER_INSTANCE = None;
    }
}

#[no_mangle]
pub extern "C" fn scan_target_async(
    target: *const c_char,
    ports: *const c_char,
    callback: extern "C" fn(*const c_char),
) -> bool {
    if target.is_null() {
        return false;
    }

    let target_str = unsafe {
        match CStr::from_ptr(target).to_str() {
            Ok(s) => s.to_string(),
            Err(_) => return false,
        }
    };

    let ports_str = if ports.is_null() {
        "1-1000".to_string()
    } else {
        unsafe {
            match CStr::from_ptr(ports).to_str() {
                Ok(s) => s.to_string(),
                Err(_) => return false,
            }
        }
    };

    let scanner_arc = unsafe {
        match &SCANNER_INSTANCE {
            Some(scanner) => scanner.clone(),
            None => return false,
        }
    };

    tokio::spawn(async move {
        let mut scanner = scanner_arc.lock().await;
        match scanner.scan_target(&target_str, &ports_str).await {
            Ok(result) => {
                let json = match serde_json::to_string(&result) {
                    Ok(j) => j,
                    Err(e) => format!(r#"{{"error": "Serialization failed: {}"}}"#, e),
                };
                
                if let Ok(c_string) = CString::new(json) {
                    callback(c_string.as_ptr());
                }
            }
            Err(e) => {
                let error_json = format!(r#"{{"error": "{}"}}"#, e);
                if let Ok(c_string) = CString::new(error_json) {
                    callback(c_string.as_ptr());
                }
            }
        }
    });

    true
}

#[no_mangle]
pub extern "C" fn update_config(config_json: *const c_char) -> bool {
    if config_json.is_null() {
        return false;
    }

    let config_str = unsafe {
        match CStr::from_ptr(config_json).to_str() {
            Ok(s) => s,
            Err(_) => return false,
        }
    };

    let config: ScanConfig = match serde_json::from_str(config_str) {
        Ok(c) => c,
        Err(_) => return false,
    };

    if config.validate().is_err() {
        return false;
    }

    let scanner_arc = unsafe {
        match &SCANNER_INSTANCE {
            Some(scanner) => scanner.clone(),
            None => return false,
        }
    };

    tokio::spawn(async move {
        let mut scanner = scanner_arc.lock().await;
        scanner.update_config(config);
    });

    true
}

#[no_mangle]
pub extern "C" fn get_statistics(callback: extern "C" fn(*const c_char)) -> bool {
    let scanner_arc = unsafe {
        match &SCANNER_INSTANCE {
            Some(scanner) => scanner.clone(),
            None => return false,
        }
    };

    tokio::spawn(async move {
        let scanner = scanner_arc.lock().await;
        let stats = scanner.get_statistics().await;
        
        match serde_json::to_string(&stats) {
            Ok(json) => {
                if let Ok(c_string) = CString::new(json) {
                    callback(c_string.as_ptr());
                }
            }
            Err(e) => {
                let error_json = format!(r#"{{"error": "{}"}}"#, e);
                if let Ok(c_string) = CString::new(error_json) {
                    callback(c_string.as_ptr());
                }
            }
        }
    });

    true
}

#[no_mangle]
pub extern "C" fn get_preset_configs() -> *const c_char {
    use crate::config::PresetConfig;
    
    let presets = PresetConfig::get_presets();
    match serde_json::to_string(&presets) {
        Ok(json) => {
            match CString::new(json) {
                Ok(c_string) => {
                    // Note: This leaks memory, but it's necessary for C interop
                    // The caller should free this memory
                    c_string.into_raw()
                }
                Err(_) => std::ptr::null(),
            }
        }
        Err(_) => std::ptr::null(),
    }
}

#[no_mangle]
pub extern "C" fn free_string(s: *mut c_char) {
    if !s.is_null() {
        unsafe {
            let _ = CString::from_raw(s);
        }
    }
}

// Progress callback for real-time updates
type ProgressCallback = extern "C" fn(completed: u32, total: u32, current_target: *const c_char);

#[no_mangle]
pub extern "C" fn scan_with_progress(
    target: *const c_char,
    ports: *const c_char,
    progress_callback: ProgressCallback,
    result_callback: extern "C" fn(*const c_char),
) -> bool {
    if target.is_null() {
        return false;
    }

    let target_str = unsafe {
        match CStr::from_ptr(target).to_str() {
            Ok(s) => s.to_string(),
            Err(_) => return false,
        }
    };

    let ports_str = if ports.is_null() {
        "1-1000".to_string()
    } else {
        unsafe {
            match CStr::from_ptr(ports).to_str() {
                Ok(s) => s.to_string(),
                Err(_) => return false,
            }
        }
    };

    // This would require modifying the scanner to support progress callbacks
    // For now, we'll use the regular scan method
    scan_target_async(target, ports, result_callback)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_init_cleanup() {
        assert!(init_scanner());
        cleanup_scanner();
    }
}