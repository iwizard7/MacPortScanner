import Foundation
import Combine

// C function declarations from Rust library
@_silgen_name("init_scanner")
func initScanner() -> Bool

@_silgen_name("cleanup_scanner")
func cleanupScanner()

@_silgen_name("scan_target_async")
func scanTargetAsync(
    _ target: UnsafePointer<CChar>,
    _ ports: UnsafePointer<CChar>?,
    _ callback: @escaping @convention(c) (UnsafePointer<CChar>) -> Void
) -> Bool

@_silgen_name("update_config")
func updateConfig(_ configJson: UnsafePointer<CChar>) -> Bool

@_silgen_name("get_statistics")
func getStatistics(_ callback: @escaping @convention(c) (UnsafePointer<CChar>) -> Void) -> Bool

@_silgen_name("get_preset_configs")
func getPresetConfigs() -> UnsafePointer<CChar>?

@_silgen_name("free_string")
func freeString(_ string: UnsafeMutablePointer<CChar>)

// Swift wrapper for the Rust scanner
class ScannerManager: ObservableObject {
    @Published var isScanning = false
    @Published var currentScan: ScanResult?
    @Published var scanHistory: [ScanResult] = []
    @Published var statistics: ScanStatistics?
    @Published var errorMessage: String?
    
    private var scanResultSubject = PassthroughSubject<ScanResult, Never>()
    private var cancellables = Set<AnyCancellable>()
    
    var scanResultPublisher: AnyPublisher<ScanResult, Never> {
        scanResultSubject.eraseToAnyPublisher()
    }
    
    init() {
        setupCallbacks()
    }
    
    deinit {
        cleanupScanner()
    }
    
    func initialize() -> Bool {
        return initScanner()
    }
    
    func scanTarget(_ target: String, ports: String = "1-1000") {
        guard !isScanning else { return }
        
        DispatchQueue.main.async {
            self.isScanning = true
            self.errorMessage = nil
        }
        
        let targetCString = target.cString(using: .utf8)!
        let portsCString = ports.cString(using: .utf8)!
        
        let success = targetCString.withUnsafeBufferPointer { targetPtr in
            portsCString.withUnsafeBufferPointer { portsPtr in
                scanTargetAsync(targetPtr.baseAddress!, portsPtr.baseAddress!, scanCallback)
            }
        }
        
        if !success {
            DispatchQueue.main.async {
                self.isScanning = false
                self.errorMessage = "Failed to start scan"
            }
        }
    }
    
    func updateScanConfig(_ config: ScanConfig) {
        do {
            let configData = try JSONEncoder().encode(config)
            let configString = String(data: configData, encoding: .utf8)!
            let configCString = configString.cString(using: .utf8)!
            
            configCString.withUnsafeBufferPointer { configPtr in
                _ = updateConfig(configPtr.baseAddress!)
            }
        } catch {
            print("Failed to encode config: \(error)")
        }
    }
    
    func getStatistics() {
        _ = getStatistics(statisticsCallback)
    }
    
    func exportResults(_ result: ScanResult, format: ExportFormat) -> String {
        switch format {
        case .json:
            return result.toJSON()
        case .csv:
            return result.toCSV()
        case .xml:
            return result.toXML()
        }
    }
    
    private func setupCallbacks() {
        // Setup any additional callback handling if needed
    }
}

// Global callback functions (must be global for C interop)
let scanCallback: @convention(c) (UnsafePointer<CChar>) -> Void = { resultPtr in
    let resultString = String(cString: resultPtr)
    
    DispatchQueue.main.async {
        if let data = resultString.data(using: .utf8) {
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let error = json["error"] as? String {
                    // Handle error
                    NotificationCenter.default.post(
                        name: .scanError,
                        object: nil,
                        userInfo: ["error": error]
                    )
                } else {
                    // Handle successful result
                    let result = try JSONDecoder().decode(ScanResult.self, from: data)
                    NotificationCenter.default.post(
                        name: .scanCompleted,
                        object: nil,
                        userInfo: ["result": result]
                    )
                }
            } catch {
                NotificationCenter.default.post(
                    name: .scanError,
                    object: nil,
                    userInfo: ["error": "Failed to parse scan result: \(error)"]
                )
            }
        }
    }
}

let statisticsCallback: @convention(c) (UnsafePointer<CChar>) -> Void = { statsPtr in
    let statsString = String(cString: statsPtr)
    
    DispatchQueue.main.async {
        if let data = statsString.data(using: .utf8) {
            do {
                let stats = try JSONDecoder().decode(ScanStatistics.self, from: data)
                NotificationCenter.default.post(
                    name: .statisticsUpdated,
                    object: nil,
                    userInfo: ["statistics": stats]
                )
            } catch {
                print("Failed to parse statistics: \(error)")
            }
        }
    }
}

