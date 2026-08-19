import Foundation

let hubVersion = "1.1.0"

func binaryVersion(_ path: String) -> String {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: path)
    process.arguments = ["--version"]
    let pipe = Pipe()
    process.standardOutput = pipe
    process.standardError = pipe
    try? process.run()
    process.waitUntilExit()
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    let raw = String(data: data, encoding: .utf8) ?? ""
    // Extract just the version number e.g. "b2c 1.4.0" -> "1.4.0"
    return raw.split(separator: " ").last.map(String.init) ?? raw.trimmingCharacters(in: .whitespacesAndNewlines)
}
