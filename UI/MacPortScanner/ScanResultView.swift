import SwiftUI
import Charts

struct ScanResultView: View {
    let result: ScanResult
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab = 0
    @State private var searchText = ""
    @State private var showingExportSheet = false
    @State private var exportFormat: ExportFormat = .json
    
    var filteredOpenPorts: [(String, Int)] {
        if searchText.isEmpty {
            return result.openPorts
        } else {
            return result.openPorts.filter { ip, port in
                ip.contains(searchText) || String(port).contains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Scan Results")
                                .font(.title2)
                                .fontWeight(.bold)
                            Text(result.target)
                                .font(.title3)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing) {
                            Text(result.timestamp, style: .date)
                            Text(result.timestamp, style: .time)
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                    
                    // Quick stats
                    HStack(spacing: 20) {
                        StatBadge(
                            title: "Open Ports",
                            value: "\(result.totalOpenPorts)",
                            color: .green
                        )
                        
                        StatBadge(
                            title: "Total Scanned",
                            value: "\(result.totalPortsScanned)",
                            color: .blue
                        )
                        
                        StatBadge(
                            title: "Duration",
                            value: String(format: "%.1fs", result.duration),
                            color: .orange
                        )
                        
                        StatBadge(
                            title: "Success Rate",
                            value: String(format: "%.1f%%", Double(result.totalOpenPorts) / Double(result.totalPortsScanned) * 100),
                            color: .purple
                        )
                    }
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                
                Divider()
                
                // Tab view
                TabView(selection: $selectedTab) {
                    // Open Ports Tab
                    OpenPortsView(result: result, searchText: $searchText)
                        .tabItem {
                            Label("Open Ports", systemImage: "checkmark.circle")
                        }
                        .tag(0)
                    
                    // All Ports Tab
                    AllPortsView(result: result)
                        .tabItem {
                            Label("All Ports", systemImage: "list.bullet")
                        }
                        .tag(1)
                    
                    // Visualization Tab
                    VisualizationTabView(result: result)
                        .tabItem {
                            Label("Charts", systemImage: "chart.bar")
                        }
                        .tag(2)
                    
                    // Services Tab
                    ServicesView(result: result)
                        .tabItem {
                            Label("Services", systemImage: "server.rack")
                        }
                        .tag(3)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu("Export") {
                        Button("JSON") {
                            exportFormat = .json
                            showingExportSheet = true
                        }
                        Button("CSV") {
                            exportFormat = .csv
                            showingExportSheet = true
                        }
                        Button("XML") {
                            exportFormat = .xml
                            showingExportSheet = true
                        }
                    }
                }
            }
        }
        .frame(width: 800, height: 600)
        .sheet(isPresented: $showingExportSheet) {
            ExportView(result: result, format: $exportFormat)
        }
    }
}

struct StatBadge: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

struct OpenPortsView: View {
    let result: ScanResult
    @Binding var searchText: String
    
    var filteredOpenPorts: [(String, Int)] {
        if searchText.isEmpty {
            return result.openPorts
        } else {
            return result.openPorts.filter { ip, port in
                ip.contains(searchText) || String(port).contains(searchText)
            }
        }
    }
    
    var body: some View {
        VStack {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search ports or IPs...", text: $searchText)
                    .textFieldStyle(.plain)
                
                if !searchText.isEmpty {
                    Button("Clear") {
                        searchText = ""
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
            .padding()
            
            // Results list
            if filteredOpenPorts.isEmpty {
                ContentUnavailableView(
                    searchText.isEmpty ? "No Open Ports" : "No Results",
                    systemImage: searchText.isEmpty ? "xmark.circle" : "magnifyingglass",
                    description: Text(searchText.isEmpty ? "No open ports were found in this scan" : "Try adjusting your search terms")
                )
            } else {
                List(filteredOpenPorts, id: \.1) { ip, port in
                    OpenPortRow(ip: ip, port: port, result: result)
                }
            }
        }
    }
}

struct OpenPortRow: View {
    let ip: String
    let port: Int
    let result: ScanResult
    
    var portInfo: PortStatus? {
        result.results[ip]?.first { $0.port == port }
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("\(ip):\(port)")
                        .font(.headline)
                    
                    if let service = portInfo?.service {
                        Text(service)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.2))
                            .cornerRadius(4)
                    }
                }
                
