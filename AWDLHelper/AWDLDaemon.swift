import Foundation

class AWDLManager {
    func checkAndDisableAWDL() {
        let status = self.getAWDLStatus()
        if status.contains("status: active") {
            self.disableAWDL()
        }
    }
    
    private func getAWDLStatus() -> String {
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
            if let output = String(data: data, encoding: .utf8) {
                return output
            }
        } catch {
            print("Failed to execute ifconfig: \(error)")
        }
        return ""
    }
    
    private func disableAWDL() {
        let process = Process()
        
        process.launchPath = "/sbin/ifconfig"
        process.arguments = ["awdl0", "down"]
        
        do {
            try process.run()
            process.waitUntilExit()
            print("AWDL interface disabled.")
        } catch {
            print("Failed to disable AWDL interface: \(error)")
        }
    }
}

// Main run loop
let manager = AWDLManager()
while true {
    manager.checkAndDisableAWDL()
    sleep(1) // Sleep for 1 second before checking again
}
