import Foundation

enum Command: String {
   case enable = "enable"
   case disable = "disable"
   case startDaemon = "startDaemon"
   case stopDaemon = "stopDaemon"
}

// Paths should be adjusted based on your actual setup
let daemonPlistPath = "/Library/LaunchDaemons/com.example.awdltoggler.plist"
let daemonScriptPath = "/usr/local/bin/AWDLDaemon.sh"
let localDaemonScriptPath = "AWDLDaemon.sh"

func main() {
   guard CommandLine.arguments.count > 1 else {
       print("No command provided.")
       return
   }

   let commandArgument = CommandLine.arguments[1]
   guard let command = Command(rawValue: commandArgument) else {
       print("Invalid command.")
       return
   }

   switch command {
   case .enable:
       enableAWDL()
   case .disable:
       disableAWDL()
   case .startDaemon:
       startDaemon()
   case .stopDaemon:
       stopDaemon()
   }
}

func enableAWDL() {
   print("Enabling AWDL...")
   runSystemCommand("sudo ifconfig awdl0 up")
}

func disableAWDL() {
   print("Disabling AWDL...")
   runSystemCommand("sudo ifconfig awdl0 down")
}

func copyDaemonScriptIfNeeded() {
   let fileManager = FileManager.default
   if !fileManager.fileExists(atPath: daemonScriptPath) {
       do {
           // Assuming runSystemCommand adapts to run with elevated privileges
           runSystemCommand("sudo cp \(localDaemonScriptPath) \(daemonScriptPath)")
           runSystemCommand("sudo chmod +x \(daemonScriptPath)")
           print("Daemon script copied to \(daemonScriptPath).")
       }
   }
}

func startDaemon() {
   print("Starting daemon...")
   copyDaemonScriptIfNeeded()
   runSystemCommand("sudo launchctl load \(daemonPlistPath)")
}

func stopDaemon() {
   print("Stopping daemon...")
   runSystemCommand("sudo launchctl unload \(daemonPlistPath)")
}

func runSystemCommand(_ command: String) {
   let process = Process()
   let pipe = Pipe()
   
   process.standardOutput = pipe
   process.standardError = pipe
   process.arguments = ["-c", command]
   process.launchPath = "/bin/zsh"
   
   do {
       try process.run()
       process.waitUntilExit()
       
       let data = pipe.fileHandleForReading.readDataToEndOfFile()
       let output = String(data: data, encoding: .utf8) ?? ""
       print(output)
   } catch {
       print("Failed to execute command: \(error)")
   }
}

main()
