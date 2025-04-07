//
//  ContentView.swift
//  Selftape_Assistant
//
//  Created by Work Stuff on 07/04/2025.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var scenes: [SceneItem]
    @State private var isShowingNewSceneSheet = false
    @State private var newSceneName = ""
    
    var body: some View {
        NavigationView {
            List {
                ForEach(scenes, id: \.id) { scene in
                    NavigationLink(destination: Text(scene.name)) {
                        VStack(alignment: .leading) {
                            Text(scene.name)
                                .font(.headline)
                            Text(scene.dateCreated.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption)
                                .foregroundColor(.gray)
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

#Preview {
    ContentView()
        .modelContainer(for: SceneItem.self, inMemory: true)
}
