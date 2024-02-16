import Foundation

enum Command: String {
    case enable = "enable"
    case disable = "disable"
    case startDaemon = "startDaemon"
    case stopDaemon = "stopDaemon"
}

let helperPlistPath = "/Library/LaunchDaemons/com.rmak.awdlhelper.plist"
let daemonPlistPath = "/Library/LaunchDaemons/com.rmak.awdltoggler.plist"
let daemonScriptPath = "/usr/local/bin/AWDLDaemon"

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
    
    // Deploy the helper plist if needed
    deployHelperPlistIfNeeded()

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

func deployHelperPlistIfNeeded() {
    let helperPlistContent = """
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
        <key>Label</key>
        <string>com.rmak.awdlhelper</string>
        <key>Program</key>
        <string>/Library/PrivilegedHelperTools/AWDLHelper</string>
        <key>RunAtLoad</key>
        <true/>
        <key>KeepAlive</key>
        <true/>
    </dict>
    </plist>
    """
    deployPlistIfNeeded(plistPath: helperPlistPath, plistContent: helperPlistContent)
}

func enableAWDL() {
    print("Enabling AWDL...")
    stopDaemon() // Ensure the daemon is stopped before attempting to bring AWDL0 up
    runSystemCommand("ifconfig awdl0 up")
}

func disableAWDL() {
    print("Disabling AWDL...")
    startDaemon()
}

func copyDaemonScriptIfNeeded() {
    let fileManager = FileManager.default
    if !fileManager.fileExists(atPath: daemonScriptPath) {
        do {
            try daemonScriptContent.write(to: URL(fileURLWithPath: daemonScriptPath), atomically: true, encoding: .utf8)
            runSystemCommand("chmod +x \(daemonScriptPath)")
            print("Daemon script deployed to \(daemonScriptPath).")
        } catch {
            print("Failed to deploy daemon script: \(error)")
        }
    }
}

func startDaemon() {
    print("Starting daemon...")
    deployDaemonPlistIfNeeded()
    copyDaemonScriptIfNeeded()
    runSystemCommand("launchctl load \(daemonPlistPath)")
}

func stopDaemon() {
    print("Stopping daemon...")
    runSystemCommand("launchctl unload \(daemonPlistPath)")
}

func deployDaemonPlistIfNeeded() {
    let daemonPlistContent = """
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
        <key>Label</key>
        <string>com.rmak.awdltoggler</string>
        <key>Program</key>
        <string>\(daemonScriptPath)</string>
        <key>RunAtLoad</key>
        <true/>
        <key>KeepAlive</key>
        <true/>
    </dict>
    </plist>
    """
    deployPlistIfNeeded(plistPath: daemonPlistPath, plistContent: daemonPlistContent)
}

func deployPlistIfNeeded(plistPath: String, plistContent: String) {
    let fileManager = FileManager.default
    if !fileManager.fileExists(atPath: plistPath) {
        do {
            try plistContent.write(to: URL(fileURLWithPath: plistPath), atomically: true, encoding: .utf8)
            runSystemCommand("chmod 644 \(plistPath)")
            runSystemCommand("chown root:wheel \(plistPath)")
            print("Plist file deployed at \(plistPath).")
        } catch {
            print("Failed to deploy plist file at \(plistPath): \(error)")
        }
    }
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

func runSystemCommandWithOutput(_ command: String) -> Int32 {
    let process = Process()
    let pipe = Pipe()

    process.standardOutput = pipe
    process.standardError = pipe
    process.arguments = ["-c", command]
    process.launchPath = "/bin/zsh"

    do {
        try process.run()
        process.waitUntilExit()
        return process.terminationStatus
    } catch {
        print("Failed to execute command: \(error)")
        return 1
    }
}

main()
