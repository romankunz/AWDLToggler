import Foundation

class AWDLDaemon {
    func run() {
        while true {
            checkAndDisableAWDL()
            sleep(1) // Sleep for 1 second before checking again
        }
    }
    
    private func checkAndDisableAWDL() {
        let status = getAWDLStatus()
        if status.contains("status: active") {
            disableAWDL()
        }
    }
    
    private func getAWDLStatus() -> String {
        let process = Process()
        let pipe = Pipe()
        
        process.launchPath = "/sbin/ifconfig"
        process.arguments = ["awdl0"]
        process.standardOutput = pipe
        process.standardError = pipe
        
        process.launch()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        if let output = String(data: data, encoding: .utf8) {
            return output
        }
        return ""
    }
    
    private func disableAWDL() {
        let process = Process()
        
        process.launchPath = "/sbin/ifconfig"
        process.arguments = ["awdl0", "down"]
        
        process.launch()
    }
}

// Entry point for the daemon
let daemon = AWDLDaemon()
daemon.run()

