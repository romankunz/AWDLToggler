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

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(named: "Toggler") // Ensure this name matches your image set name in the asset catalog.
            button.image?.isTemplate = true // Consider making it a template image if it should adapt to light/dark mode.
        }

        constructMenu()
    }

    func constructMenu() {
        let menu = NSMenu()
        
        // Dynamically add the AWDL status menu item
        let statusMenuItem = NSMenuItem(title: "Status: \(awdlStatus())", action: nil, keyEquivalent: "")
        statusMenuItem.isEnabled = false
        menu.addItem(statusMenuItem)
        
        menu.addItem(NSMenuItem(title: "Enable AWDL", action: #selector(enableAWDL), keyEquivalent: "e"))
        menu.addItem(NSMenuItem(title: "Disable AWDL", action: #selector(disableAWDL), keyEquivalent: "d"))
        menu.addItem(NSMenuItem.separator()) // Adds a separator
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(terminateApp), keyEquivalent: "q"))

        // Assign the constructed menu to the status item
        statusItem?.menu = menu // This line ensures the menu is associated with the status item.
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
        constructMenu() // Refresh the menu to reflect the updated status.
    }
    
    @objc func disableAWDL() {
        runHelperCommand(["disable"])
        constructMenu() // Refresh the menu to reflect the updated status.
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
