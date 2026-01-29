//
//  MusicPlayer.swift
//  Karaoke Time
//
//  Handles music playback with play/pause controls
//

import AVFoundation
import Combine
import SwiftUI

@MainActor
class MusicPlayer: ObservableObject {
    private var audioPlayer: AVAudioPlayer?
    private var progressTimer: Timer?
    
    @Published var isPlaying = false
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var songTitle: String = "No song loaded"
    @Published var errorMessage: String?
    
    @Published var volume: Float = 0.8 {
        didSet {
            audioPlayer?.volume = volume
        }
    }
    
    init() {
        loadSampleSong()
    }
    
    // MARK: - Song Loading
    
    private func loadSampleSong() {
        // Check for bundled sample song
        if let url = Bundle.main.url(forResource: "sample", withExtension: "mp3") {
            loadSong(from: url)
        } else if let url = Bundle.main.url(forResource: "sample", withExtension: "m4a") {
            loadSong(from: url)
        } else {
            songTitle = "Add a song to get started"
        }
    }
    
    func loadSong(from url: URL) {
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.prepareToPlay()
            audioPlayer?.volume = volume
            duration = audioPlayer?.duration ?? 0
            songTitle = url.deletingPathExtension().lastPathComponent
            currentTime = 0
            errorMessage = nil
        } catch {
            errorMessage = "Failed to load song: \(error.localizedDescription)"
            songTitle = "Error loading song"
        }
    }
    
    // MARK: - Playback Controls
    
    func play() {
        guard let player = audioPlayer else {
            errorMessage = "No song loaded"
            return
        }
        
        player.play()
        isPlaying = true
        startProgressTimer()
    }
    
    func pause() {
        audioPlayer?.pause()
        isPlaying = false
        stopProgressTimer()
    }
    
    func stop() {
        audioPlayer?.stop()
        audioPlayer?.currentTime = 0
        isPlaying = false
        currentTime = 0
        stopProgressTimer()
    }
    
    func togglePlayPause() {
        if isPlaying {
            pause()
        } else {
            play()
        }
    }
    
    func seek(to time: TimeInterval) {
        audioPlayer?.currentTime = time
        currentTime = time
    }
    
    // MARK: - Progress Timer
    
    private func startProgressTimer() {
        stopProgressTimer()
        
        // Use a Timer to update progress
        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                
                if let player = self.audioPlayer {
                    self.currentTime = player.currentTime
                    
                    // Check if song ended
                    if !player.isPlaying && self.isPlaying {
                        self.isPlaying = false
                        self.currentTime = 0
                        self.stopProgressTimer()
                    }
                }
            }
        }
    }
    
    private func stopProgressTimer() {
        progressTimer?.invalidate()
        progressTimer = nil
    }
    
    // MARK: - Time Formatting
    
    static func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
