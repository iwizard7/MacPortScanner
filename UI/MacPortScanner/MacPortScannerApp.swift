import SwiftUI
import UserNotifications

@main
struct MacPortScannerApp: App {
    @StateObject private var scannerManager = ScannerManager()
    @State private var showingPermissionAlert = false
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(scannerManager)
                .onAppear {
                    setupApp()
                }
                .alert("Network Access Required", isPresented: $showingPermissionAlert) {
                    Button("OK") { }
                } message: {
                    Text("This app requires network access to scan ports. Please grant permission in System Preferences.")
                }
        }
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unified)
        
        Settings {
            SettingsView()
                .environmentObject(scannerManager)
        }
    }
    
    private func setupApp() {
        // Request notification permissions
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error)")
            }
        }
        
        // Initialize scanner
        scannerManager.initialize()
    }
}

struct SettingsView: View {
    @EnvironmentObject var scannerManager: ScannerManager
    
    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem {
                    Label("General", systemImage: "gear")
                }
            
            ScanSettingsView()
                .tabItem {
                    Label("Scanning", systemImage: "network")
                }
                .environmentObject(scannerManager)
            
            NotificationSettingsView()
                .tabItem {
                    Label("Notifications", systemImage: "bell")
                }
        }
        .frame(width: 500, height: 400)
    }
}

struct GeneralSettingsView: View {
    @AppStorage("theme") private var selectedTheme = "auto"
    @AppStorage("showMenuBarIcon") private var showMenuBarIcon = true
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    
    var body: some View {
        Form {
            Section("Appearance") {
                Picker("Theme", selection: $selectedTheme) {
                    Text("Auto").tag("auto")
                    Text("Light").tag("light")
                    Text("Dark").tag("dark")
                }
                .pickerStyle(.segmented)
            }
            
            Section("System Integration") {
                Toggle("Show menu bar icon", isOn: $showMenuBarIcon)
                Toggle("Launch at login", isOn: $launchAtLogin)
            }
        }
        .padding()
    }
}

struct ScanSettingsView: View {
    @EnvironmentObject var scannerManager: ScannerManager
    @State private var batchSize = 1000
    @State private var timeout = 3.0
    @State private var maxRetries = 1
    
    var body: some View {
        Form {
            Section("Performance") {
                HStack {
                    Text("Batch Size:")
                    Spacer()
                    TextField("Batch Size", value: $batchSize, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 100)
                }
                
                HStack {
                    Text("Timeout (seconds):")
                    Spacer()
                    TextField("Timeout", value: $timeout, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 100)
                }
                
                HStack {
                    Text("Max Retries:")
                    Spacer()
                    TextField("Max Retries", value: $maxRetries, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 100)
                }
            }
            
            Section("Presets") {
                HStack {
                    Button("Fast") {
                        applyPreset(.fast)
                    }
                    Button("Balanced") {
                        applyPreset(.balanced)
                    }
                    Button("Thorough") {
                        applyPreset(.thorough)
                    }
                    Button("Stealth") {
                        applyPreset(.stealth)
                    }
                }
            }
        }
        .padding()
    }
    
    private func applyPreset(_ preset: ScanPreset) {
        switch preset {
        case .fast:
            batchSize = 2000
            timeout = 1.0
            maxRetries = 1
        case .balanced:
            batchSize = 1000
            timeout = 3.0
            maxRetries = 1
        case .thorough:
            batchSize = 500
            timeout = 5.0
            maxRetries = 3
        case .stealth:
            batchSize = 100
            timeout = 10.0
            maxRetries = 1
        }
    }
}

struct NotificationSettingsView: View {
    @AppStorage("notifyOnCompletion") private var notifyOnCompletion = true
    @AppStorage("notifyOnOpenPorts") private var notifyOnOpenPorts = true
    @AppStorage("soundEnabled") private var soundEnabled = true
    
    var body: some View {
        Form {
            Section("Notifications") {
                Toggle("Notify when scan completes", isOn: $notifyOnCompletion)
                Toggle("Notify when open ports found", isOn: $notifyOnOpenPorts)
                Toggle("Play sound", isOn: $soundEnabled)
            }
        }
        .padding()
    }
}

enum ScanPreset {
    case fast, balanced, thorough, stealth
}