//
//  SettingsView.swift
//  JustZen
//

import SwiftUI

struct SettingsView: View {
    @StateObject private var dataManager = FocusDataManager.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "1C1C1E")
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Timer Settings
                        SettingsSection(title: "Timer Settings") {
                            VStack(spacing: 16) {
                                DurationSettingRow(
                                    title: "Focus Duration",
                                    value: $dataManager.settings.workDuration,
                                    range: 5...60,
                                    unit: "min"
                                )
                                
                                DurationSettingRow(
                                    title: "Short Break",
                                    value: $dataManager.settings.shortBreakDuration,
                                    range: 1...15,
                                    unit: "min"
                                )
                                
                                DurationSettingRow(
                                    title: "Long Break",
                                    value: $dataManager.settings.longBreakDuration,
                                    range: 10...30,
                                    unit: "min"
                                )
                                
                                StepperSettingRow(
                                    title: "Sessions until Long Break",
                                    value: $dataManager.settings.sessionsUntilLongBreak,
                                    range: 2...8
                                )
                            }
                        }
                        
                        // Goal Settings
                        SettingsSection(title: "Daily Goal") {
                            StepperSettingRow(
                                title: "Daily Focus Sessions",
                                value: $dataManager.settings.dailyGoal,
                                range: 1...20
                            )
                        }
                        
                        // Notification Settings
                        SettingsSection(title: "Notifications") {
                            ToggleSettingRow(
                                title: "Enable Notifications",
                                isOn: $dataManager.settings.notificationEnabled
                            )
                            
                            ToggleSettingRow(
                                title: "Sound",
                                isOn: $dataManager.settings.soundEnabled
                            )
                        }
                        
                        SettingsSection(title: "Smart Reminders") {
                            ToggleSettingRow(
                                title: "Enable Reminders",
                                isOn: $dataManager.settings.reminderEnabled
                            )
                            
                            if dataManager.settings.reminderEnabled {
                                DatePicker(
                                    "Morning Reminder",
                                    selection: Binding(
                                        get: { dataManager.settings.morningReminderTime ?? defaultMorningTime() },
                                        set: { dataManager.settings.morningReminderTime = $0 }
                                    ),
                                    displayedComponents: .hourAndMinute
                                )
                                .foregroundColor(.white)
                                .datePickerStyle(.compact)
                                
                                DatePicker(
                                    "Evening Reminder",
                                    selection: Binding(
                                        get: { dataManager.settings.eveningReminderTime ?? defaultEveningTime() },
                                        set: { dataManager.settings.eveningReminderTime = $0 }
                                    ),
                                    displayedComponents: .hourAndMinute
                                )
                                .foregroundColor(.white)
                                .datePickerStyle(.compact)
                                
                                ToggleSettingRow(
                                    title: "Auto-Start Breaks",
                                    isOn: $dataManager.settings.autoStartBreaks
                                )
                                
                                ToggleSettingRow(
                                    title: "Auto-Start Work",
                                    isOn: $dataManager.settings.autoStartWork
                                )
                            }
                        }
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dataManager.saveSettings()
                        dismiss()
                    }
                    .foregroundColor(Color(hex: "FF6B6B"))
                    .accessibilityIdentifier("done_settings")
                }
            }
            .toolbarBackground(Color(hex: "1C1C1E"), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Settings Components

struct SettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color(hex: "8E8E93"))
                .textCase(.uppercase)
            
            VStack(spacing: 0) {
                content
            }
            .background(Color(hex: "2C2C2E"))
            .cornerRadius(12)
        }
    }
}

struct DurationSettingRow: View {
    let title: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    let unit: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 16))
                .foregroundColor(.white)
            
            Spacer()
            
            HStack(spacing: 12) {
                Button(action: {
                    if value > range.lowerBound * 60 {
                        value -= 60
                    }
                }) {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(Color(hex: "8E8E93"))
                }
                
                Text("\(value / 60)")
                    .font(.system(size: 18, weight: .semibold, design: .monospaced))
                    .foregroundColor(.white)
                    .frame(minWidth: 40)
                
                Button(action: {
                    if value < range.upperBound * 60 {
                        value += 60
                    }
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(Color(hex: "FF6B6B"))
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

struct StepperSettingRow: View {
    let title: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 16))
                .foregroundColor(.white)
            
            Spacer()
            
            HStack(spacing: 16) {
                Button(action: {
                    if value > range.lowerBound {
                        value -= 1
                    }
                }) {
                    Image(systemName: "minus")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 28, height: 28)
                        .background(Color(hex: "3A3A3C"))
                        .cornerRadius(6)
                }
                
                Text("\(value)")
                    .font(.system(size: 18, weight: .semibold, design: .monospaced))
                    .foregroundColor(.white)
                    .frame(minWidth: 30)
                
                Button(action: {
                    if value < range.upperBound {
                        value += 1
                    }
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 28, height: 28)
                        .background(Color(hex: "FF6B6B"))
                        .cornerRadius(6)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

struct ToggleSettingRow: View {
    let title: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 16))
                .foregroundColor(.white)
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(Color(hex: "FF6B6B"))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - Helper Functions

private func defaultMorningTime() -> Date {
    var components = DateComponents()
    components.hour = 9
    components.minute = 0
    return Calendar.current.date(from: components) ?? Date()
}

private func defaultEveningTime() -> Date {
    var components = DateComponents()
    components.hour = 20
    components.minute = 0
    return Calendar.current.date(from: components) ?? Date()
}

#Preview {
    SettingsView()
}
