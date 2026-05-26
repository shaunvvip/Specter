import Foundation
import AppKit

enum ReloadResult: Equatable {
    case sent
    case ghosttyNotRunning
    case automationDenied
    case scriptError(String)
}

actor ReloadHelper {
    func requestReload() async -> ReloadResult {
        let running = NSWorkspace.shared.runningApplications.contains {
            $0.bundleIdentifier == "com.mitchellh.ghostty"
        }
        guard running else { return .ghosttyNotRunning }

        let script = """
        tell application "System Events"
            tell process "Ghostty"
                keystroke "," using {command down, shift down}
            end tell
        end tell
        """
        var error: NSDictionary?
        guard let appleScript = NSAppleScript(source: script) else {
            return .scriptError("Could not compile AppleScript")
        }
        _ = appleScript.executeAndReturnError(&error)
        if let error = error {
            let code = error[NSAppleScript.errorNumber] as? Int ?? 0
            if code == -1743 || code == -1719 {
                return .automationDenied
            }
            return .scriptError(error[NSAppleScript.errorMessage] as? String ?? "Unknown")
        }
        return .sent
    }
}
