import SwiftUI
import Cocoa
import ServiceManagement
import Foundation

// Updated protocol to match the new interface with Bool and Error? in the completion handler.
@objc protocol AWDLHelperServiceProtocol {
    func enableAWDL(with reply: @escaping (Bool, Error?) -> Void)
    func disableAWDL(with reply: @escaping (Bool, Error?) -> Void)
}

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
    var helperConnection: NSXPCConnection?

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(named: "Toggler")
            button.image?.isTemplate = true // Ensure the image adapts to light/dark mode
        }

        constructMenu()
        setupXPCConnection() // Set up the XPC connection
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
        guard let remote = helperConnection?.remoteObjectProxyWithErrorHandler({ error in
            print("Received XPC error: \(error.localizedDescription)")
        }) as? AWDLHelperServiceProtocol else {
            return
        }

        remote.enableAWDL { (success, error) in
            DispatchQueue.main.async {
                if let error = error {
                    self.statusMenuItem?.title = "Enable AWDL Failed: \(error.localizedDescription)"
                } else if success {
                    self.statusMenuItem?.title = "Status: UP"
                } else {
                    self.statusMenuItem?.title = "Enable AWDL Failed"
                }
            }
        }
    }
    
    @objc func disableAWDL() {
        guard let remote = helperConnection?.remoteObjectProxyWithErrorHandler({ error in
            print("Received XPC error: \(error.localizedDescription)")
        }) as? AWDLHelperServiceProtocol else {
            return
        }

        remote.disableAWDL { (success, error) in
            DispatchQueue.main.async {
                if let error = error {
                    self.statusMenuItem?.title = "Disable AWDL Failed: \(error.localizedDescription)"
                } else if success {
                    self.statusMenuItem?.title = "Status: DOWN"
                } else {
                    self.statusMenuItem?.title = "Disable AWDL Failed"
                }
            }
        }
    }

    @objc func terminateApp() {
        NSApplication.shared.terminate(nil)
    }
    
    private func setupXPCConnection() {
        helperConnection = NSXPCConnection(serviceName: "com.rmak.AWDLHelperService")
        helperConnection?.remoteObjectInterface = NSXPCInterface(with: AWDLHelperServiceProtocol.self)
        helperConnection?.resume()
    }
}
