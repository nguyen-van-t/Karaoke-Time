//
//  AudioManager.swift
//  Karaoke Time
//
//  Handles microphone input and real-time passthrough to speakers
//

import AVFoundation
import Combine

@MainActor
class AudioManager: ObservableObject {
    private let audioEngine = AVAudioEngine()
    private var isConfigured = false
    
    @Published var isMicrophoneActive = false
    @Published var microphoneLevel: Float = 0.0
    @Published var errorMessage: String?
    
    /// Volume for microphone passthrough (0.0 to 1.0)
    @Published var microphoneVolume: Float = 1.0 {
        didSet {
            updateMicrophoneVolume()
        }
    }
    
    /// Gain boost for microphone (1.0 to 4.0, where 1.0 is no boost)
    @Published var microphoneGain: Float = 2.0 {
        didSet {
            updateMicrophoneVolume()
        }
    }
    
    private var mixerNode: AVAudioMixerNode?
    
    init() {
        setupNotifications()
    }
    
    // MARK: - Audio Session Configuration
    
    private func configureAudioSession() throws {
        let session = AVAudioSession.sharedInstance()
        
        // Configure for playback and recording simultaneously
        // Using voiceChat mode enables echo cancellation and noise suppression
        try session.setCategory(.playAndRecord, mode: .voiceChat, options: [
            .defaultToSpeaker,
            .allowBluetooth,
            .allowBluetoothA2DP
        ])
        
        // Set preferred sample rate and buffer duration for low latency
        try session.setPreferredSampleRate(44100)
        try session.setPreferredIOBufferDuration(0.005) // 5ms buffer for low latency
        
        try session.setActive(true)
    }
    
    // MARK: - Audio Engine Setup
    
    private func setupAudioEngine() throws {
        guard !isConfigured else { return }
        
        let inputNode = audioEngine.inputNode
        let mainMixer = audioEngine.mainMixerNode
        
        // Get the input format
        let inputFormat = inputNode.outputFormat(forBus: 0)
        
        // Create a mixer for the microphone with volume control
        let micMixer = AVAudioMixerNode()
        self.mixerNode = micMixer
        audioEngine.attach(micMixer)
        
        // Connect input -> mic mixer -> main mixer -> output
        audioEngine.connect(inputNode, to: micMixer, format: inputFormat)
        audioEngine.connect(micMixer, to: mainMixer, format: inputFormat)
        
        // Set initial volume with gain boost applied
        micMixer.outputVolume = microphoneVolume * microphoneGain
        
        // Boost the main mixer output as well for overall louder sound
        mainMixer.outputVolume = 1.0
        
        // Install tap to monitor audio levels
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: inputFormat) { [weak self] buffer, _ in
            self?.processAudioBuffer(buffer)
        }
        
        isConfigured = true
    }
    
    private func processAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData else { return }
        
        let channelDataValue = channelData.pointee
        let channelDataValueArray = stride(from: 0, to: Int(buffer.frameLength), by: buffer.stride).map { channelDataValue[$0] }
        
        let rms = sqrt(channelDataValueArray.map { $0 * $0 }.reduce(0, +) / Float(buffer.frameLength))
        let avgPower = 20 * log10(rms)
        let normalizedLevel = max(0, min(1, (avgPower + 50) / 50))
        
        Task { @MainActor in
            self.microphoneLevel = normalizedLevel
        }
    }
    
    // MARK: - Public Methods
    
    func requestMicrophonePermission() async -> Bool {
        return await withCheckedContinuation { continuation in
            AVAudioApplication.requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }
    
    func startMicrophone() async {
        // Check permission first
        let hasPermission = await requestMicrophonePermission()
        guard hasPermission else {
            errorMessage = "Microphone permission denied. Please enable in Settings."
            return
        }
        
        do {
            try configureAudioSession()
            try setupAudioEngine()
            try audioEngine.start()
            isMicrophoneActive = true
            errorMessage = nil
        } catch {
            errorMessage = "Failed to start microphone: \(error.localizedDescription)"
            isMicrophoneActive = false
        }
    }
    
    func stopMicrophone() {
        if audioEngine.isRunning {
            audioEngine.stop()
        }
        isMicrophoneActive = false
        microphoneLevel = 0
    }
    
    func toggleMicrophone() async {
        if isMicrophoneActive {
            stopMicrophone()
        } else {
            await startMicrophone()
        }
    }
    
    private func updateMicrophoneVolume() {
        mixerNode?.outputVolume = microphoneVolume * microphoneGain
    }
    
    // MARK: - Notifications
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleInterruption(notification)
        }
        
        NotificationCenter.default.addObserver(
            forName: AVAudioSession.routeChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleRouteChange(notification)
        }
    }
    
    private func handleInterruption(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }
        
        switch type {
        case .began:
            stopMicrophone()
        case .ended:
            // Could auto-restart here if desired
            break
        @unknown default:
            break
        }
    }
    
    private func handleRouteChange(_ notification: Notification) {
        // Audio route changed (e.g., Bluetooth connected/disconnected)
        // The system handles routing automatically
    }
}
