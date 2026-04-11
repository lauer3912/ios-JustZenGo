//
//  DailyPlanner.swift
//  FocusTimer
//
//  Daily Focus Planner - plan your day's focus sessions
//

import Foundation
import Combine

// MARK: - Daily Plan

struct DailyPlanItem: Identifiable, Codable {
    let id: UUID
    var projectName: String
    var modeType: FocusModeType
    var plannedSessions: Int
    var completedSessions: Int
    var estimatedMinutes: Int
    var priority: PlanPriority
    var notes: String
    var isCompleted: Bool
    
    enum PlanPriority: String, Codable, CaseIterable {
        case high = "high"
        case medium = "medium"
        case low = "low"
        
        var displayName: String {
            switch self {
            case .high: return "High"
            case .medium: return "Medium"
            case .low: return "Low"
            }
        }
        
        var color: String {
            switch self {
            case .high: return "FF3B30"
            case .medium: return "FF9500"
            case .low: return "4ECB71"
            }
        }
    }
    
    init(projectName: String, modeType: FocusModeType, plannedSessions: Int, priority: PlanPriority = .medium, notes: String = "") {
        self.id = UUID()
        self.projectName = projectName
        self.modeType = modeType
        self.plannedSessions = plannedSessions
        self.completedSessions = 0
        self.estimatedMinutes = plannedSessions * modeType.workDuration / 60
        self.priority = priority
        self.notes = notes
        self.isCompleted = false
    }
}

class DailyPlanner: ObservableObject {
    static let shared = DailyPlanner()
    
    @Published var todayPlan: [DailyPlanItem] = []
    @Published var isPlanActive: Bool = false
    @Published var totalPlannedSessions: Int = 0
    @Published var totalPlannedMinutes: Int = 0
    @Published var currentPlanIndex: Int = 0
    
    private let dataManager = FocusDataManager.shared
    private let modeManager = FocusModeManager.shared
    
    private init() {
        load()
    }
    
    // MARK: - Plan Management
    
    func createPlan() {
        // Auto-generate a plan based on daily goal
        let dailyGoal = dataManager.settings.dailyGoal
        let remainingSessions = dailyGoal - dataManager.statistics.todaySessions
        
        guard remainingSessions > 0 else {
            todayPlan = []
            return
        }
        
        // Create a smart plan
        var plan: [DailyPlanItem] = []
        
        // Morning: Deep Work sessions
        let morningSessions = min(remainingSessions / 2, 3)
        if morningSessions > 0 {
            plan.append(DailyPlanItem(
                projectName: "Morning Deep Work",
                modeType: .deepWork,
                plannedSessions: morningSessions,
                priority: .high,
                notes: "Tackle most important tasks"
            ))
        }
        
        // Mid-day: Mixed sessions
        let midSessions = remainingSessions - morningSessions
        if midSessions > 0 {
            plan.append(DailyPlanItem(
                projectName: "Afternoon Focus",
                modeType: .creativeFlow,
                plannedSessions: midSessions,
                priority: .medium,
                notes: "Creative and administrative work"
            ))
        }
        
        todayPlan = plan
        updateTotals()
    }
    
    func addToPlan(projectName: String, modeType: FocusModeType, sessions: Int, priority: DailyPlanItem.PlanPriority = .medium, notes: String = "") {
        let item = DailyPlanItem(
            projectName: projectName,
            modeType: modeType,
            plannedSessions: sessions,
            priority: priority,
            notes: notes
        )
        todayPlan.append(item)
        updateTotals()
        save()
    }
    
    func removeFromPlan(at index: Int) {
        guard index < todayPlan.count else { return }
        todayPlan.remove(at: index)
        updateTotals()
        save()
    }
    
    func markSessionComplete(at index: Int) {
        guard index < todayPlan.count else { return }
        todayPlan[index].completedSessions += 1
        if todayPlan[index].completedSessions >= todayPlan[index].plannedSessions {
            todayPlan[index].isCompleted = true
        }
        save()
    }
    
    func updatePlanItem(_ item: DailyPlanItem) {
        if let index = todayPlan.firstIndex(where: { $0.id == item.id }) {
            todayPlan[index] = item
            updateTotals()
            save()
        }
    }
    
    func reorderPlan(from source: IndexSet, to destination: Int) {
        todayPlan.move(fromOffsets: source, toOffset: destination)
        save()
    }
    
    func clearPlan() {
        todayPlan = []
        updateTotals()
        isPlanActive = false
        save()
    }
    
    // MARK: - Current Item
    
    var currentItem: DailyPlanItem? {
        guard isPlanActive, currentPlanIndex < todayPlan.count else { return nil }
        return todayPlan[currentPlanIndex]
    }
    
    var nextItem: DailyPlanItem? {
        let nextIndex = currentPlanIndex + 1
        guard nextIndex < todayPlan.count else { return nil }
        return todayPlan[nextIndex]
    }
    
    func startPlan() {
        guard !todayPlan.isEmpty else { return }
        isPlanActive = true
        currentPlanIndex = 0
        save()
    }
    
    func moveToNextItem() {
        if currentPlanIndex < todayPlan.count - 1 {
            currentPlanIndex += 1
            save()
        } else {
            // Plan complete
            isPlanActive = false
            save()
        }
    }
    
    func skipCurrentItem() {
        moveToNextItem()
    }
    
    // MARK: - Statistics
    
    var completedSessions: Int {
        todayPlan.reduce(0) { $0 + $1.completedSessions }
    }
    
    var totalSessions: Int {
        todayPlan.reduce(0) { $0 + $1.plannedSessions }
    }
    
    var progress: Double {
        guard totalSessions > 0 else { return 0 }
        return Double(completedSessions) / Double(totalSessions)
    }
    
    var isPlanCompleted: Bool {
        !todayPlan.isEmpty && todayPlan.allSatisfy { $0.isCompleted }
    }
    
    var remainingSessions: Int {
        totalSessions - completedSessions
    }
    
    // MARK: - Persistence
    
    private func updateTotals() {
        totalPlannedSessions = totalSessions
        totalPlannedMinutes = todayPlan.reduce(0) { $0 + $1.estimatedMinutes }
    }
    
    private func save() {
        if let encoded = try? JSONEncoder().encode(todayPlan) {
            UserDefaults.standard.set(encoded, forKey: "daily_plan")
        }
        UserDefaults.standard.set(isPlanActive, forKey: "plan_active")
        UserDefaults.standard.set(currentPlanIndex, forKey: "plan_current_index")
    }
    
    func load() {
        if let data = UserDefaults.standard.data(forKey: "daily_plan"),
           let decoded = try? JSONDecoder().decode([DailyPlanItem].self, from: data) {
            todayPlan = decoded
        }
        isPlanActive = UserDefaults.standard.bool(forKey: "plan_active")
        currentPlanIndex = UserDefaults.standard.integer(forKey: "plan_current_index")
        updateTotals()
        
        // Check if it's a new day
        if let lastPlanDate = UserDefaults.standard.object(forKey: "last_plan_date") as? Date {
            let calendar = Calendar.current
            if !calendar.isDateInToday(lastPlanDate) {
                // New day - reset plan or keep based on preference
                resetIfNewDay()
            }
        }
    }
    
    func resetIfNewDay() {
        // Reset completed sessions count for new day
        for i in 0..<todayPlan.count {
            todayPlan[i].completedSessions = 0
            todayPlan[i].isCompleted = false
        }
        currentPlanIndex = 0
        isPlanActive = false
        save()
    }
}
