//
//  ContentView.swift
//  Selftape_Assistant
//
//  Created by Work Stuff on 07/04/2025.
//

import SwiftUI
import SwiftData
import AVFoundation

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var scenes: [SceneItem]
    @State private var isShowingNewSceneSheet = false
    @State private var newSceneName = ""
    
    var body: some View {
        NavigationView {
            List {
                ForEach(scenes, id: \.id) { scene in
                    NavigationLink(destination: SceneDetailView(scene: scene)) {
                        VStack(alignment: .leading) {
                            Text(scene.name)
                                .font(.headline)
                            Text(scene.dateCreated.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    .contextMenu {
                        Button(role: .destructive) {
                            modelContext.delete(scene)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
                .onDelete(perform: deleteScenes)
            }
            .navigationTitle("Selftape Scenes")
            .toolbar {
                Button(action: { isShowingNewSceneSheet = true }) {
                    Label("Add Scene", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $isShowingNewSceneSheet) {
            NavigationView {
                Form {
                    TextField("Scene Name", text: $newSceneName)
                }
                .navigationTitle("New Scene")
                .navigationBarItems(
                    leading: Button("Cancel") {
                        isShowingNewSceneSheet = false
                        newSceneName = ""
                    },
                    trailing: Button("Add") {
                        if !newSceneName.isEmpty {
                            let newScene = SceneItem(name: newSceneName)
                            modelContext.insert(newScene)
                            newSceneName = ""
                            isShowingNewSceneSheet = false
                        }
                    }
                    .disabled(newSceneName.isEmpty)
                )
            }
        }
    }
    
    private func deleteScenes(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(scenes[index])
        }
    }
}

struct SceneDetailView: View {
    var scene: SceneItem
    @Environment(\.modelContext) private var modelContext
    @State private var isShowingAddLineSheet = false
    @State private var newLineText = ""
    @State private var isUserLine = true
    
    @StateObject private var audioManager = AudioManager()
    
    var body: some View {
        VStack {
            Text("Scene: \(scene.name)")
                .font(.title)
                .padding()
            
            List {
                if scene.lines.isEmpty {
                    Text("No lines added yet")
                        .foregroundColor(.gray)
                        .italic()
                } else {
                    ForEach(scene.lines.sorted(by: { $0.order < $1.order }), id: \.id) { line in
                        VStack(alignment: .leading) {
                            HStack {
                                Image(systemName: line.isUserLine ? "person" : "person.2")
                                    .foregroundColor(line.isUserLine ? .blue : .green)
                                
                                VStack(alignment: .leading) {
                                    Text(line.isUserLine ? "Me" : "Reader")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    Text(line.text.isEmpty ? "(No text yet)" : line.text)
                                }
                                
                                Spacer()
                                
                                if audioManager.isRecording && audioManager.recordingLine?.id == line.id {
                                    Image(systemName: "waveform")
                                        .foregroundColor(.red)
                                        .padding(.horizontal, 4)
                                }
                            }
                            
                            HStack {
                                Button(action: {
                                    if audioManager.isRecording {
                                        audioManager.stopRecording()
                                    } else {
                                        audioManager.startRecording(for: line)
                                    }
                                }) {
                                    Label(
                                        audioManager.isRecording && audioManager.recordingLine?.id == line.id ? "Stop" : "Record", 
                                        systemImage: audioManager.isRecording && audioManager.recordingLine?.id == line.id ? "stop.circle" : "record.circle"
                                    )
                                    .padding(6)
                                    .background(
                                        audioManager.isRecording && audioManager.recordingLine?.id == line.id ? Color.red : Color.blue
                                    )
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                                }
                                .disabled(audioManager.isRecording && audioManager.recordingLine?.id != line.id)
                                
                                if line.audioFilePath != nil {
                                    Button(action: {
                                        audioManager.playRecording(for: line)
                                    }) {
                                        Label("Play", systemImage: "play.circle")
                                            .padding(6)
                                            .background(Color.green)
                                            .foregroundColor(.white)
                                            .cornerRadius(8)
                                    }
                                    .disabled(audioManager.isRecording)
                                }
                            }
                            .padding(.top, 4)
                        }
                        .padding(.vertical, 4)
                        .contextMenu {
                            Button(role: .destructive) {
                                let orderedLines = scene.lines.sorted(by: { $0.order < $1.order })
                                if let index = orderedLines.firstIndex(where: { $0.id == line.id }) {
                                    deleteLines(at: IndexSet([index]))
                                }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                    .onDelete(perform: deleteLines)
                }
            }
            
            Button(action: {
                isShowingAddLineSheet = true
            }) {
                Label("Add Line", systemImage: "plus")
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .padding()
            .disabled(audioManager.isRecording)
        }
        .sheet(isPresented: $isShowingAddLineSheet) {
            NavigationView {
                Form {
                    Section(header: Text("Line Type")) {
                        Picker("Line Type", selection: $isUserLine) {
                            Text("Me").tag(true)
                            Text("Reader").tag(false)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                    
                    Section(header: Text("Line Text")) {
                        TextField("Enter line text", text: $newLineText)
                    }
                }
                .navigationTitle("Add New Line")
                .navigationBarItems(
                    leading: Button("Cancel") {
                        isShowingAddLineSheet = false
                        resetForm()
                    },
                    trailing: Button("Add") {
                        addNewLine()
                        isShowingAddLineSheet = false
                    }
                )
            }
        }
        .onAppear {
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                if !granted {
                    print("Microphone permission not granted")
                }
            }
        }
    }
    
    private func addNewLine() {
        let newLine = LineItem(
            order: scene.lines.count,
            text: newLineText,
            isUserLine: isUserLine
        )
        
        newLine.scene = scene
        scene.lines.append(newLine)
        
        resetForm()
    }
    
    private func resetForm() {
        newLineText = ""
        isUserLine = true
    }
    
    private func deleteLines(at offsets: IndexSet) {
        let orderedLines = scene.lines.sorted(by: { $0.order < $1.order })
        
        for index in offsets {
            let lineToDelete = orderedLines[index]
            scene.lines.removeAll(where: { $0.id == lineToDelete.id })
            modelContext.delete(lineToDelete)
        }
        
        let remainingLines = scene.lines.sorted(by: { $0.order < $1.order })
        for (index, line) in remainingLines.enumerated() {
            line.order = index
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [SceneItem.self, LineItem.self], inMemory: true)
}
