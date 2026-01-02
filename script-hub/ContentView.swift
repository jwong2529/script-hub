//
//  ContentView.swift
//  script-hub
//
//  Created by Janice Wong on 1/2/26.
//

import SwiftUI
import UniformTypeIdentifiers

struct ScriptProfile: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var pythonPath: String
    var scriptPath: String
}

struct ContentView: View {
    @AppStorage("savedProfiles") var profilesData: Data = Data()
    
    @State private var profiles: [ScriptProfile] = []
    @State private var selectedProfileId: UUID?
    @State private var showAddSheet = false
    
    var body: some View {
        NavigationSplitView {
            List(selection: $selectedProfileId) {
                Section("My Tools") {
                    ForEach(profiles) { profile in
                        NavigationLink(value: profile.id) {
                            Label(profile.name, systemImage: "applescript")
                        }
                    }
                    .onDelete(perform: deleteProfile)
                }
            }
            .navigationSplitViewColumnWidth(min: 200, ideal: 250)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showAddSheet = true }) {
                        Label("Add Tool", systemImage: "plus")
                    }
                }
            }
        } detail: {
            if let selectedId = selectedProfileId,
               let profile = profiles.first(where: { $0.id == selectedId }) {
                
                TerminalSessionView(profile: profile)
                    .id(profile.id)
            } else {
                Text("Select a tool to start")
                    .foregroundColor(.secondary)
            }
        }
        .onAppear(perform: loadProfiles)
        .sheet(isPresented: $showAddSheet) {
            AddProfileView(profiles: $profiles, isPresented: $showAddSheet)
                .frame(width: 500, height: 400)
        }
        .onChange(of: profiles) { _ in saveProfiles() }
        .frame(minWidth: 800, minHeight: 600)
    }
    
    func deleteProfile(at offsets: IndexSet) {
        profiles.remove(atOffsets: offsets)
    }
    
    func loadProfiles() {
        if let decoded = try? JSONDecoder().decode([ScriptProfile].self, from: profilesData) {
            profiles = decoded
        }
    }
    
    func saveProfiles() {
        if let encoded = try? JSONEncoder().encode(profiles) {
            profilesData = encoded
        }
    }
}

struct TerminalSessionView: View {
    let profile: ScriptProfile
    @StateObject private var engine = ScriptEngine()
    @State private var userInput = ""
    @FocusState private var isInputFocused: Bool
    private let bottomID = "BottomAnchor"
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(profile.name)
                    .font(.headline)
                
                if engine.isRunning {
                    Text("• Live").foregroundColor(.green).font(.caption)
                    Spacer()
                    Button(action: { engine.sendInterrupt() }) {
                        Label("Stop", systemImage: "stop.circle")
                    }
                    .keyboardShortcut(".", modifiers: .command)
                } else {
                    Text("• Inactive").foregroundColor(.secondary).font(.caption)
                    Spacer()
                    Button("Start") {
                        startEngine()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 4) {
                        ForEach(engine.outputLog) { message in
                            if message.isUser {
                                HStack { Spacer(); Text(message.text).padding(8).background(Color.blue).cornerRadius(8) }
                            } else {
                                AnsiText(text: message.text)
                                    .font(.system(.body, design: .monospaced))
                                    .fixedSize(horizontal: false, vertical: true)
                                    .textSelection(.enabled)
                            }
                        }
                        Color.clear.frame(height: 1).id(bottomID)
                    }
                    .padding()
                }
                .onChange(of: engine.outputLog.count) {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        proxy.scrollTo(bottomID, anchor: .bottom)
                    }
                }
            }
            
            Divider()
            
            HStack {
                TextField("Command...", text: $userInput)
                    .textFieldStyle(.plain)
                    .font(.system(.body, design: .monospaced))
                    .focused($isInputFocused)
                    .disabled(!engine.isRunning)
                    .onSubmit {
                        engine.sendInput(userInput)
                        userInput = ""
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { isInputFocused = true }
                    }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
        }
        .onDisappear {
            engine.stop()
        }
    }
    
    private func startEngine() {
        engine.stop()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            engine.startScript(pythonPath: profile.pythonPath, scriptPath: profile.scriptPath)
            isInputFocused = true
        }
    }
}

struct AddProfileView: View {
    @Binding var profiles: [ScriptProfile]
    @Binding var isPresented: Bool
    
    @State private var name = ""
    @State private var pythonPath = ""
    @State private var scriptPath = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Add New Tool").font(.title2)
            
            TextField("Tool Name (e.g. GCal Manager)", text: $name)
                .textFieldStyle(.roundedBorder)
            
            VStack(alignment: .leading) {
                Text("Python Path:").font(.caption)
                HStack {
                    TextField("...", text: $pythonPath).textFieldStyle(.roundedBorder)
                    Button("Browse") { if let url = selectFile() { pythonPath = url.path } }
                }
            }
            
            VStack(alignment: .leading) {
                Text("Script Path (.py):").font(.caption)
                HStack {
                    TextField("...", text: $scriptPath).textFieldStyle(.roundedBorder)
                    Button("Browse") { if let url = selectFile(["py"]) { scriptPath = url.path } }
                }
            }
            
            HStack {
                Button("Cancel") { isPresented = false }
                Spacer()
                Button("Add Tool") {
                    let newProfile = ScriptProfile(name: name, pythonPath: pythonPath, scriptPath: scriptPath)
                    profiles.append(newProfile)
                    isPresented = false
                }
                .buttonStyle(.borderedProminent)
                .disabled(name.isEmpty || pythonPath.isEmpty || scriptPath.isEmpty)
            }
        }
        .padding()
    }
    
    func selectFile(_ types: [String]? = nil) -> URL? {
        let dialog = NSOpenPanel()
        dialog.canChooseFiles = true
        if let types = types { dialog.allowedContentTypes = types.compactMap { UTType(filenameExtension: $0) } }
        return dialog.runModal() == .OK ? dialog.url : nil
    }
}

