//
//  ScriptEngine.swift
//  script-hub
//
//  Created by Janice Wong on 1/2/26.
//

import Foundation
import Combine
import SwiftUI

class ScriptEngine: ObservableObject {
    @Published var outputLog: [LogMessage] = []
    @Published var isRunning = false
    @Published var configError: String?
    
    private var process: Process?
    private var inputPipe: Pipe?
    
    struct LogMessage: Identifiable, Equatable {
        let id = UUID()
        let text: String
        let isUser: Bool
    }
    
    func startScript(pythonPath: String, scriptPath: String) {
        self.outputLog = [] // Clear log
        self.configError = nil
        
        guard !pythonPath.isEmpty, !scriptPath.isEmpty else {
            self.configError = "Paths are missing."
            return
        }
        
        self.process = Process()
        self.process?.executableURL = URL(fileURLWithPath: pythonPath)
        self.process?.arguments = ["-u", scriptPath] // -u is CRITICAL
        
        // Set working directory
        let scriptUrl = URL(fileURLWithPath: scriptPath)
        self.process?.currentDirectoryURL = scriptUrl.deletingLastPathComponent()
        
        let outputPipe = Pipe()
        self.inputPipe = Pipe()
        
        self.process?.standardOutput = outputPipe
        self.process?.standardError = outputPipe
        self.process?.standardInput = self.inputPipe
        
        outputPipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            if let string = String(data: data, encoding: .utf8), !string.isEmpty {
                DispatchQueue.main.async {
                    self?.appendOutput(string)
                }
            }
        }
        
        self.process?.terminationHandler = { [weak self] _ in
            DispatchQueue.main.async {
                self?.isRunning = false
                self?.outputLog.append(LogMessage(text: "\n[Process Finished]", isUser: false))
            }
        }
        
        do {
            try self.process?.run()
            self.isRunning = true
        } catch {
            self.configError = "Failed to run: \(error.localizedDescription)"
        }
    }
    
    func sendInput(_ input: String) {
        let stringToSend = input + "\n"
        guard let data = stringToSend.data(using: .utf8) else { return }
        self.inputPipe?.fileHandleForWriting.write(data)
        
        let visualLog = input.isEmpty ? "⏎" : input
        self.outputLog.append(LogMessage(text: visualLog, isUser: true))
    }
    
    func sendInterrupt() {
        process?.interrupt()
    }
    
    func stop() {
        process?.terminate()
    }
    
    private func appendOutput(_ rawText: String) {
        // Fix line endings to avoid double spacing
        var cleanText = rawText.replacingOccurrences(of: "\r\n", with: "\n")
        
        // Handle leftover carriage returns (spinner logic)
        cleanText = cleanText.replacingOccurrences(of: "\r", with: "\n")
        
        // So that SwiftUI doesn't render as an extra blank line
        if cleanText.hasSuffix("\n") {
            cleanText.removeLast()
        }
        
        // Ignore completely empty chunks
        if cleanText.isEmpty { return }
        
        self.outputLog.append(LogMessage(text: cleanText, isUser: false))
    }
}
