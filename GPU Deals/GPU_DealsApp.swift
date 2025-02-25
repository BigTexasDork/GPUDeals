//
//  GPU_DealsApp.swift
//  GPU Deals
//
//  Created by Joe Franklin on 2/23/25.
//

import SwiftUI

@main
struct GPU_DealsApp: App {
    // Attache custom AppDelegate to the SwiftUI app
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

// Custom AppDelegate implementing the termination behavior
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_: NSApplication) -> Bool {
        true
    }
}
