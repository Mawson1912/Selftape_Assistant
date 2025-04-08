//
//  AudioManager.swift
//  Selftape_Assistant
//
//  Created by Work Stuff on 08/04/2025.
//

import Foundation
import AVFoundation
import SwiftUI

class AudioManager: NSObject, ObservableObject, AVAudioRecorderDelegate {
    // Published properties to observe in the UI
    @Published var isRecording = false
    @Published var recordingLine: LineItem? = nil
    
    // Audio components
    private var audioRecorder: AVAudioRecorder?
    private var audioPlayer: AVAudioPlayer?
    
    // Directory management functions
    func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    func getSceneDirectory(for sceneId: UUID) -> URL {
        let sceneDir = getDocumentsDirectory().appendingPathComponent("Scene_\(sceneId.uuidString)")
        
        // Create directory if it doesn't exist
        if !FileManager.default.fileExists(atPath: sceneDir.path) {
            do {
                try FileManager.default.createDirectory(at: sceneDir, withIntermediateDirectories: true)
            } catch {
                print("Error creating scene directory: \(error)")
            }
        }
        
        return sceneDir
    }
    
    func getAudioFileURL(for line: LineItem) -> URL? {
        guard let scene = line.scene else { return nil }
        
        let fileName = "line_\(line.id.uuidString).m4a"
        let fileURL = getSceneDirectory(for: scene.id).appendingPathComponent(fileName)
        
        return fileURL
    }
    
    // Recording functions
    func startRecording(for line: LineItem) {
        // Set up audio session
        let audioSession = AVAudioSession.sharedInstance()
        
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default)
            try audioSession.setActive(true)
            
            // Get the file URL
            guard let fileURL = getAudioFileURL(for: line) else {
                print("Could not get file URL for line")
                return
            }
            
            // Audio settings
            let settings = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44100,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            
            // Create and configure recorder
            audioRecorder = try AVAudioRecorder(url: fileURL, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.prepareToRecord()
            
            // Start recording
            audioRecorder?.record()
            isRecording = true
            recordingLine = line
            
            // Store the path in the line model
            line.audioFilePath = fileURL.path
            
        } catch {
            print("Failed to start recording: \(error)")
        }
    }
    
    func stopRecording() {
        audioRecorder?.stop()
        isRecording = false
        recordingLine = nil
    }
    
    // Playback functions
    func playRecording(for line: LineItem) {
        // Ensure we have a path
        guard let path = line.audioFilePath,
              FileManager.default.fileExists(atPath: path) else {
            print("No recording exists for this line")
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: path))
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
        } catch {
            print("Failed to play recording: \(error)")
        }
    }
    
    // AVAudioRecorderDelegate methods
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        isRecording = false
        
        if !flag {
            print("Recording failed")
            // If recording failed, clear the path
            recordingLine?.audioFilePath = nil
        }
        
        recordingLine = nil
    }
} 