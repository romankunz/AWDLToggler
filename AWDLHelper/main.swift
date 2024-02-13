import Foundation

enum Command: String {
    case enable = "enable"
    case disable = "disable"
    case startDaemon = "startDaemon"
    case stopDaemon = "stopDaemon"
}

let daemonPlistPath = "/Library/LaunchDaemons/com.rmak.awdltoggler.plist"
let daemonScriptPath = "/usr/local/bin/AWDLDaemon.sh"
let daemonScriptContent = """
#!/usr/bin/env bash

set -euo pipefail

while true; do
    if ifconfig awdl0 | grep -q "<UP"; then
        (set -x; sudo ifconfig awdl0 down)
    fi
    sleep 1
done
"""

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
            try daemonScriptContent.write(to: URL(fileURLWithPath: daemonScriptPath), atomically: true, encoding: .utf8)
            runSystemCommand("sudo chmod +x \(daemonScriptPath)")
            print("Daemon script deployed to \(daemonScriptPath).")
        } catch {
            print("Failed to deploy daemon script: \(error)")
        }
    }
}

func startDaemon() {
    print("Starting daemon...")
    deployPlistIfNeeded()
    copyDaemonScriptIfNeeded()
    runSystemCommand("sudo launchctl load \(daemonPlistPath)")
}

func stopDaemon() {
    print("Stopping daemon...")
    runSystemCommand("sudo launchctl unload \(daemonPlistPath)")
}

func deployPlistIfNeeded() {
    let plistContent = """
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
    let fileManager = FileManager.default
    if !fileManager.fileExists(atPath: daemonPlistPath) {
        do {
            try plistContent.write(to: URL(fileURLWithPath: daemonPlistPath), atomically: true, encoding: .utf8)
            runSystemCommand("sudo chmod 644 \(daemonPlistPath)")
            runSystemCommand("sudo chown root:wheel \(daemonPlistPath)")
            print("Plist file deployed.")
        } catch {
            print("Failed to deploy plist file: \(error)")
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

main()

