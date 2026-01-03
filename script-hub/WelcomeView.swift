//
//  WelcomeView.swift
//  script-hub
//
//  Created by Janice Wong on 1/2/26.
//

import SwiftUI
struct WelcomeView: View {
    var onAddTool: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(nsImage: NSApplication.shared.applicationIconImage)
                .font(.system(size: 60))
                .foregroundColor(.blue)
                .opacity(0.8)
            
            VStack(spacing: 8) {
                Text("Welcome to Script Hub")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Run your interactive Python tools in a clean, native interface.\nCreated by Janice Wong.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .font(.body)
            }
            
            Button("Add First Tool") {
                onAddTool()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.top, 10)
            
        }
        .padding()
        .padding(.top, -100)
        .frame(maxWidth: 400)
    }
}
