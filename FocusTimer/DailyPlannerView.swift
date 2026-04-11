//
//  DailyPlannerView.swift
//  FocusTimer
//

import SwiftUI

struct DailyPlannerView: View {
    @StateObject private var planner = DailyPlanner.shared
    @StateObject private var modeManager = FocusModeManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var showAddItem: Bool = false
    @State private var editingItem: DailyPlanItem?
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "1C1C1E")
                    .ignoresSafeArea()
                
                if planner.todayPlan.isEmpty {
                    emptyStateView
                } else {
                    planContentView
                }
            }
            .navigationTitle("Daily Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { dismiss() }
                        .foregroundColor(Color(hex: "FF6B6B"))
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showAddItem = true }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(Color(hex: "4ECB71"))
                    }
                }
            }
            .sheet(isPresented: $showAddItem) {
                AddPlanItemView { item in
                    planner.addToPlan(
                        projectName: item.projectName,
                        modeType: item.modeType,
                        sessions: item.plannedSessions,
                        priority: item.priority,
                        notes: item.notes
                    )
                }
            }
        }
        .preferredColorScheme(.dark)
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 64))
                .foregroundColor(Color(hex: "3A3A3C"))
            
            Text("No Plan Yet")
                .font(.title2.bold())
                .foregroundColor(.white)
            
            Text("Plan your focus sessions for today.\nTap + to add your first item.")
                .font(.body)
                .foregroundColor(Color(hex: "8E8E93"))
                .multilineTextAlignment(.center)
            
            Button(action: autoGeneratePlan) {
                Label("Auto-Generate Plan", systemImage: "wand.and.stars")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color(hex: "FF6B6B"))
                    .cornerRadius(12)
            }
            .padding(.top, 20)
            
            Button(action: { showAddItem = true }) {
                Label("Add Manually", systemImage: "plus")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color(hex: "FF6B6B"))
            }
            .padding(.top, 8)
        }
        .padding()
    }
    
    // MARK: - Plan Content
    
    private var planContentView: some View {
        VStack(spacing: 0) {
            // Progress header
            progressHeader
            
            // Plan items
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(Array(planner.todayPlan.enumerated()), id: \.element.id) { index, item in
                        PlanItemRow(
                            item: item,
                            isActive: planner.isPlanActive && index == planner.currentPlanIndex,
                            isCompleted: item.isCompleted,
                            onComplete: {
                                planner.markSessionComplete(at: index)
                            },
                            onEdit: {
                                editingItem = item
                            },
                            onDelete: {
                                planner.removeFromPlan(at: index)
                            }
                        )
                    }
                }
                .padding()
            }
            
            // Bottom actions
            bottomActions
        }
    }
    
    // MARK: - Progress Header
    
    private var progressHeader: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Today's Progress")
                        .font(.caption)
                        .foregroundColor(Color(hex: "8E8E93"))
                    
                    Text("\(planner.completedSessions)/\(planner.totalSessions) sessions")
                        .font(.title2.bold())
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                CircularProgressView(progress: planner.progress, size: 60)
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color(hex: "3A3A3C"))
                        .frame(height: 8)
                        .cornerRadius(4)
                    
                    Rectangle()
                        .fill(Color(hex: "4ECB71"))
                        .frame(width: geometry.size.width * planner.progress, height: 8)
                        .cornerRadius(4)
                }
            }
            .frame(height: 8)
            
            HStack {
                Label("\(planner.remainingSessions) remaining", systemImage: "clock")
                    .font(.caption)
                    .foregroundColor(Color(hex: "8E8E93"))
                
                Spacer()
                
                if planner.isPlanCompleted {
                    Label("Complete!", systemImage: "checkmark.circle.fill")
                        .font(.caption.bold())
                        .foregroundColor(Color(hex: "4ECB71"))
                }
            }
        }
        .padding()
        .background(Color(hex: "2C2C2E"))
    }
    
    // MARK: - Bottom Actions
    
    private var bottomActions: some View {
        VStack(spacing: 12) {
            if !planner.isPlanActive && !planner.todayPlan.isEmpty {
                Button(action: startPlan) {
                    Label("Start Plan", systemImage: "play.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color(hex: "4ECB71"))
                        .cornerRadius(12)
                }
            }
            
            if planner.isPlanActive {
                HStack(spacing: 12) {
                    Button(action: skipCurrent) {
                        Label("Skip", systemImage: "forward.fill")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color(hex: "8E8E93"))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color(hex: "3A3A3C"))
                            .cornerRadius(10)
                    }
                    
                    if let current = planner.currentItem {
                        Button(action: startCurrentSession) {
                            Label("Focus Now", systemImage: "brain.head.profile")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color(hex: "FF6B6B"))
                                .cornerRadius(10)
                        }
                    }
                }
                
                if let next = planner.nextItem {
                    Text("Up next: \(next.projectName)")
                        .font(.caption)
                        .foregroundColor(Color(hex: "8E8E93"))
                }
            }
        }
        .padding()
        .background(Color(hex: "2C2C2E"))
    }
    
    // MARK: - Actions
    
    private func autoGeneratePlan() {
        planner.createPlan()
    }
    
    private func startPlan() {
        planner.startPlan()
        // Navigate to timer
    }
    
    private func skipCurrent() {
        planner.skipCurrentItem()
    }
    
    private func startCurrentSession() {
        // Apply the mode and start timer
        if let current = planner.currentItem {
            modeManager.applyMode(current.modeType)
        }
    }
}

