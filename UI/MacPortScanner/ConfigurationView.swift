import SwiftUI

struct ConfigurationView: View {
    @EnvironmentObject var scannerManager: ScannerManager
    @State private var batchSize = 1000
    @State private var timeout = 3.0
    @State private var maxRetries = 1
    @State private var retryDelay = 0.1
    @State private var delayBetweenBatches = 0.01
    @State private var detectServices = true
    @State private var scanUdp = false
    @State private var randomizePorts = false
    @State private var resolveHostnames = true
    @State private var maxIpsFromCidr = 1024
    @State private var selectedPreset = "Custom"
    
    let presets = ["Fast", "Balanced", "Thorough", "Stealth", "Custom"]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Scan Configuration")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Preset selection
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Presets")
                            .font(.headline)
                        
                        Picker("Preset", selection: $selectedPreset) {
                            ForEach(presets, id: \.self) { preset in
                                Text(preset).tag(preset)
                            }
                        }
                        .pickerStyle(.segmented)
                        .onChange(of: selectedPreset) { _, newValue in
                            applyPreset(newValue)
                        }
                        
                        Text(presetDescription(selectedPreset))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Divider()
                    
                    // Performance settings
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Performance")
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            ConfigSlider(
                                title: "Batch Size",
                                value: $batchSize,
                                range: 10...5000,
                                step: 10,
                                description: "Number of ports to scan concurrently"
                            )
                            
                            ConfigSlider(
                                title: "Timeout (seconds)",
                                value: $timeout,
                                range: 0.1...30.0,
                                step: 0.1,
                                description: "Maximum time to wait for each port response"
                            )
                            
                            ConfigSlider(
                                title: "Max Retries",
                                value: Binding(
                                    get: { Double(maxRetries) },
                                    set: { maxRetries = Int($0) }
                                ),
                                range: 1...10,
                                step: 1,
                                description: "Number of retry attempts for each port"
                            )
                            
                            ConfigSlider(
                                title: "Retry Delay (seconds)",
                                value: $retryDelay,
                                range: 0.01...2.0,
                                step: 0.01,
                                description: "Delay between retry attempts"
                            )
                            