                if let portInfo = portInfo {
                    HStack {
                        Text("Response: \(String(format: "%.0fms", portInfo.responseTime * 1000))")
                        Text("•")
                        Text("Attempts: \(portInfo.attempts)")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
        }
        .padding(.vertical, 4)
    }
}

struct AllPortsView: View {
    let result: ScanResult
    @State private var selectedIP: String?
    
    var allIPs: [String] {
        Array(result.results.keys).sorted()
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // IP list
            VStack(alignment: .leading) {
                Text("IP Addresses")
                    .font(.headline)
                    .padding()
                
                List(allIPs, id: \.self, selection: $selectedIP) { ip in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(ip)
                            .font(.headline)
                        
                        let ports = result.results[ip] ?? []
                        let openCount = ports.filter { $0.isOpen }.count
                        
                        Text("\(openCount) open / \(ports.count) total")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .frame(width: 200)
            
            Divider()
            
            // Port details
            if let selectedIP = selectedIP,
               let ports = result.results[selectedIP] {
                PortDetailsView(ip: selectedIP, ports: ports)
            } else {
                ContentUnavailableView(
                    "Select an IP Address",
                    systemImage: "network",
                    description: Text("Choose an IP from the list to view port details")
                )
            }
        }
        .onAppear {
            if selectedIP == nil && !allIPs.isEmpty {
                selectedIP = allIPs.first
            }
        }
    }
}

struct PortDetailsView: View {
    let ip: String
    let ports: [PortStatus]
    @State private var showOnlyOpen = false
    
    var filteredPorts: [PortStatus] {
        showOnlyOpen ? ports.filter { $0.isOpen } : ports
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Ports for \(ip)")
                    .font(.headline)
                
                Spacer()
                
                Toggle("Open only", isOn: $showOnlyOpen)
            }
            .padding()
            
            List(filteredPorts, id: \.port) { port in
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Port \(port.port)")
                                .font(.headline)
                            
                            if let service = port.service {
                                Text(service)
                                    .font(.caption)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.blue.opacity(0.2))
                                    .cornerRadius(4)
                            }
                        }
                        
                        HStack {
                            Text("Response: \(String(format: "%.0fms", port.responseTime * 1000))")
                            Text("•")
                            Text("Attempts: \(port.attempts)")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: port.isOpen ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(port.isOpen ? .green : .red)
                }
                .padding(.vertical, 2)
            }
        }
    }
}

struct VisualizationTabView: View {
    let result: ScanResult
    
    var portDistribution: [PortRange] {
        let ranges = [
            (1...1023, "Well-known"),
            (1024...49151, "Registered"),
            (49152...65535, "Dynamic")
        ]
        
        return ranges.map { range, name in
            let count = result.openPorts.filter { range.contains($0.1) }.count
            return PortRange(name: name, count: count, range: "\(range.lowerBound)-\(range.upperBound)")
        }
    }
    
