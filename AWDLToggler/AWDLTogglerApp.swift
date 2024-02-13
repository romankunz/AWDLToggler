import SwiftUI
import Cocoa

@main
struct AWDLTogglerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            // Placeholder for any settings UI, which might not be needed for a menu bar app.
            Text("Settings View")
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Initialize the status bar item.
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(named: "Toggler") // Ensure this name matches your image set name in the asset catalog
            button.image?.isTemplate = true // Consider making it a template image if it should adapt to light/dark mode
        }

        // Construct the menu for the status item.
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Enable AWDL", action: #selector(enableAWDL), keyEquivalent: "e"))
        menu.addItem(NSMenuItem(title: "Disable AWDL", action: #selector(disableAWDL), keyEquivalent: "d"))
        menu.addItem(NSMenuItem.separator()) // Adds a separator.
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(terminateApp), keyEquivalent: "q"))

        statusItem?.menu = menu
    }

    @objc func enableAWDL() {
        runHelperCommand(["enable"])
    }
    
    @objc func disableAWDL() {
        runHelperCommand(["disable"])
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

