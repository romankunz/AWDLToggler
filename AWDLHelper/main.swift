import Foundation

enum Command: String {
    case enable = "enable"
    case disable = "disable"
}

let daemonPlistPath = "/Library/LaunchDaemons/com.rmak.awdltoggler.plist"
let daemonBinaryPath = "/usr/local/bin/AWDLDaemon"
// Adjust the path according to where your app bundle actually stores the daemon
let daemonBinarySourcePath = Bundle.main.bundlePath + "/Contents/Helpers/AWDLDaemon"

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
    }
}

func enableAWDL() {
    print("Enabling AWDL...")
    // Unload the daemon
    if runSystemCommand("/bin/launchctl", arguments: ["unload", daemonPlistPath]) {
        print("Daemon unloaded successfully.")
    } else {
        print("Failed to unload daemon.")
    }
    // Bring AWDL0 up
    if runSystemCommand("/sbin/ifconfig", arguments: ["awdl0", "up"]) {
        print("AWDL interface enabled.")
    } else {
        print("Failed to enable AWDL interface.")
    }
}

func disableAWDL() {
    print("Disabling AWDL...")
    // Copy the daemon binary if it's not already there
    copyDaemonBinaryIfNeeded()
    // Deploy the LaunchDaemon plist and load the daemon
    deployDaemonPlistAndLoad()
}

func copyDaemonBinaryIfNeeded() {
    let fileManager = FileManager.default
    if !fileManager.fileExists(atPath: daemonBinaryPath) {
        do {
            try fileManager.copyItem(atPath: daemonBinarySourcePath, toPath: daemonBinaryPath)
            print("Daemon binary copied.")
        } catch {
            print("Failed to copy daemon binary: \(error)")
        }
    }
}

func deployDaemonPlistAndLoad() {
    let fileManager = FileManager.default
    if !fileManager.fileExists(atPath: daemonPlistPath) {
        let daemonPlistContent = """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
            <key>Label</key>
            <string>com.rmak.awdltoggler</string>
            <key>Program</key>
            <string>\(daemonBinaryPath)</string>
            <key>RunAtLoad</key>
            <true/>
            <key>KeepAlive</key>
            <true/>
        </dict>
        </plist>
        """
        do {
            try daemonPlistContent.write(to: URL(fileURLWithPath: daemonPlistPath), atomically: true, encoding: .utf8)
            print("Daemon plist deployed.")
        } catch {
            print("Failed to deploy daemon plist: \(error)")
        }
    }

    if runSystemCommand("/bin/launchctl", arguments: ["load", daemonPlistPath]) {
        print("Daemon loaded successfully.")
    } else {
        print("Failed to load daemon.")
    }
}

func runSystemCommand(_ launchPath: String, arguments: [String]) -> Bool {
    let process = Process()
    let pipe = Pipe()

    process.standardOutput = pipe
    process.standardError = pipe
    process.arguments = arguments
    process.launchPath = launchPath

    do {
        try process.run()
        process.waitUntilExit()

        let status = process.terminationStatus
        return status == 0
    } catch {
        print("Failed to execute command: \(error)")
        return false
    }
}

main()