                            ConfigSlider(
                                title: "Batch Delay (seconds)",
                                value: $delayBetweenBatches,
                                range: 0.001...1.0,
                                step: 0.001,
                                description: "Delay between port batches"
                            )
                        }
                    }
                    
                    Divider()
                    
                    // Feature settings
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Features")
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            ConfigToggle(
                                title: "Detect Services",
                                isOn: $detectServices,
                                description: "Attempt to identify services running on open ports"
                            )
                            
                            ConfigToggle(
                                title: "Scan UDP Ports",
                                isOn: $scanUdp,
                                description: "Include UDP port scanning (slower but more comprehensive)"
                            )
                            
                            ConfigToggle(
                                title: "Randomize Port Order",
                                isOn: $randomizePorts,
                                description: "Scan ports in random order for stealth"
                            )
                            
                            ConfigToggle(
                                title: "Resolve Hostnames",
                                isOn: $resolveHostnames,
                                description: "Resolve IP addresses to hostnames when possible"
                            )
                        }
                    }
                    
                    Divider()
                    
                    // Advanced settings
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Advanced")
                            .font(.headline)
                        
                        ConfigSlider(
                            title: "Max IPs from CIDR",
                            value: Binding(
                                get: { Double(maxIpsFromCidr) },
                                set: { maxIpsFromCidr = Int($0) }
                            ),
                            range: 1...10000,
                            step: 1,
                            description: "Maximum number of IP addresses to scan from CIDR ranges"
                        )
                    }
                    
                    Divider()
                    
                    // System optimization
                    VStack(alignment: .leading, spacing: 16) {
                        Text("System Optimization")
                            .font(.headline)
                        
                        Button("Optimize for Current System") {
                            optimizeForSystem()
                        }
                        .buttonStyle(.borderedProminent)
                        
                        Text("Automatically adjusts settings based on your system's capabilities")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
            }
            
            // Action buttons
            HStack {
                Button("Reset to Defaults") {
                    resetToDefaults()
                }
                
                Spacer()
                
                Button("Apply Configuration") {
                    applyConfiguration()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .onAppear {
            loadCurrentConfiguration()
        }
    }
    
    private func applyPreset(_ preset: String) {
        switch preset {
        case "Fast":
            batchSize = 2000
            timeout = 1.0
            maxRetries = 1
            retryDelay = 0.05
            delayBetweenBatches = 0.005
            detectServices = false
            scanUdp = false
            randomizePorts = false
            
        case "Balanced":
            batchSize = 1000
            timeout = 3.0
            maxRetries = 1
            retryDelay = 0.1
            delayBetweenBatches = 0.01
            detectServices = true
            scanUdp = false
            randomizePorts = false
            
        case "Thorough":
            batchSize = 500
            timeout = 5.0
            maxRetries = 3
            retryDelay = 0.2
            delayBetweenBatches = 0.05
            detectServices = true
            scanUdp = true
            randomizePorts = false
            
        case "Stealth":
            batchSize = 100
            timeout = 10.0
            maxRetries = 1
            retryDelay = 0.5
            delayBetweenBatches = 1.0
            detectServices = true
            scanUdp = false
            randomizePorts = true
            
        case "Custom":
            break
        }
    }
    
    private func presetDescription(_ preset: String) -> String {
        switch preset {
        case "Fast":
            return "Optimized for speed with minimal timeouts and large batch sizes"
        case "Balanced":
            return "Good balance between speed and accuracy for most use cases"
        case "Thorough":
            return "Comprehensive scanning with service detection and UDP support"
        case "Stealth":
            return "Slow and careful scanning to avoid detection"
        case "Custom":
            return "Manually configured settings"
        default:
            return ""
        }
    }
    
    private func loadCurrentConfiguration() {
        // Load current configuration from scanner manager
        // This would typically come from the Rust backend
    }
    
    private func applyConfiguration() {
        let config = ScanConfig(
            batchSize: batchSize,
            timeout: timeout,
            maxRetries: UInt8(maxRetries),
            retryDelay: retryDelay,
            delayBetweenBatches: delayBetweenBatches,
            detectServices: detectServices,
            scanUdp: scanUdp,
            randomizePorts: randomizePorts,
            resolveHostnames: resolveHostnames,
            maxIpsFromCidr: maxIpsFromCidr
        )
        
        scannerManager.updateScanConfig(config)
        selectedPreset = "Custom"
    }
    
    private func resetToDefaults() {
        selectedPreset = "Balanced"
        applyPreset("Balanced")
    }
    
    private func optimizeForSystem() {
        // Get system information and optimize settings
        let processInfo = ProcessInfo.processInfo
        let physicalMemory = processInfo.physicalMemory
        let processorCount = processInfo.processorCount
        
        // Adjust batch size based on available memory and CPU cores
        let memoryGB = physicalMemory / (1024 * 1024 * 1024)
        let optimalBatchSize = min(5000, max(100, Int(memoryGB) * processorCount * 50))
        
        batchSize = optimalBatchSize
        
        // Adjust timeout based on system performance
        if processorCount >= 8 {
            timeout = 2.0
        } else if processorCount >= 4 {
            timeout = 3.0
        } else {
            timeout = 5.0
        }
        
        selectedPreset = "Custom"
    }
}

struct ConfigSlider: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text(String(format: step < 1 ? "%.2f" : "%.0f", value))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .monospacedDigit()
            }
            
            Slider(value: $value, in: range, step: step)
            
            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct ConfigToggle: View {
    let title: String
    @Binding var isOn: Bool
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Toggle("", isOn: $isOn)
                    .labelsHidden()
            }
            
            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    ConfigurationView()
        .environmentObject(ScannerManager())
}