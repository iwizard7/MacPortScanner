import SwiftUI
import Charts

struct ContentView: View {
    @EnvironmentObject var scannerManager: ScannerManager
    @State private var targetHost = ""
    @State private var portRange = "1-1000"
    @State private var selectedPreset = "Balanced"
    @State private var showingResults = false
    @State private var showingHistory = false
    @State private var showingVisualization = false
    @State private var showingConfiguration = false
    
    let presets = ["Fast", "Balanced", "Thorough", "Stealth"]
    
    var body: some View {
        NavigationSplitView {
            // Sidebar
            VStack(alignment: .leading, spacing: 20) {
                // Logo and title
                VStack {
                    Image(systemName: "network")
                        .font(.system(size: 40))
                        .foregroundColor(.accentColor)
                    Text("MacPortScanner")
                        .font(.title2)
                        .fontWeight(.bold)
                }
                .frame(maxWidth: .infinity)
                .padding(.top)
                
                Divider()
                
                // Navigation
                VStack(alignment: .leading, spacing: 8) {
                    NavigationLink(destination: ScanView()) {
                        Label("New Scan", systemImage: "magnifyingglass")
                    }
                    .buttonStyle(.plain)
                    
                    NavigationLink(destination: HistoryView()) {
                        Label("History", systemImage: "clock")
                    }
                    .buttonStyle(.plain)
                    
                    NavigationLink(destination: VisualizationView()) {
                        Label("Visualization", systemImage: "chart.bar")
                    }
                    .buttonStyle(.plain)
                    
                    NavigationLink(destination: StatisticsView()) {
                        Label("Statistics", systemImage: "chart.line.uptrend.xyaxis")
                    }
                    .buttonStyle(.plain)
                }
                
                Divider()
                
                // Quick stats
                if let stats = scannerManager.statistics {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Quick Stats")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            Text("Total Scans:")
                            Spacer()
                            Text("\(stats.totalScans)")
                                .fontWeight(.medium)
                        }
                        
                        HStack {
                            Text("Ports/sec:")
                            Spacer()
                            Text(String(format: "%.1f", stats.portsPerSecond))
                                .fontWeight(.medium)
                        }
                        
                        HStack {
                            Text("Success Rate:")
                            Spacer()
                            Text(String(format: "%.1f%%", stats.successRate))
                                .fontWeight(.medium)
                        }
                    }
                    .font(.caption)
                }
                
                Spacer()
                
                // Status indicator
                HStack {
                    Circle()
                        .fill(scannerManager.isScanning ? .green : .gray)
                        .frame(width: 8, height: 8)
                    Text(scannerManager.isScanning ? "Scanning..." : "Ready")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .frame(width: 200)
            .background(Color(NSColor.controlBackgroundColor))
        } detail: {
            // Main content
            ScanView()
        }
        .onReceive(NotificationCenter.default.publisher(for: .scanCompleted)) { notification in
            if let result = notification.userInfo?["result"] as? ScanResult {
                scannerManager.currentScan = result
                scannerManager.scanHistory.append(result)
                scannerManager.isScanning = false
                showingResults = true
                
                // Send notification
                sendNotification(for: result)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .scanError)) { notification in
            if let error = notification.userInfo?["error"] as? String {
                scannerManager.errorMessage = error
                scannerManager.isScanning = false
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .statisticsUpdated)) { notification in
            if let stats = notification.userInfo?["statistics"] as? ScanStatistics {
                scannerManager.statistics = stats
            }
        }
        .sheet(isPresented: $showingResults) {
            if let result = scannerManager.currentScan {
                ScanResultView(result: result)
            }
        }
        .onAppear {
            scannerManager.getStatistics()
        }
    }
    
    private func sendNotification(for result: ScanResult) {
        let content = UNMutableNotificationContent()
        content.title = "Scan Completed"
        content.body = "Found \(result.totalOpenPorts) open ports on \(result.target)"
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request)
    }
}

