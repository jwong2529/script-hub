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
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowResizability(.contentSize)
    }
}
