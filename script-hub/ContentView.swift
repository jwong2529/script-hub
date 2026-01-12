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
    var isFavorite: Bool
}

struct ContentView: View {
    @AppStorage("savedProfiles") var profilesData: Data = Data()
    
    @State private var profiles: [ScriptProfile] = []
    @State private var selectedProfileId: String?
    @State private var showAddSheet = false
    
    @State private var searchText = ""
    
    var filteredProfiles: [ScriptProfile] {
        if searchText.isEmpty {
            return profiles
        } else {
            return profiles.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var moveAction: ((IndexSet, Int) -> Void)? {
        if searchText.isEmpty {
            return moveProfile
        } else {
            return nil
        }
    }
    
    var sidebarView: some View {
        List(selection: $selectedProfileId) {
            
            if !favorites.isEmpty && searchText.isEmpty {
                Section("Favorites") {
                    ForEach(favorites) { profile in
                        NavigationLink(value: "fav_" + profile.id.uuidString) {
                            HStack {
                                Label(profile.name, systemImage: "star.fill")
                                    .foregroundColor(.yellow)
                            }
                        }
                        .contextMenu {
                            Button("Unfavorite") {
                                toggleFavorite(id: profile.id)
                            }
                            Button("Delete", role: .destructive) {
                                deleteProfileById(profile.id)
                            }
                        }
                    }
                }
            }
            Section("My Tools") {
                ForEach(filteredProfiles) { profile in
                    NavigationLink(value: profile.id.uuidString) {
                        HStack {
                            Label(profile.name, systemImage: "applescript")
                            
                            Spacer()
                        
                            if profile.isFavorite {
                                Image(systemName: "star.fill")
                                    .font(.caption2)
                                    .foregroundColor(.yellow)
                            }
                        }
                    }
                    .contextMenu {
                        Button(profile.isFavorite ? "Unfavorite" : "Favorite") {
                            toggleFavorite(id: profile.id)
                        }
                        Button("Delete", role: .destructive) {
                            deleteProfileById(profile.id)
                        }
                    }
                }
                .onDelete(perform: deleteProfile)
                .onMove(perform: moveAction)
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
        .searchable(text: $searchText, placement: .sidebar, prompt: "Search tools")
    }

    var body: some View {
        NavigationSplitView {
            sidebarView
        } detail: {
            if let selString = selectedProfileId,
               let uuid = UUID(uuidString: selString.replacingOccurrences(of: "fav_", with: "")),
               let index = profiles.firstIndex(where: { $0.id == uuid }) {
                TerminalSessionView(
                    profile: $profiles[index],
                    onDelete: {
                        profiles.remove(at: index)
                        selectedProfileId = nil
                    },
                    onClose: {
                        selectedProfileId = nil
                    }
                )
                .id(selString)
            } else if profiles.isEmpty {
                WelcomeView {
                    showAddSheet = true
                }
            } else {
                VStack(spacing: 16) {
                    Image(nsImage: NSApplication.shared.applicationIconImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 120, height: 120)
                        .grayscale(1.0)
                        .opacity(0.08)
                    
                    Text("Select a tool to start")
                        .font(.system(size: 20, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                        .opacity(0.6)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .offset(x: 110)
                .background(Color(NSColor.windowBackgroundColor))
                .ignoresSafeArea()
            }
        }
        .onAppear(perform: loadProfiles)
        .sheet(isPresented: $showAddSheet) {
            AddProfileView(profiles: $profiles, isPresented: $showAddSheet)
                .frame(width: 500)
                .fixedSize(horizontal: false, vertical: true)
        }
        .onChange(of: profiles) { saveProfiles() }
        .frame(minWidth: 800, minHeight: 600)
    }
    
    var favorites: [ScriptProfile] {
        profiles.filter { $0.isFavorite }
    }

    func toggleFavorite(id: UUID) {
        if let index = profiles.firstIndex(where: { $0.id == id }) {
            profiles[index].isFavorite.toggle()
            
            if !profiles[index].isFavorite, selectedProfileId == "fav_" + id.uuidString {
                selectedProfileId = id.uuidString
            }
        }
    }
    func deleteProfileById(_ id: UUID) {
        if let index = profiles.firstIndex(where: { $0.id == id }) {
            profiles.remove(at: index)
            if let sel = selectedProfileId, sel.contains(id.uuidString) {
                selectedProfileId = nil
            }
        }
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
    
    func moveProfile(from source: IndexSet, to destination: Int) {
        profiles.move(fromOffsets: source, toOffset: destination)
    }
}

struct TerminalSessionView: View {
    @Binding var profile: ScriptProfile
    var onDelete: () -> Void
    var onClose: () -> Void
    @StateObject private var engine = ScriptEngine()
    @State private var userInput = ""
    @FocusState private var isInputFocused: Bool
    @State private var showSettings = false
    private let bottomID = "BottomAnchor"
    @AppStorage("terminalFontSize") private var fontSize: Double = 12.0
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center) {
                Text(profile.name)
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Spacer()
                
                HStack(spacing: 16) {
                    if engine.isRunning {
                        HStack(spacing: 8) {
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
                                    .help("Stop Script (Cmd + .)")
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.trailing, -8)
                    } else {
                        HStack(spacing: 8) {
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
                            .help("Run (Cmd + R)")
                        }
                        .padding(.trailing, 2)
                    }
                    
                    Divider().frame(height: 16)
                    
                    Button(action: {
                        engine.outputLog.removeAll()
                    }) {
                        Image(systemName: "trash")
                            .foregroundColor(.secondary)
                            .font(.title3)
                    }
                    .buttonStyle(.plain)
                    .disabled(engine.outputLog.isEmpty)
                    .help("Clear Console Output (Cmd + K)")
                    
                    Button(action: { showSettings = true }) {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(.secondary)
                            .font(.title3)
                    }
                    .buttonStyle(.plain)
                    .help("Settings (Cmd + ,)")
                    
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
                    VStack(spacing: 0) {
                        LazyVStack(alignment: .leading, spacing: 0) {
                            ForEach(engine.outputLog) { message in
                                if message.isUser {
                                    HStack {
                                        Spacer()
                                        Text(message.text)
                                            .font(.system(size: fontSize, weight: .regular, design: .monospaced))
                                            .padding(8)
                                            .background(Color.blue)
                                            .cornerRadius(8)
                                            .textSelection(.enabled)
                                    }
                                    .padding(.vertical, 4)
                                } else {
                                    AnsiText(text: message.text, fontSize: fontSize)
                                        .fixedSize(horizontal: false, vertical: true)
                                        .textSelection(.enabled)
                                        .padding(.vertical, 1)
                                }
                            }
                        }
                        .padding()
                        Color.clear.frame(height: 1).id(bottomID)
                    }
                    
                }
                
                .onChange(of: engine.outputLog.count) {
                    scrollToBottom(proxy: proxy)
                }
                
                .onChange(of: engine.outputLog.last?.text) {
                    scrollToBottom(proxy: proxy)
                }
                
            }
            
            Divider()
            
            HStack(alignment: .bottom, spacing: 12) {
                TextField("Command...", text: $userInput, axis: .vertical)
                    .textFieldStyle(.plain)
                    .font(.system(.body, design: .monospaced))
                    .focused($isInputFocused)
                    .disabled(!engine.isRunning)
                    .lineLimit(1...8)
                    .onKeyPress(.return) {
                        // If Shift is pressed, let it create a new line
                        if NSEvent.modifierFlags.contains(.shift) {
                            return .ignored
                        }
                        // Otherwise, send the command and block the new line
                        submitCommand()
                        return .handled
                    }
                    .frame(minHeight: 24)
                
                Button(action: submitCommand) {
                    Image(systemName: "paperplane.fill")
                        .font(.title3)
                        .foregroundColor(canSubmit ? .blue : .gray)
                }
                .buttonStyle(.plain)
                .disabled(!canSubmit)
                .padding(.bottom, 5)
            }
            .padding(12)
            .background(Color(NSColor.controlBackgroundColor))
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: onClose) {
                    Image(systemName: "square.grid.2x2")
                        .imageScale(.medium) 
                }
                .help("Return to Tools List")
            }
        }
        .focusedSceneValue(\.terminalActions, TerminalActions(
            start: { startEngine() },
            stop: { engine.sendInterrupt() },
            clear: { engine.outputLog.removeAll() },
            openSettings: { showSettings = true },
            isRunning: engine.isRunning,
            isLogEmpty: engine.outputLog.isEmpty
        ))
        .focusable()
        .onDisappear {
            engine.stop()
        }
    }
    private func scrollToBottom(proxy: ScrollViewProxy, delay: Double = 0.05) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            withAnimation(.easeOut(duration: 0.1)) {
                proxy.scrollTo(bottomID, anchor: .bottom)
            }
        }
    }
    
    private var canSubmit: Bool {
        engine.isRunning
    }
    
    private func submitCommand() {
        guard canSubmit else { return }
        engine.sendInput(userInput)
        userInput = ""
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            isInputFocused = true
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
    @State private var isFavorite = false
    
    @State private var attemptedSubmit = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center) {
                Text("Add New Tool")
                    .font(.title2.weight(.bold))
                
                Spacer()
                
                Button {
                    isFavorite.toggle()
                } label: {
                    Image(systemName: isFavorite ? "star.fill" : "star")
                        .foregroundColor(isFavorite ? .yellow : .secondary)
                        .font(.title3)
                }
                .buttonStyle(.plain)
            }
            .padding(.bottom, 16)
            
            VStack(alignment: .leading, spacing: 12) {
                TextField("Tool Name (e.g. GCal Manager)", text: $name)
                    .textFieldStyle(.roundedBorder)
                    .padding(1)
                    .overlay(
                        RoundedRectangle(cornerRadius: 7)
                            .stroke(Color.red, lineWidth: (attemptedSubmit && name.isEmpty) ? 2 : 0)
                    )
                
                VStack(alignment: .leading) {
                    Text("Python Path:").font(.caption)
                    HStack {
                        TextField("...", text: $pythonPath)
                            .textFieldStyle(.roundedBorder)
                            .padding(1)
                            .overlay(
                                RoundedRectangle(cornerRadius: 7)
                                    .stroke(Color.red, lineWidth: (attemptedSubmit && pythonPath.isEmpty) ? 2 : 0)
                            )
                        Button("Browse") { if let url = selectFile() { pythonPath = url.path } }
                    }
                }
                
                VStack(alignment: .leading) {
                    Text("Script Path (.py):").font(.caption)
                    HStack {
                        TextField("...", text: $scriptPath)
                            .textFieldStyle(.roundedBorder)
                            .padding(1)
                            .overlay(
                                RoundedRectangle(cornerRadius: 7)
                                    .stroke(Color.red, lineWidth: (attemptedSubmit && scriptPath.isEmpty) ? 2 : 0)
                            )
                        Button("Browse") { if let url = selectFile(["py"]) { scriptPath = url.path } }
                    }
                }
            }
            .padding(.bottom, 20)
            HStack {
                Button("Cancel") { isPresented = false }
                Spacer()
                Button("Add Tool") {
                    if name.isEmpty || pythonPath.isEmpty || scriptPath.isEmpty {
                        attemptedSubmit = true
                    } else {
                        let newProfile = ScriptProfile(name: name, pythonPath: pythonPath, scriptPath: scriptPath, isFavorite: isFavorite)
                        profiles.append(newProfile)
                        isPresented = false
                    }
                }
                .buttonStyle(.borderedProminent)
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
    @State private var draftProfile: ScriptProfile // temp copy
    @State private var attemptedSubmit = false
    
    init(profile: Binding<ScriptProfile>, isPresented: Binding<Bool>, onDelete: @escaping () -> Void) {
        self._profile = profile
        self._isPresented = isPresented
        self.onDelete = onDelete
        self._draftProfile = State(initialValue: profile.wrappedValue)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .center) {
                Text("Edit Tool")
                    .font(.title2.weight(.bold))
                Spacer()
                Button {
                    draftProfile.isFavorite.toggle()
                } label: {
                    Image(systemName: draftProfile.isFavorite ? "star.fill" : "star")
                        .foregroundColor(draftProfile.isFavorite ? .yellow : .secondary)
                        .font(.title2)
                }
                .buttonStyle(.plain)
                .help(draftProfile.isFavorite ? "Remove from Favorites" : "Add to Favorites")
            }
            
            TextField("Name", text: $draftProfile.name)
                .textFieldStyle(.roundedBorder)
                .padding(1)
                .overlay(
                    RoundedRectangle(cornerRadius: 7)
                        .stroke(Color.red, lineWidth: (attemptedSubmit && draftProfile.name.isEmpty) ? 2 : 0)
                )
            
            VStack(alignment: .leading) {
                Text("Python Path:").font(.caption)
                HStack {
                    TextField("...", text: $draftProfile.pythonPath)
                        .textFieldStyle(.roundedBorder)
                        .padding(1)
                        .overlay(
                            RoundedRectangle(cornerRadius: 7)
                                .stroke(Color.red, lineWidth: (attemptedSubmit && draftProfile.pythonPath.isEmpty) ? 2 : 0)
                        )
                    Button("Browse") { if let url = selectFile() { draftProfile.pythonPath = url.path } }
                }
            }
            
            VStack(alignment: .leading) {
                Text("Script Path:").font(.caption)
                HStack {
                    TextField("...", text: $draftProfile.scriptPath)
                        .textFieldStyle(.roundedBorder)
                        .padding(1)
                        .overlay(
                            RoundedRectangle(cornerRadius: 7)
                                .stroke(Color.red, lineWidth: (attemptedSubmit && draftProfile.scriptPath.isEmpty) ? 2 : 0)
                        )
                    Button("Browse") { if let url = selectFile(["py"]) { draftProfile.scriptPath = url.path } }
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
                
                Button("Done") {
                    if draftProfile.name.isEmpty || draftProfile.pythonPath.isEmpty || draftProfile.scriptPath.isEmpty {
                        attemptedSubmit = true
                    } else {
                        profile = draftProfile
                        isPresented = false
                    }
                }
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