// MARK: - Plan Item Row

struct PlanItemRow: View {
    let item: DailyPlanItem
    let isActive: Bool
    let isCompleted: Bool
    let onComplete: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Completion button
            Button(action: onComplete) {
                Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundColor(isCompleted ? Color(hex: "4ECB71") : Color(hex: "8E8E93"))
            }
            .disabled(isCompleted)
            
            // Item info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(item.projectName)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .strikethrough(isCompleted)
                    
                    // Priority badge
                    Text(item.priority.displayName)
                        .font(.caption2.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(hex: item.priority.color))
                        .cornerRadius(4)
                }
                
                HStack(spacing: 8) {
                    Label("\(item.plannedSessions) sessions", systemImage: "timer")
                        .font(.caption)
                        .foregroundColor(Color(hex: "8E8E93"))
                    
                    Text("•")
                        .foregroundColor(Color(hex: "8E8E93"))
                    
                    Text(item.modeType.displayName)
                        .font(.caption)
                        .foregroundColor(Color(hex: "8E8E93"))
                }
                
                if !item.notes.isEmpty {
                    Text(item.notes)
                        .font(.caption)
                        .foregroundColor(Color(hex: "6C6C70"))
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            // Progress
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(item.completedSessions)/\(item.plannedSessions)")
                    .font(.caption.bold())
                    .foregroundColor(.white)
                
                Text("\(item.estimatedMinutes) min")
                    .font(.caption2)
                    .foregroundColor(Color(hex: "8E8E93"))
            }
            
            // Active indicator
            if isActive {
                Image(systemName: "arrowtriangle.right.fill")
                    .foregroundColor(Color(hex: "FF6B6B"))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(hex: isActive ? "FF6B6B".opacity(0.15) : "2C2C2E"))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isActive ? Color(hex: "FF6B6B").opacity(0.5) : Color.clear, lineWidth: 2)
                )
        )
        .contextMenu {
            Button(action: onEdit) {
                Label("Edit", systemImage: "pencil")
            }
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

// MARK: - Add Plan Item View

struct AddPlanItemView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var modeManager = FocusModeManager.shared
    
    @State private var projectName: String = ""
    @State private var selectedMode: FocusModeType = .deepWork
    @State private var plannedSessions: Int = 2
    @State private var priority: DailyPlanItem.PlanPriority = .medium
    @State private var notes: String = ""
    
    var onAdd: (DailyPlanItem) -> Void
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "1C1C1E")
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Project name
                        VStack(alignment: .leading, spacing: 8) {
                            Text("What will you work on?")
                                .font(.caption)
                                .foregroundColor(Color(hex: "8E8E93"))
                            
                            TextField("Project name", text: $projectName)
                                .textFieldStyle(.plain)
                                .padding(12)
                                .background(Color(hex: "3A3A3C"))
                                .cornerRadius(8)
                                .foregroundColor(.white)
                        }
                        
                        // Focus mode
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Focus Mode")
                                .font(.caption)
                                .foregroundColor(Color(hex: "8E8E93"))
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(FocusModeType.allCases, id: \.self) { mode in
                                        ModeChip(
                                            mode: mode,
                                            isSelected: selectedMode == mode,
                                            onTap: { selectedMode = mode }
                                        )
                                    }
                                }
                            }
                        }
                        
                        // Sessions count
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Planned Sessions: \(plannedSessions)")
                                .font(.caption)
                                .foregroundColor(Color(hex: "8E8E93"))
                            
                            Stepper(value: $plannedSessions, in: 1...10) {
                                EmptyView()
                            }
                            .labelsHidden()
                            
                            HStack {
                                ForEach(1...10, id: \.self) { num in
                                    Circle()
                                        .fill(num <= plannedSessions ? Color(hex: "FF6B6B") : Color(hex: "3A3A3C"))
                                        .frame(width: 24, height: 24)
                                        .onTapGesture {
                                            plannedSessions = num
                                        }
                                }
                            }
                        }
                        
                        // Priority
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Priority")
                                .font(.caption)
                                .foregroundColor(Color(hex: "8E8E93"))
                            
                            HStack(spacing: 8) {
                                ForEach(DailyPlanItem.PlanPriority.allCases, id: \.self) { p in
                                    Button(action: { priority = p }) {
                                        Text(p.displayName)
                                            .font(.caption.bold())
                                            .foregroundColor(priority == p ? .white : Color(hex: "8E8E93"))
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 8)
                                            .background(priority == p ? Color(hex: p.color) : Color(hex: "3A3A3C"))
                                            .cornerRadius(8)
                                    }
                                }
                            }
                        }
                        
                        // Notes
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Notes (optional)")
                                .font(.caption)
                                .foregroundColor(Color(hex: "8E8E93"))
                            
                            TextField("Any additional notes...", text: $notes)
                                .textFieldStyle(.plain)
                                .padding(12)
                                .background(Color(hex: "3A3A3C"))
                                .cornerRadius(8)
                                .foregroundColor(.white)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Add to Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(Color(hex: "8E8E93"))
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        let item = DailyPlanItem(
                            projectName: projectName.isEmpty ? "Focus Session" : projectName,
                            modeType: selectedMode,
                            plannedSessions: plannedSessions,
                            priority: priority,
                            notes: notes
                        )
                        onAdd(item)
                        dismiss()
                    }
                    .foregroundColor(Color(hex: "4ECB71"))
                    .disabled(plannedSessions == 0)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Mode Chip

struct ModeChip: View {
    let mode: FocusModeType
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Image(systemName: mode.icon)
                    .font(.caption)
                Text(mode.displayName)
                    .font(.caption.bold())
            }
            .foregroundColor(isSelected ? .white : Color(hex: "8E8E93"))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color(hex: mode.accentColor) : Color(hex: "3A3A3C"))
            .cornerRadius(20)
        }
    }
}

// MARK: - Circular Progress View

struct CircularProgressView: View {
    let progress: Double
    let size: CGFloat
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color(hex: "3A3A3C"), lineWidth: 6)
                .frame(width: size, height: size)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(Color(hex: "4ECB71"), style: StrokeStyle(lineWidth: 6, lineCap: .round))
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))
            
            Text("\(Int(progress * 100))%")
                .font(.system(size: size / 4, weight: .bold))
                .foregroundColor(.white)
        }
    }
}
