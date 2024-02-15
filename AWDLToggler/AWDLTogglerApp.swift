import SwiftUI
import Cocoa
import ServiceManagement

@main
struct AWDLTogglerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
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

        installHelperIfNeeded()
        constructMenu()
    }

    func constructMenu() {
        let menu = NSMenu()
        
        statusMenuItem = NSMenuItem(title: "Status: Checking...", action: nil, keyEquivalent: "")
        statusMenuItem?.isEnabled = false
        menu.addItem(statusMenuItem!)
        
        menu.addItem(NSMenuItem(title: "Enable AWDL", action: #selector(enableAWDL), keyEquivalent: "e"))
        menu.addItem(NSMenuItem(title: "Disable AWDL", action: #selector(disableAWDL), keyEquivalent: "d"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(terminateApp), keyEquivalent: "q"))

        statusItem?.menu = menu
    }

    func installHelperIfNeeded() {
        let helperBundleID = "com.rmak.AWDLHelper" // Adjust to your helper's actual bundle ID
        var authRef: AuthorizationRef?
        let authStatus = AuthorizationCreate(nil, nil, [.extendRights, .interactionAllowed], &authRef)
        
        guard authStatus == errAuthorizationSuccess else {
            print("Failed to create authorization reference: \(authStatus)")
            return
        }
        
        var error: Unmanaged<CFError>?
        if !SMJobBless(kSMDomainSystemLaunchd, helperBundleID as CFString, authRef, &error) {
            if let error = error?.takeRetainedValue() {
                print("Failed to install helper with error: \(error)")
            }
        } else {
            print("Helper tool installed successfully.")
        }
        
        if authRef != nil {
            AuthorizationFree(authRef!, [])
        }
    }

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
