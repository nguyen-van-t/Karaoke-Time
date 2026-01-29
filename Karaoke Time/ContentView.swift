//
//  ContentView.swift
//  Karaoke Time
//
//  Main karaoke interface with microphone and music controls
//

import SwiftUI

struct ContentView: View {
    @StateObject private var audioManager = AudioManager()
    @StateObject private var musicPlayer = MusicPlayer()
    
    var body: some View {
        ZStack {
            // Background
            KaraokeTheme.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                headerView
                    .padding(.top, 20)
                
                Spacer()
                
                // Main Microphone Button
                microphoneButton
                
                Spacer()
                
                // Music Player Controls
                musicPlayerView
                    .padding(.horizontal, 24)
                    .padding(.bottom, 20)
                
                // Volume Controls
                volumeControlsView
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
            }
        }
        .preferredColorScheme(.dark)
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        VStack(spacing: 8) {
            Text("🎤 Karaoke Time")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(KaraokeTheme.primaryGradient)
            
            Text(audioManager.isMicrophoneActive ? "Microphone Active" : "Tap to Start Singing")
                .font(.subheadline)
                .foregroundColor(audioManager.isMicrophoneActive ? KaraokeTheme.primaryGreen : KaraokeTheme.textSecondary)
        }
    }
    
    // MARK: - Microphone Button
    
    private var microphoneButton: some View {
        VStack(spacing: 24) {
            // Big microphone button
            Button {
                Task {
                    await audioManager.toggleMicrophone()
                }
            } label: {
                ZStack {
                    // Outer glow ring when active
                    if audioManager.isMicrophoneActive {
                        Circle()
                            .stroke(KaraokeTheme.primaryGreen.opacity(0.3), lineWidth: 4)
                            .frame(width: 160, height: 160)
                            .blur(radius: 10)
                    }
                    
                    // Main button
                    Circle()
                        .fill(
                            audioManager.isMicrophoneActive
                                ? KaraokeTheme.primaryGradient
                                : LinearGradient(colors: [KaraokeTheme.surface], startPoint: .top, endPoint: .bottom)
                        )
                        .frame(width: 140, height: 140)
                        .overlay(
                            Circle()
                                .stroke(KaraokeTheme.primaryGreen, lineWidth: 4)
                        )
                        .shadow(color: audioManager.isMicrophoneActive ? KaraokeTheme.glowGreen : KaraokeTheme.primaryGreen.opacity(0.2), radius: audioManager.isMicrophoneActive ? 40 : 15)
                    
                    // Microphone icon
                    Image(systemName: audioManager.isMicrophoneActive ? "mic.fill" : "mic")
                        .font(.system(size: 50, weight: .medium))
                        .foregroundColor(audioManager.isMicrophoneActive ? KaraokeTheme.background : KaraokeTheme.primaryGreen)
                }
            }
            .buttonStyle(PlainButtonStyle())
            .scaleEffect(audioManager.isMicrophoneActive ? 1.05 : 1.0)
            .animation(.spring(response: 0.4, dampingFraction: 0.6), value: audioManager.isMicrophoneActive)
            
            // Audio level indicator
            if audioManager.isMicrophoneActive {
                audioLevelIndicator
            }
            
            // Error message
            if let error = audioManager.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(KaraokeTheme.error)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
        }
    }
    
    private var audioLevelIndicator: some View {
        HStack(spacing: 4) {
            ForEach(0..<10, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(index < Int(audioManager.microphoneLevel * 10)
                          ? KaraokeTheme.primaryGreen
                          : KaraokeTheme.border)
                    .frame(width: 8, height: 20 + CGFloat(index) * 2)
            }
        }
        .frame(height: 40)
        .animation(.easeOut(duration: 0.1), value: audioManager.microphoneLevel)
    }
    
    // MARK: - Music Player
    
    private var musicPlayerView: some View {
        VStack(spacing: 16) {
            // Song title
            Text(musicPlayer.songTitle)
                .font(.headline)
                .foregroundColor(KaraokeTheme.textPrimary)
                .lineLimit(1)
            
            // Progress bar
            VStack(spacing: 8) {
                Slider(
                    value: Binding(
                        get: { musicPlayer.currentTime },
                        set: { musicPlayer.seek(to: $0) }
                    ),
                    in: 0...max(musicPlayer.duration, 1)
                )
                .accentColor(KaraokeTheme.primaryGreen)
                
                HStack {
                    Text(MusicPlayer.formatTime(musicPlayer.currentTime))
                        .font(.caption)
                        .foregroundColor(KaraokeTheme.textSecondary)
                    
                    Spacer()
                    
                    Text(MusicPlayer.formatTime(musicPlayer.duration))
                        .font(.caption)
                        .foregroundColor(KaraokeTheme.textSecondary)
                }
            }
            
            // Playback controls
            HStack(spacing: 40) {
                // Stop button
                Button {
                    musicPlayer.stop()
                } label: {
                    Image(systemName: "stop.fill")
                        .font(.title2)
                        .foregroundColor(KaraokeTheme.textSecondary)
                        .frame(width: 50, height: 50)
                        .background(KaraokeTheme.surface)
                        .clipShape(Circle())
                }
                
                // Play/Pause button
                Button {
                    musicPlayer.togglePlayPause()
                } label: {
                    Image(systemName: musicPlayer.isPlaying ? "pause.fill" : "play.fill")
                        .font(.title)
                        .foregroundColor(KaraokeTheme.background)
                        .frame(width: 70, height: 70)
                        .background(KaraokeTheme.primaryGradient)
                        .clipShape(Circle())
                        .shadow(color: KaraokeTheme.glowGreen, radius: 15)
                }
            }
            
            // Error message for music player
            if let error = musicPlayer.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(KaraokeTheme.error)
            }
        }
        .padding(24)
        .background(KaraokeTheme.surface)
        .cornerRadius(24)
        .glowingBorder(isActive: musicPlayer.isPlaying)
    }
    
    // MARK: - Volume Controls
    
    private var volumeControlsView: some View {
        VStack(spacing: 16) {
            // Microphone volume
            HStack(spacing: 12) {
                Image(systemName: "mic.fill")
                    .foregroundColor(KaraokeTheme.primaryGreen)
                    .frame(width: 24)
                
                Slider(value: $audioManager.microphoneVolume, in: 0...1)
                    .accentColor(KaraokeTheme.primaryGreen)
                
                Text("\(Int(audioManager.microphoneVolume * 100))%")
                    .font(.caption)
                    .foregroundColor(KaraokeTheme.textSecondary)
                    .frame(width: 40)
            }
            
            // Music volume
            HStack(spacing: 12) {
                Image(systemName: "music.note")
                    .foregroundColor(KaraokeTheme.primaryGreen)
                    .frame(width: 24)
                
                Slider(value: $musicPlayer.volume, in: 0...1)
                    .accentColor(KaraokeTheme.primaryGreen)
                
                Text("\(Int(musicPlayer.volume * 100))%")
                    .font(.caption)
                    .foregroundColor(KaraokeTheme.textSecondary)
                    .frame(width: 40)
            }
        }
        .padding(20)
        .background(KaraokeTheme.surface)
        .cornerRadius(16)
    }
}

#Preview {
    ContentView()
}
