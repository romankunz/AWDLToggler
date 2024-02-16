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
    var statusMenuItem: NSMenuItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(named: "Toggler")
            button.image?.isTemplate = true // Ensure the image adapts to light/dark mode
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
        menu.delegate = self // Ensure AppDelegate is set as the menu's delegate
    }

    func installHelperIfNeeded() {
        let helperBundleID = "com.rmak.AWDLHelper" // Ensure this matches your helper's CFBundleIdentifier
        var authRef: AuthorizationRef?
        var authStatus = OSStatus(errAuthorizationDenied)
        
        // Create an Authorization Reference
        authStatus = AuthorizationCreate(nil, nil, [.extendRights, .interactionAllowed], &authRef)
        
        guard authStatus == errAuthorizationSuccess else {
            print("Authorization failed: \(authStatus)")
            return
        }
        
        // Attempt to install the helper using SMJobBless
        var error: Unmanaged<CFError>?
        if SMJobBless(kSMDomainSystemLaunchd, helperBundleID as CFString, authRef, &error) {
            print("Successfully installed helper.")
        } else {
            if let error = error?.takeRetainedValue() {
                print("Failed to install helper with error: \(error)")
            }
        }
        
        // Always free the Authorization Reference when done
        if authRef != nil {
            AuthorizationFree(authRef!, [.destroyRights])
        }
    }

    func menuWillOpen(_ menu: NSMenu) {
        updateAWDLStatus()
    }

    func updateAWDLStatus() {
        DispatchQueue.global(qos: .userInitiated).async {
            let status = self.awdlStatus()
            
            DispatchQueue.main.async {
                self.statusMenuItem?.title = "Status: \(status)"
            }
        }
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
        // Define the path to the helper tool directly
        let helperPath = "/Library/PrivilegedHelperTools/AWDLHelper"

        let process = Process()
        let pipe = Pipe()

        // Set the launchPath for the Process to the direct path of the helper
        process.launchPath = helperPath
        process.arguments = arguments
        process.standardOutput = pipe
        process.standardError = pipe

        do {
            try process.run()
            process.waitUntilExit()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            print("Helper output: \(output)")
        } catch {
            print("Failed to run AWDLHelper: \(error)")
        }
    }
}
