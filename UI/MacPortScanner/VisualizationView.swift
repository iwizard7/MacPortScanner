import SwiftUI
import Charts

struct VisualizationView: View {
    @EnvironmentObject var scannerManager: ScannerManager
    @State private var selectedTimeRange = TimeRange.lastWeek
    @State private var selectedMetric = Metric.portsScanned
    
    enum TimeRange: String, CaseIterable {
        case lastHour = "Last Hour"
        case lastDay = "Last Day"
        case lastWeek = "Last Week"
        case lastMonth = "Last Month"
        case all = "All Time"
    }
    
    enum Metric: String, CaseIterable {
        case portsScanned = "Ports Scanned"
        case openPorts = "Open Ports Found"
        case scanDuration = "Scan Duration"
        case successRate = "Success Rate"
    }
    
    var filteredResults: [ScanResult] {
        let now = Date()
        let cutoffDate: Date
        
        switch selectedTimeRange {
        case .lastHour:
            cutoffDate = now.addingTimeInterval(-3600)
        case .lastDay:
            cutoffDate = now.addingTimeInterval(-86400)
        case .lastWeek:
            cutoffDate = now.addingTimeInterval(-604800)
        case .lastMonth:
            cutoffDate = now.addingTimeInterval(-2592000)
        case .all:
            cutoffDate = Date.distantPast
        }
        
        return scannerManager.scanHistory.filter { $0.timestamp >= cutoffDate }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack {
                Text("Scan Visualization")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Spacer()
                
                HStack {
                    Picker("Time Range", selection: $selectedTimeRange) {
                        ForEach(TimeRange.allCases, id: \.self) { range in
                            Text(range.rawValue).tag(range)
                        }
                    }
                    .pickerStyle(.menu)
                    
                    Picker("Metric", selection: $selectedMetric) {
                        ForEach(Metric.allCases, id: \.self) { metric in
                            Text(metric.rawValue).tag(metric)
                        }
                    }
                    .pickerStyle(.menu)
                }
            }
            
            if filteredResults.isEmpty {
                ContentUnavailableView(
                    "No Data Available",
                    systemImage: "chart.bar",
                    description: Text("Run some scans to see visualization data")
                )
            } else {
                ScrollView {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 20) {
                        // Main time series chart
                        VStack(alignment: .leading) {
                            Text("Scan Activity Over Time")
                                .font(.headline)
                            
                            Chart(filteredResults, id: \.id) { result in
                                LineMark(
                                    x: .value("Time", result.timestamp),
                                    y: .value(selectedMetric.rawValue, getMetricValue(result, selectedMetric))
                                )
                                .foregroundStyle(.blue)
                                .symbol(.circle)
                            }
                            .frame(height: 200)
                        }
                        .padding()
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(12)
                        .gridCellColumns(2)
                        
                        // Target distribution
                        VStack(alignment: .leading) {
                            Text("Most Scanned Targets")
                                .font(.headline)
                            
                            let targetCounts = Dictionary(grouping: filteredResults, by: \.target)
                                .mapValues { $0.count }
                                .sorted { $0.value > $1.value }
                                .prefix(5)
                            
                            Chart(Array(targetCounts), id: \.key) { target, count in
                                BarMark(
                                    x: .value("Count", count),
                                    y: .value("Target", target)
                                )
                                .foregroundStyle(.green)
                            }
                            .frame(height: 200)
                        }
                        .padding()
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(12)
                        
                        // Port range heatmap
                        VStack(alignment: .leading) {
                            Text("Port Range Activity")
                                .font(.headline)
                            
                            let portRanges = getPortRangeData()
                            
                            Chart(portRanges, id: \.range) { data in
                                BarMark(
                                    x: .value("Range", data.range),
                                    y: .value("Scans", data.count)
                                )
                                .foregroundStyle(.orange)
                            }
                            .frame(height: 200)
                        }
                        .padding()
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(12)
                        
                        // Success rate over time
                        VStack(alignment: .leading) {
                            Text("Success Rate Trend")
                                .font(.headline)
                            
                            Chart(filteredResults, id: \.id) { result in
                                LineMark(
                                    x: .value("Time", result.timestamp),
                                    y: .value("Success Rate", Double(result.totalOpenPorts) / Double(result.totalPortsScanned) * 100)
                                )
                                .foregroundStyle(.purple)
                                .symbol(.square)
                            }
                            .frame(height: 200)
                        }
                        .padding()
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(12)
                        
                        // Performance metrics
                        VStack(alignment: .leading) {
                            Text("Performance Metrics")
                                .font(.headline)
                            
                            VStack(alignment: .leading, spacing: 12) {
                                MetricRow(
                                    title: "Average Scan Duration",
                                    value: String(format: "%.2fs", filteredResults.map(\.duration).reduce(0, +) / Double(filteredResults.count)),
                                    icon: "timer"
                                )
                                
                                MetricRow(
                                    title: "Total Ports Scanned",
                                    value: "\(filteredResults.reduce(0) { $0 + $1.totalPortsScanned })",
                                    icon: "network"
                                )
                                
                                MetricRow(
                                    title: "Total Open Ports",
                                    value: "\(filteredResults.reduce(0) { $0 + $1.totalOpenPorts })",
                                    icon: "checkmark.circle"
                                )
                                
                                MetricRow(
                                    title: "Average Success Rate",
                                    value: String(format: "%.1f%%", filteredResults.map { Double($0.totalOpenPorts) / Double($0.totalPortsScanned) * 100 }.reduce(0, +) / Double(filteredResults.count)),
                                    icon: "percent"
                                )
                            }
                        }
                        .padding()
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(12)
                        
                        // Network topology
                        VStack(alignment: .leading) {
                            Text("Network Overview")
                                .font(.headline)
                            
                            let uniqueIPs = Set(filteredResults.flatMap { $0.results.keys }).count
                            let totalOpenPorts = filteredResults.reduce(0) { $0 + $1.totalOpenPorts }
                            
                            VStack(spacing: 16) {
                                HStack {
                                    Image(systemName: "network")
                                        .font(.title)
                                        .foregroundColor(.blue)
                                    
                                    VStack(alignment: .leading) {
                                        Text("\(uniqueIPs)")
                                            .font(.title2)
                                            .fontWeight(.bold)
                                        Text("Unique IPs Scanned")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                }
                                
                                HStack {
                                    Image(systemName: "door.left.hand.open")
                                        .font(.title)
                                        .foregroundColor(.green)
                                    
                                    VStack(alignment: .leading) {
                                        Text("\(totalOpenPorts)")
                                            .font(.title2)
                                            .fontWeight(.bold)
                                        Text("Total Open Ports")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                }
                            }
                        }
                        .padding()
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(12)
                    }
                    .padding()
                }
            }
        }
        .padding()
    }
    
