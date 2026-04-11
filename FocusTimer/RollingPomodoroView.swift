//
//  RollingPomodoroView.swift
//  FocusTimer
//

import SwiftUI

struct RollingPomodoroView: View {
    @StateObject private var rolling = RollingPomodoroManager.shared
    @StateObject private var modeManager = FocusModeManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var showSettings: Bool = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient based on phase
                LinearGradient(
                    colors: [Color(hex: rolling.currentPhase.color).opacity(0.3), Color(hex: "1C1C1E")],
                    startPoint: .top,
                    endPoint: .center
                )
                .ignoresSafeArea()
                
                VStack(spacing: 32) {
                    Spacer()
                    
                    // Phase indicator
                    phaseIndicator
                    
                    // Timer circle
                    timerCircle
                    
                    // Stats
                    statsRow
                    
                    Spacer()
                    
                    // Controls
                    controlButtons
                    
                    // Bottom info
                    bottomInfo
                }
                .padding()
            }
            .navigationTitle("Rolling Pomodoro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { dismiss() }
                        .foregroundColor(Color(hex: "8E8E93"))
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showSettings = true }) {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(Color(hex: "8E8E93"))
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                RollingSettingsView()
            }
        }
        .preferredColorScheme(.dark)
    }
    
    // MARK: - Phase Indicator
    
    private var phaseIndicator: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                Circle()
                    .fill(Color(hex: rolling.currentPhase.color))
                    .frame(width: 12, height: 12)
                
                Text(rolling.currentPhase.rawValue)
                    .font(.title3.bold())
                    .foregroundColor(.white)
            }
            
            Text(rolling.currentPhase == .work 
                ? "Stay focused! Micro-break coming up." 
                : "Take a short breath...")
                .font(.caption)
                .foregroundColor(Color(hex: "8E8E93"))
        }
    }
    
    // MARK: - Timer Circle
    
    private var timerCircle: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(Color(hex: "3A3A3C"), lineWidth: 12)
                .frame(width: 250, height: 250)
            
            // Progress circle
            Circle()
                .trim(from: 0, to: rolling.progress)
                .stroke(
                    Color(hex: rolling.currentPhase.color),
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .frame(width: 250, height: 250)
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1), value: rolling.progress)
            
            // Time display
            VStack(spacing: 4) {
                Text(rolling.formattedTime)
                    .font(.system(size: 56, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                
                Text("Session \(rolling.sessionCount + 1)")
                    .font(.caption)
                    .foregroundColor(Color(hex: "8E8E93"))
            }
        }
    }
    
    // MARK: - Stats Row
    
    private var statsRow: some View {
        HStack(spacing: 32) {
            StatItem(title: "Total Work", value: rolling.totalWorkTimeFormatted, icon: "clock.fill", color: .orange)
            StatItem(title: "Sessions", value: "\(rolling.sessionCount)", icon: "checkmark.circle.fill", color: .green)
            StatItem(title: "Status", value: rolling.isPaused ? "Paused" : "Running", icon: rolling.isPaused ? "pause.fill" : "play.fill", color: .blue)
        }
        .padding()
        .background(Color(hex: "2C2C2E"))
        .cornerRadius(16)
    }
    
    // MARK: - Control Buttons
    
    private var controlButtons: some View {
        HStack(spacing: 24) {
            if rolling.isActive {
                // Stop button
                Button(action: { rolling.stop() }) {
                    Image(systemName: "stop.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                        .frame(width: 60, height: 60)
                        .background(Color(hex: "FF3B30"))
                        .clipShape(Circle())
                }
                
                // Pause/Resume button
                Button(action: { 
                    if rolling.isPaused {
                        rolling.resume()
                    } else {
                        rolling.pause()
                    }
                }) {
                    Image(systemName: rolling.isPaused ? "play.fill" : "pause.fill")
                        .font(.title)
                        .foregroundColor(.white)
                        .frame(width: 80, height: 80)
                        .background(Color(hex: rolling.currentPhase.color))
                        .clipShape(Circle())
                }
                
                // Skip micro-break button
                if rolling.currentPhase == .microBreak {
                    Button(action: { rolling.skipMicroBreak() }) {
                        Image(systemName: "forward.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(width: 60, height: 60)
                            .background(Color(hex: "4ECB71"))
                            .clipShape(Circle())
                    }
                } else {
                    Color.clear
                        .frame(width: 60, height: 60)
                }
            } else {
                // Start button
                Button(action: { rolling.start() }) {
                    Label("Start Rolling", systemImage: "play.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 16)
                        .background(Color(hex: "FF6B6B"))
                        .cornerRadius(30)
                }
            }
        }
    }
    
    // MARK: - Bottom Info
    
    private var bottomInfo: some View {
        VStack(spacing: 8) {
            Text("Rolling Pomodoro")
                .font(.caption.bold())
                .foregroundColor(Color(hex: "8E8E93"))
            
            Text("Work sessions connect end-to-end with 1-minute micro-breaks")
                .font(.caption2)
                .foregroundColor(Color(hex: "6C6C70"))
                .multilineTextAlignment(.center)
        }
        .padding(.bottom, 16)
    }
}

// MARK: - Stat Item

struct StatItem: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
            
            Text(title)
                .font(.caption2)
                .foregroundColor(Color(hex: "8E8E93"))
        }
    }
}

// MARK: - Rolling Settings View

struct RollingSettingsView: View {
    @StateObject private var rolling = RollingPomodoroManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var microBreakMinutes: Double = 1
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "1C1C1E")
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Micro-break duration
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Micro-Break Duration")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        HStack {
                            Slider(value: $microBreakMinutes, in: 0.5...3, step: 0.5)
                                .tint(Color(hex: "4ECB71"))
                            
                            Text("\(Int(microBreakMinutes * 60))s")
                                .font(.system(.body, design: .monospaced))
                                .foregroundColor(.white)
                                .frame(width: 50)
                        }
                        
                        Text("How long each micro-break lasts")
                            .font(.caption)
                            .foregroundColor(Color(hex: "8E8E93"))
                    }
                    .padding()
                    .background(Color(hex: "2C2C2E"))
                    .cornerRadius(12)
                    
                    // Auto-resume toggle
                    Toggle(isOn: Binding(
                        get: { rolling.autoResume },
                        set: { rolling.setAutoResume($0) }
                    )) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Auto-Resume After Break")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Text("Automatically start next work phase")
                                .font(.caption)
                                .foregroundColor(Color(hex: "8E8E93"))
                        }
                    }
                    .tint(Color(hex: "4ECB71"))
                    .padding()
                    .background(Color(hex: "2C2C2E"))
                    .cornerRadius(12)
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Rolling Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(Color(hex: "FF6B6B"))
                }
            }
            .onAppear {
                microBreakMinutes = Double(rolling.microBreakDuration) / 60.0
            }
            .onChange(of: microBreakMinutes) { _, newValue in
                rolling.setMicroBreakDuration(Int(newValue * 60))
            }
        }
        .preferredColorScheme(.dark)
    }
}
