import Foundation

let hubVersion = "1.4.0"

func findBinary(_ name: String) -> String {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/which")
    process.arguments = [name]
    let pipe = Pipe()
    process.standardOutput = pipe
    process.standardError = pipe
    try? process.run()
    process.waitUntilExit()
    let output = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)?
        .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    return output.isEmpty ? "/usr/local/bin/\(name)" : output
}

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
	return (raw.split(separator: " ").last.map(String.init) ?? raw).trimmingCharacters(in: .whitespacesAndNewlines)
}