// Notification names
extension Notification.Name {
    static let scanCompleted = Notification.Name("scanCompleted")
    static let scanError = Notification.Name("scanError")
    static let statisticsUpdated = Notification.Name("statisticsUpdated")
}

// Data models matching Rust structs
struct ScanResult: Codable, Identifiable {
    let id: String
    let target: String
    let results: [String: [PortStatus]]
    let duration: TimeInterval
    let timestamp: Date
    let scanConfig: ScanConfig
    
    func toJSON() -> String {
        do {
            let data = try JSONEncoder().encode(self)
            return String(data: data, encoding: .utf8) ?? ""
        } catch {
            return ""
        }
    }
    
    func toCSV() -> String {
        var csv = "IP,Port,Status,Service,ResponseTime,Attempts\n"
        
        for (ip, ports) in results {
            for port in ports {
                csv += "\(ip),\(port.port),\(port.isOpen ? "Open" : "Closed"),\(port.service ?? "Unknown"),\(port.responseTime),\(port.attempts)\n"
            }
        }
        
        return csv
    }
    
    func toXML() -> String {
        var xml = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<scan_result>\n"
        xml += "  <id>\(id)</id>\n"
        xml += "  <target>\(target)</target>\n"
        xml += "  <timestamp>\(timestamp.ISO8601Format())</timestamp>\n"
        xml += "  <duration>\(duration)</duration>\n"
        xml += "  <results>\n"
        
        for (ip, ports) in results {
            xml += "    <host ip=\"\(ip)\">\n"
            for port in ports {
                xml += "      <port number=\"\(port.port)\" status=\"\(port.isOpen ? "open" : "closed")\" service=\"\(port.service ?? "unknown")\" response_time=\"\(port.responseTime)\" attempts=\"\(port.attempts)\"/>\n"
            }
            xml += "    </host>\n"
        }
        
        xml += "  </results>\n</scan_result>\n"
        return xml
    }
    
    var openPorts: [(String, Int)] {
        var openPorts: [(String, Int)] = []
        for (ip, ports) in results {
            for port in ports where port.isOpen {
                openPorts.append((ip, Int(port.port)))
            }
        }
        return openPorts.sorted { $0.1 < $1.1 }
    }
    
    var totalPortsScanned: Int {
        results.values.reduce(0) { $0 + $1.count }
    }
    
    var totalOpenPorts: Int {
        results.values.reduce(0) { total, ports in
            total + ports.filter { $0.isOpen }.count
        }
    }
}

struct PortStatus: Codable {
    let port: UInt16
    let isOpen: Bool
    let service: String?
    let responseTime: TimeInterval
    let attempts: UInt8
    
    private enum CodingKeys: String, CodingKey {
        case port
        case isOpen = "is_open"
        case service
        case responseTime = "response_time"
        case attempts
    }
}

struct ScanConfig: Codable {
    let batchSize: Int
    let timeout: TimeInterval
    let maxRetries: UInt8
    let retryDelay: TimeInterval
    let delayBetweenBatches: TimeInterval
    let detectServices: Bool
    let scanUdp: Bool
    let randomizePorts: Bool
    let resolveHostnames: Bool
    let maxIpsFromCidr: Int
    
    private enum CodingKeys: String, CodingKey {
        case batchSize = "batch_size"
        case timeout
        case maxRetries = "max_retries"
        case retryDelay = "retry_delay"
        case delayBetweenBatches = "delay_between_batches"
        case detectServices = "detect_services"
        case scanUdp = "scan_udp"
        case randomizePorts = "randomize_ports"
        case resolveHostnames = "resolve_hostnames"
        case maxIpsFromCidr = "max_ips_from_cidr"
    }
}

struct ScanStatistics: Codable {
    let totalScans: UInt64
    let totalPortsScanned: UInt64
    let totalOpenPorts: UInt64
    let totalTime: TimeInterval
    let averageScanTime: TimeInterval
    let fastestScan: TimeInterval
    let slowestScan: TimeInterval
    
    private enum CodingKeys: String, CodingKey {
        case totalScans = "total_scans"
        case totalPortsScanned = "total_ports_scanned"
        case totalOpenPorts = "total_open_ports"
        case totalTime = "total_time"
        case averageScanTime = "average_scan_time"
        case fastestScan = "fastest_scan"
        case slowestScan = "slowest_scan"
    }
    
    var portsPerSecond: Double {
        totalTime > 0 ? Double(totalPortsScanned) / totalTime : 0
    }
    
    var successRate: Double {
        totalPortsScanned > 0 ? Double(totalOpenPorts) / Double(totalPortsScanned) * 100 : 0
    }
}

enum ExportFormat: String, CaseIterable {
    case json = "JSON"
    case csv = "CSV"
    case xml = "XML"
    
    var fileExtension: String {
        switch self {
        case .json: return "json"
        case .csv: return "csv"
        case .xml: return "xml"
        }
    }
}