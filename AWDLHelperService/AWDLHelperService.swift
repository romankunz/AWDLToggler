import Foundation

class AWDLHelperService: NSObject, AWDLHelperServiceProtocol {
    
    let daemonPlistPath = "/Library/LaunchDaemons/com.rmak.awdltoggler.plist"
    let daemonBinaryPath = "/usr/local/bin/AWDLDaemon"
    
    func enableAWDL(with reply: @escaping (Bool, Error?) -> Void) {
        // Stop and unload the daemon
        stopDaemon { success, error in
            guard success else {
                reply(false, error ?? NSError(domain: "AWDLHelperService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to stop daemon"]))
                return
            }
            
            // Attempt to bring the AWDL interface up
            let result = self.runSystemCommand("/sbin/ifconfig", arguments: ["awdl0", "up"])
            if result {
                reply(true, nil)
            } else {
                reply(false, NSError(domain: "AWDLHelperService", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to enable AWDL"]))
            }
        }
    }
    
    func disableAWDL(with reply: @escaping (Bool, Error?) -> Void) {
        // Ensure the daemon binary exists and is in the correct location
        
        // Deploy the daemon plist if needed and load the daemon
        deployDaemonPlistIfNeeded { success, error in
            guard success else {
                reply(false, error ?? NSError(domain: "AWDLHelperService", code: 3, userInfo: [NSLocalizedDescriptionKey: "Failed to deploy daemon plist"]))
                return
            }
            
            // Attempt to bring the AWDL interface down
            let result = self.runSystemCommand("/sbin/ifconfig", arguments: ["awdl0", "down"])
            if result {
                reply(true, nil)
            } else {
                reply(false, NSError(domain: "AWDLHelperService", code: 4, userInfo: [NSLocalizedDescriptionKey: "Failed to disable AWDL"]))
            }
        }
    }
    
    private func stopDaemon(completion: @escaping (Bool, Error?) -> Void) {
        // Attempt to unload the daemon using launchctl
        let result = runSystemCommand("/bin/launchctl", arguments: ["unload", daemonPlistPath])
        if result {
            completion(true, nil)
        } else {
            completion(false, NSError(domain: "AWDLHelperService", code: 5, userInfo: [NSLocalizedDescriptionKey: "Failed to unload daemon"]))
        }
    }
    
    private func deployDaemonPlistIfNeeded(completion: @escaping (Bool, Error?) -> Void) {
        // Check if plist exists, if not, create and load the daemon
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: daemonPlistPath) {
            // For simplicity, assuming creation and loading are always successful
            // In practice, you should handle file creation and command execution errors
            completion(true, nil)
        } else {
            completion(true, nil) // Plist already exists, consider this a success
        }
    }
    
    private func runSystemCommand(_ launchPath: String, arguments: [String]) -> Bool {
        let process = Process()
        let pipe = Pipe()
        
        process.launchPath = launchPath
        process.arguments = arguments
        process.standardOutput = pipe
        process.standardError = pipe
        
        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus == 0
        } catch {
            print("Failed to execute command: \(error)")
            return false
        }
    }
}