    var serviceDistribution: [ServiceCount] {
        var services: [String: Int] = [:]
        
        for (_, ports) in result.results {
            for port in ports where port.isOpen {
                let service = port.service ?? "Unknown"
                services[service, default: 0] += 1
            }
        }
        
        return services.map { ServiceCount(name: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
            .prefix(10)
            .map { $0 }
    }
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 20) {
                // Port range distribution
                VStack(alignment: .leading) {
                    Text("Port Range Distribution")
                        .font(.headline)
                    
                    Chart(portDistribution, id: \.name) { item in
                        BarMark(
                            x: .value("Range", item.name),
                            y: .value("Count", item.count)
                        )
                        .foregroundStyle(.blue)
                    }
                    .frame(height: 200)
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(12)
                
                // Service distribution
                VStack(alignment: .leading) {
                    Text("Top Services")
                        .font(.headline)
                    
                    Chart(serviceDistribution, id: \.name) { item in
                        BarMark(
                            x: .value("Count", item.count),
                            y: .value("Service", item.name)
                        )
                        .foregroundStyle(.green)
                    }
                    .frame(height: 200)
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(12)
                
                // Response time distribution
                VStack(alignment: .leading) {
                    Text("Response Time Distribution")
                        .font(.headline)
                    
                    let responseTimes = result.results.values.flatMap { $0 }
                        .filter { $0.isOpen }
                        .map { $0.responseTime * 1000 }
                    
                    if !responseTimes.isEmpty {
                        Chart {
                            ForEach(Array(responseTimes.enumerated()), id: \.offset) { index, time in
                                LineMark(
                                    x: .value("Port", index),
                                    y: .value("Response Time (ms)", time)
                                )
                                .foregroundStyle(.orange)
                            }
                        }
                        .frame(height: 200)
                    } else {
                        Text("No response time data available")
                            .foregroundColor(.secondary)
                            .frame(height: 200)
                    }
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(12)
                
                // Scan timeline
                VStack(alignment: .leading) {
                    Text("Scan Summary")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Target:")
                            Spacer()
                            Text(result.target)
                                .fontWeight(.medium)
                        }
                        
                        HStack {
                            Text("Duration:")
                            Spacer()
                            Text(String(format: "%.2fs", result.duration))
                                .fontWeight(.medium)
                        }
                        
                        HStack {
                            Text("Ports/second:")
                            Spacer()
                            Text(String(format: "%.0f", Double(result.totalPortsScanned) / result.duration))
                                .fontWeight(.medium)
                        }
                        
                        HStack {
                            Text("Success rate:")
                            Spacer()
                            Text(String(format: "%.1f%%", Double(result.totalOpenPorts) / Double(result.totalPortsScanned) * 100))
                                .fontWeight(.medium)
                        }
                    }
                    .font(.caption)
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(12)
            }
            .padding()
        }
    }
}

struct ServicesView: View {
    let result: ScanResult
    
    var serviceGroups: [String: [(String, Int)]] {
        var groups: [String: [(String, Int)]] = [:]
        
        for (ip, ports) in result.results {
            for port in ports where port.isOpen {
                let service = port.service ?? "Unknown"
                groups[service, default: []].append((ip, Int(port.port)))
            }
        }
        
        return groups
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Detected Services")
                .font(.headline)
                .padding()
            
            if serviceGroups.isEmpty {
                ContentUnavailableView(
                    "No Services Detected",
                    systemImage: "server.rack",
                    description: Text("No service information available for open ports")
                )
            } else {
                List {
                    ForEach(Array(serviceGroups.keys.sorted()), id: \.self) { service in
                        Section(service) {
                            ForEach(serviceGroups[service]!, id: \.1) { ip, port in
                                HStack {
                                    Text("\(ip):\(port)")
                                        .font(.headline)
                                    
                                    Spacer()
                                    
                                    Button("Copy") {
                                        NSPasteboard.general.clearContents()
                                        NSPasteboard.general.setString("\(ip):\(port)", forType: .string)
                                    }
                                    .buttonStyle(.plain)
                                    .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

struct PortRange {
    let name: String
    let count: Int
    let range: String
}

struct ServiceCount {
    let name: String
    let count: Int
}

#Preview {
    ScanResultView(result: ScanResult(
        id: "test",
        target: "example.com",
        results: [:],
        duration: 1.5,
        timestamp: Date(),
        scanConfig: ScanConfig(
            batchSize: 1000,
            timeout: 3.0,
            maxRetries: 1,
            retryDelay: 0.1,
            delayBetweenBatches: 0.01,
            detectServices: true,
            scanUdp: false,
            randomizePorts: false,
            resolveHostnames: true,
            maxIpsFromCidr: 1024
        )
    ))
}