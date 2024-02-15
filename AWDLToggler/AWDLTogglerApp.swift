import SwiftUI
import Cocoa

@main
struct AWDLTogglerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            // Placeholder for any settings UI; might not be needed for a menu bar app.
            Text("Settings View")
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    var statusItem: NSStatusItem?
    var statusMenuItem: NSMenuItem? // Reference to dynamically update status

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(named: "Toggler")
            button.image?.isTemplate = true
        }

        constructMenu()
    }

    func constructMenu() {
        let menu = NSMenu()
        
        // Initialize the AWDL status menu item with a placeholder title
        statusMenuItem = NSMenuItem(title: "Status: Checking...", action: nil, keyEquivalent: "")
        statusMenuItem?.isEnabled = false
        menu.addItem(statusMenuItem!)
        
        menu.addItem(NSMenuItem(title: "Enable AWDL", action: #selector(enableAWDL), keyEquivalent: "e"))
        menu.addItem(NSMenuItem(title: "Disable AWDL", action: #selector(disableAWDL), keyEquivalent: "d"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(terminateApp), keyEquivalent: "q"))

        menu.delegate = self // Set AppDelegate as the menu delegate
        statusItem?.menu = menu
    }

    // NSMenuDelegate method to update the menu item just before the menu opens
    func menuWillOpen(_ menu: NSMenu) {
        statusMenuItem?.title = "Status: \(awdlStatus())"
    }

    func awdlStatus() -> String {
        let process = Process()
        let pipe = Pipe()

        process.launchPath = "/sbin/ifconfig"
        process.arguments = ["awdl0"]
        process.standardOutput = pipe
        process.standardError = pipe

        do {
            try process.run()
            process.waitUntilExit()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            
            return output.contains("status: active") ? "UP" : "DOWN"
        } catch {
            print("Failed to check AWDL status: \(error)")
            return "UNKNOWN"
        }
    }

    @objc func enableAWDL() {
        runHelperCommand(["enable"])
        // No need to explicitly call constructMenu() here as the menu will update automatically when clicked
    }
    
    @objc func disableAWDL() {
        runHelperCommand(["disable"])
        // No need to explicitly call constructMenu() here as the menu will update automatically when clicked
    }
    
    @objc func terminateApp() {
        NSApplication.shared.terminate(nil)
    }
    
    func runHelperCommand(_ arguments: [String]) {
        guard let helperURL = Bundle.main.url(forResource: "AWDLHelper", withExtension: nil) else {
            print("AWDLHelper not found.")
            return
        }
        
        let process = Process()
        let pipe = Pipe()
        
        process.executableURL = helperURL
        process.arguments = arguments
        process.standardOutput = pipe
        process.standardError = pipe
        
        do {
            try process.run()
            process.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            print(output)
        } catch {
            print("Failed to run AWDLHelper: \(error)")
        }
    }
}