    private func getMetricValue(_ result: ScanResult, _ metric: Metric) -> Double {
        switch metric {
        case .portsScanned:
            return Double(result.totalPortsScanned)
        case .openPorts:
            return Double(result.totalOpenPorts)
        case .scanDuration:
            return result.duration
        case .successRate:
            return Double(result.totalOpenPorts) / Double(result.totalPortsScanned) * 100
        }
    }
    
    private func getPortRangeData() -> [PortRangeData] {
        let ranges = [
            (1...1023, "Well-known"),
            (1024...49151, "Registered"),
            (49152...65535, "Dynamic")
        ]
        
        return ranges.map { range, name in
            let count = filteredResults.reduce(0) { total, result in
                total + result.openPorts.filter { range.contains($0.1) }.count
            }
            return PortRangeData(range: name, count: count)
        }
    }
}

struct MetricRow: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.accentColor)
                .frame(width: 20)
            
            Text(title)
                .font(.caption)
            
            Spacer()
            
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
        }
    }
}

struct PortRangeData {
    let range: String
    let count: Int
}

// Network topology visualization
struct NetworkTopologyView: View {
    let results: [ScanResult]
    @State private var selectedNode: String?
    
    var networkNodes: [NetworkNode] {
        var nodes: [String: NetworkNode] = [:]
        
        for result in results {
            for (ip, ports) in result.results {
                let openPorts = ports.filter { $0.isOpen }.count
                
                if let existing = nodes[ip] {
                    nodes[ip] = NetworkNode(
                        id: ip,
                        openPorts: existing.openPorts + openPorts,
                        totalScans: existing.totalScans + 1
                    )
                } else {
                    nodes[ip] = NetworkNode(
                        id: ip,
                        openPorts: openPorts,
                        totalScans: 1
                    )
                }
            }
        }
        
        return Array(nodes.values)
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Network Topology")
                .font(.headline)
            
            GeometryReader { geometry in
                ZStack {
                    // Background grid
                    Path { path in
                        let spacing: CGFloat = 50
                        for x in stride(from: 0, through: geometry.size.width, by: spacing) {
                            path.move(to: CGPoint(x: x, y: 0))
                            path.addLine(to: CGPoint(x: x, y: geometry.size.height))
                        }
                        for y in stride(from: 0, through: geometry.size.height, by: spacing) {
                            path.move(to: CGPoint(x: 0, y: y))
                            path.addLine(to: CGPoint(x: geometry.size.width, y: y))
                        }
                    }
                    .stroke(Color.gray.opacity(0.2), lineWidth: 0.5)
                    
                    // Network nodes
                    ForEach(Array(networkNodes.enumerated()), id: \.element.id) { index, node in
                        let position = getNodePosition(index: index, total: networkNodes.count, in: geometry.size)
                        
                        Circle()
                            .fill(node.openPorts > 0 ? Color.red : Color.green)
                            .frame(width: max(20, min(60, CGFloat(node.openPorts) * 5)), height: max(20, min(60, CGFloat(node.openPorts) * 5)))
                            .position(position)
                            .overlay(
                                Text(node.id.components(separatedBy: ".").last ?? "")
                                    .font(.caption2)
                                    .foregroundColor(.white)
                                    .position(position)
                            )
                            .onTapGesture {
                                selectedNode = node.id
                            }
                    }
                }
            }
            .frame(height: 300)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
            
            if let selectedNode = selectedNode,
               let node = networkNodes.first(where: { $0.id == selectedNode }) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Selected: \(node.id)")
                        .font(.headline)
                    Text("Open Ports: \(node.openPorts)")
                    Text("Total Scans: \(node.totalScans)")
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
            }
        }
    }
    
    private func getNodePosition(index: Int, total: Int, in size: CGSize) -> CGPoint {
        let angle = Double(index) * 2 * .pi / Double(total)
        let radius = min(size.width, size.height) * 0.3
        let centerX = size.width / 2
        let centerY = size.height / 2
        
        return CGPoint(
            x: centerX + CGFloat(cos(angle)) * radius,
            y: centerY + CGFloat(sin(angle)) * radius
        )
    }
}

struct NetworkNode {
    let id: String
    let openPorts: Int
    let totalScans: Int
}

#Preview {
    VisualizationView()
        .environmentObject(ScannerManager())
}