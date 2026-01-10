//
//  script_hubApp.swift
//  script-hub
//
//  Created by Janice Wong on 1/2/26.
//

import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    // Red X quits app completely
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}

@main
struct script_hubApp: App {
    
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @AppStorage("terminalFontSize") private var fontSize: Double = 12.0
    
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowResizability(.contentSize)
        .commands {
            // Show/Hide Sidebar
            SidebarCommands()
            
            CommandGroup(replacing: .textFormatting) {
                Button("Increase Font Size") {
                    fontSize = min(fontSize + 1, 36)
                }
                .keyboardShortcut("+", modifiers: .command)
                
                Button("Decrease Font Size") {
                    fontSize = max(fontSize - 1, 8)
                }
                .keyboardShortcut("-", modifiers: .command)
                
                Button("Default Size") {
                    fontSize = 12
                }
                .keyboardShortcut("0", modifiers: .command)
            }
            
            CommandMenu("Script") {
                ScriptCommands()
            }
            
        }
    }
}

struct ScriptCommands: View {
    @FocusedValue(\.terminalActions) var actions
    
    var body: some View {
        Button("Run Script") { actions?.start() }
            .keyboardShortcut("r", modifiers: .command)
            .disabled(actions == nil || actions!.isRunning)
        
        Button("Stop Script") { actions?.stop() }
            .keyboardShortcut(".", modifiers: .command)
            .disabled(actions == nil || !actions!.isRunning)
        
        Divider()
        
        Button("Clear Console") { actions?.clear() }
            .keyboardShortcut("k", modifiers: .command)
            .disabled(actions == nil || actions!.isLogEmpty)
        
        Divider()
        
        Button("Tool Settings") { actions?.openSettings() }
            .keyboardShortcut(",", modifiers: .command)
            .disabled(actions == nil)
    }
}