struct ScanView: View {
    @EnvironmentObject var scannerManager: ScannerManager
    @State private var targetHost = ""
    @State private var portRange = "1-1000"
    @State private var selectedPreset = "Balanced"
    @State private var showingAdvanced = false
    @State private var customPorts = ""
    @State private var useCustomPorts = false
    
    let presets = ["Fast", "Balanced", "Thorough", "Stealth"]
    let commonPortRanges = [
        "1-1000": "Common ports (1-1000)",
        "1-65535": "All ports (1-65535)",
        "21,22,23,25,53,80,110,143,443,993,995": "Web & Mail",
        "3306,5432,1433,27017,6379": "Databases",
        "22,3389,5900": "Remote Access"
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack {
                VStack(alignment: .leading) {
                    Text("Port Scanner")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Text("Fast and reliable network port scanning")
                        .foregroundColor(.secondary)
                }
                Spacer()
                
                if scannerManager.isScanning {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            
            // Main form
            VStack(alignment: .leading, spacing: 16) {
                // Target input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Target")
                        .font(.headline)
                    
                    TextField("Enter IP address, hostname, or CIDR range", text: $targetHost)
                        .textFieldStyle(.roundedBorder)
                        .disabled(scannerManager.isScanning)
                    
                    Text("Examples: 192.168.1.1, google.com, 10.0.0.0/24")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Port configuration
                VStack(alignment: .leading, spacing: 8) {
                    Text("Ports")
                        .font(.headline)
                    
                    Toggle("Use custom port list", isOn: $useCustomPorts)
                    
                    if useCustomPorts {
                        TextField("Enter ports (e.g., 80,443,8080-8090)", text: $customPorts)
                            .textFieldStyle(.roundedBorder)
                            .disabled(scannerManager.isScanning)
                    } else {
                        Picker("Port Range", selection: $portRange) {
                            ForEach(Array(commonPortRanges.keys.sorted()), id: \.self) { key in
                                Text(commonPortRanges[key]!).tag(key)
                            }
                        }
                        .pickerStyle(.menu)
                        .disabled(scannerManager.isScanning)
                    }
                }
                
                // Scan preset
                VStack(alignment: .leading, spacing: 8) {
                    Text("Scan Profile")
                        .font(.headline)
                    
                    Picker("Preset", selection: $selectedPreset) {
                        ForEach(presets, id: \.self) { preset in
                            Text(preset).tag(preset)
                        }
                    }
                    .pickerStyle(.segmented)
                    .disabled(scannerManager.isScanning)
                    
                    Text(presetDescription(selectedPreset))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Advanced options
                DisclosureGroup("Advanced Options", isExpanded: $showingAdvanced) {
                    VStack(alignment: .leading, spacing: 12) {
                        Toggle("Scan UDP ports", isOn: .constant(false))
                        Toggle("Randomize port order", isOn: .constant(false))
                        Toggle("Resolve hostnames", isOn: .constant(true))
                        Toggle("Detect services", isOn: .constant(true))
                    }
                    .padding(.top, 8)
                }
                .disabled(scannerManager.isScanning)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(12)
            
            // Error message
            if let error = scannerManager.errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
            }
            
            Spacer()
            
            // Action buttons
            HStack {
                Button("Clear") {
                    targetHost = ""
                    portRange = "1-1000"
                    customPorts = ""
                    useCustomPorts = false
                    scannerManager.errorMessage = nil
                }
                .disabled(scannerManager.isScanning)
                
                Spacer()
                
                Button(scannerManager.isScanning ? "Scanning..." : "Start Scan") {
                    startScan()
                }
                .buttonStyle(.borderedProminent)
                .disabled(scannerManager.isScanning || targetHost.isEmpty)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
    
    private func startScan() {
        let ports = useCustomPorts ? customPorts : portRange
        scannerManager.scanTarget(targetHost, ports: ports)
    }
    
    private func presetDescription(_ preset: String) -> String {
        switch preset {
        case "Fast":
            return "Quick scan with minimal timeouts (1s timeout, 2000 batch size)"
        case "Balanced":
            return "Good balance of speed and accuracy (3s timeout, 1000 batch size)"
        case "Thorough":
            return "Comprehensive scan with service detection (5s timeout, 500 batch size)"
        case "Stealth":
            return "Slow and careful to avoid detection (10s timeout, 100 batch size)"
        default:
            return ""
        }
    }
}

struct HistoryView: View {
    @EnvironmentObject var scannerManager: ScannerManager
    @State private var selectedResult: ScanResult?
    @State private var showingExportSheet = false
    @State private var exportFormat: ExportFormat = .json
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Scan History")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button("Export") {
                    showingExportSheet = true
                }
                .disabled(selectedResult == nil)
                
                Button("Clear All") {
                    scannerManager.scanHistory.removeAll()
                }
                .disabled(scannerManager.scanHistory.isEmpty)
            }
            
            if scannerManager.scanHistory.isEmpty {
                ContentUnavailableView(
                    "No Scan History",
                    systemImage: "clock",
                    description: Text("Your completed scans will appear here")
                )
            } else {
                List(scannerManager.scanHistory, id: \.id, selection: $selectedResult) { result in
                    HistoryRowView(result: result)
                }
            }
        }
        .padding()
        .sheet(isPresented: $showingExportSheet) {
            if let result = selectedResult {
                ExportView(result: result, format: $exportFormat)
            }
        }
    }
}

struct HistoryRowView: View {
    let result: ScanResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(result.target)
                    .font(.headline)
                
