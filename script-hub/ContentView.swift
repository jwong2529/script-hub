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
               let index = profiles.firstIndex(where: { $0.id == selectedId }) {
                TerminalSessionView(
                    profile: $profiles[index],
                    onDelete: {
                        profiles.remove(at: index)
                        selectedProfileId = nil
                    }
                )
                .id(selectedId)
            } else if profiles.isEmpty {
                WelcomeView {
                    showAddSheet = true
                }
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
        .onChange(of: profiles) { saveProfiles() }
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
    @Binding var profile: ScriptProfile
    var onDelete: () -> Void
    @StateObject private var engine = ScriptEngine()
    @State private var userInput = ""
    @FocusState private var isInputFocused: Bool
    @State private var showSettings = false
    private let bottomID = "BottomAnchor"
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center) {
                Text(profile.name)
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Spacer()
                
                HStack(spacing: 12) {
                    if engine.isRunning {
                        HStack(spacing: 4) {
                            Circle().fill(Color.green).frame(width: 8, height: 8)
                            Text("Live")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Button(action: {
                            engine.stop()
                        }) {
                            Image(systemName: "stop.circle.fill")
                                .font(.title2)
                                .foregroundColor(.red)
                                .help("Quit (Cmd + .)")
                        }
                        .buttonStyle(.plain)
                        
                        // Cmd + '.' quit shortcut
                        Button("HiddenSignal") {
                            engine.sendInterrupt()
                        }
                        .keyboardShortcut(".", modifiers: .command)
                        .opacity(0)
                        .frame(width: 0, height: 0)
                        
                    } else {
                        HStack(spacing: 4) {
                            Circle().fill(Color.gray).frame(width: 8, height: 8)
                            Text("Inactive")
                                .font(.subheadline)
                                .foregroundColor(Color(NSColor.tertiaryLabelColor))
                        }
                        
                        Button("Start") {
                            startEngine()
                        }
                        .controlSize(.regular)
                        .keyboardShortcut("r", modifiers: .command)
                        .help("Run (Cmd + R)")
                    }
                    
                    Divider().frame(height: 20)
                    Button(action: { showSettings = true }) {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(.secondary)
                            .font(.title3)
                    }
                    .buttonStyle(.plain)
                    .help("Edit Tool Settings")
                    
                }
                .frame(minHeight: 32)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(NSColor.windowBackgroundColor))
            .sheet(isPresented: $showSettings) {
                EditProfileView(profile: $profile, isPresented: $showSettings, onDelete: onDelete)
            }
            
            Divider()
            
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(engine.outputLog) { message in
                            if message.isUser {
                                HStack { Spacer(); Text(message.text).padding(8).background(Color.blue).cornerRadius(8) }
                                    .padding(.vertical, 4)
                            } else {
                                AnsiText(text: message.text)
                                    .font(.system(.body, design: .monospaced))
                                    .fixedSize(horizontal: false, vertical: true)
                                    .textSelection(.enabled)
                                    .padding(.vertical, 1)
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

struct EditProfileView: View {
    @Binding var profile: ScriptProfile
    @Binding var isPresented: Bool
    var onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Edit Tool").font(.title2)
            
            TextField("Name", text: $profile.name).textFieldStyle(.roundedBorder)
            
            VStack(alignment: .leading) {
                Text("Python Path:").font(.caption)
                HStack {
                    TextField("...", text: $profile.pythonPath).textFieldStyle(.roundedBorder)
                    Button("Browse") { if let url = selectFile() { profile.pythonPath = url.path } }
                }
            }
            
            VStack(alignment: .leading) {
                Text("Script Path:").font(.caption)
                HStack {
                    TextField("...", text: $profile.scriptPath).textFieldStyle(.roundedBorder)
                    Button("Browse") { if let url = selectFile(["py"]) { profile.scriptPath = url.path } }
                }
            }
            
            Divider()
            
            HStack {
                Button("Delete Tool", role: .destructive) {
                    onDelete()
                    isPresented = false
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button("Done") { isPresented = false }
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(width: 500, height: 350)
    }
    
    func selectFile(_ types: [String]? = nil) -> URL? {
        let dialog = NSOpenPanel()
        dialog.canChooseFiles = true
        if let types = types { dialog.allowedContentTypes = types.compactMap { UTType(filenameExtension: $0) } }
        return dialog.runModal() == .OK ? dialog.url : nil
    }
}