                Spacer()
                
                Text(result.timestamp, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Label("\(result.totalOpenPorts) open", systemImage: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.caption)
                
                Label("\(result.totalPortsScanned) scanned", systemImage: "magnifyingglass")
                    .foregroundColor(.blue)
                    .font(.caption)
                
                Spacer()
                
                Text(String(format: "%.1fs", result.duration))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct StatisticsView: View {
    @EnvironmentObject var scannerManager: ScannerManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Statistics")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            if let stats = scannerManager.statistics {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 20) {
                    StatCard(title: "Total Scans", value: "\(stats.totalScans)", icon: "magnifyingglass")
                    StatCard(title: "Ports Scanned", value: "\(stats.totalPortsScanned)", icon: "network")
                    StatCard(title: "Open Ports Found", value: "\(stats.totalOpenPorts)", icon: "checkmark.circle")
                    StatCard(title: "Success Rate", value: String(format: "%.1f%%", stats.successRate), icon: "percent")
                    StatCard(title: "Avg Speed", value: String(format: "%.0f p/s", stats.portsPerSecond), icon: "speedometer")
                    StatCard(title: "Fastest Scan", value: String(format: "%.1fs", stats.fastestScan), icon: "timer")
                }
                
                Spacer()
            } else {
                ContentUnavailableView(
                    "No Statistics Available",
                    systemImage: "chart.line.uptrend.xyaxis",
                    description: Text("Statistics will appear after running scans")
                )
            }
        }
        .padding()
        .onAppear {
            scannerManager.getStatistics()
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.accentColor)
                Spacer()
            }
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }
}

struct ExportView: View {
    let result: ScanResult
    @Binding var format: ExportFormat
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Export Scan Results")
                .font(.title2)
                .fontWeight(.bold)
            
            Picker("Format", selection: $format) {
                ForEach(ExportFormat.allCases, id: \.self) { format in
                    Text(format.rawValue).tag(format)
                }
            }
            .pickerStyle(.segmented)
            
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                
                Spacer()
                
                Button("Export") {
                    exportFile()
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(width: 400, height: 200)
    }
    
    private func exportFile() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.init(filenameExtension: format.fileExtension)!]
        panel.nameFieldStringValue = "scan_\(result.target)_\(Date().timeIntervalSince1970).\(format.fileExtension)"
        
        if panel.runModal() == .OK, let url = panel.url {
            let content: String
            switch format {
            case .json:
                content = result.toJSON()
            case .csv:
                content = result.toCSV()
            case .xml:
                content = result.toXML()
            }
            
            try? content.write(to: url, atomically: true, encoding: .utf8)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(ScannerManager())
}