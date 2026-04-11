//
//  TimerStackManager.swift
//  FocusTimer
//

import Foundation

// MARK: - Timer Stack Item

struct TimerStackItem: Identifiable, Codable {
    let id: UUID
    var projectName: String
    var sessionsCount: Int
    var mode: FocusModeType
    var isCompleted: Bool = false
    
    init(id: UUID = UUID(), projectName: String, sessionsCount: Int, mode: FocusModeType) {
        self.id = id
        self.projectName = projectName
        self.sessionsCount = sessionsCount
        self.mode = mode
    }
}

// MARK: - Timer Stack Manager

class TimerStackManager: ObservableObject {
    static let shared = TimerStackManager()
    
    @Published var stack: [TimerStackItem] = []
    @Published var currentIndex: Int = 0
    @Published var isQueueMode: Bool = false
    
    var currentItem: TimerStackItem? {
        guard isQueueMode, currentIndex < stack.count else { return nil }
        return stack[currentIndex]
    }
    
    var remainingItems: Int {
        stack.count - currentIndex - 1
    }
    
    var totalSessionsInQueue: Int {
        stack.reduce(0) { $0 + $1.sessionsCount }
    }
    
    var completedSessionsInQueue: Int {
        stack.prefix(currentIndex).reduce(0) { $0 + $1.sessionsCount }
    }
    
    func addToStack(projectName: String, sessionsCount: Int, mode: FocusModeType) {
        let item = TimerStackItem(projectName: projectName, sessionsCount: sessionsCount, mode: mode)
        stack.append(item)
        save()
    }
    
    func removeFromStack(at index: Int) {
        guard index < stack.count else { return }
        stack.remove(at: index)
        if currentIndex >= index && currentIndex > 0 {
            currentIndex -= 1
        }
        save()
    }
    
    func clearStack() {
        stack.removeAll()
        currentIndex = 0
        isQueueMode = false
        save()
    }
    
    func startQueue() {
        guard !stack.isEmpty else { return }
        currentIndex = 0
        isQueueMode = true
        save()
    }
    
    func moveToNext() {
        guard currentIndex < stack.count - 1 else {
            // Queue complete
            isQueueMode = false
            currentIndex = 0
            return
        }
        currentIndex += 1
        save()
    }
    
    func markCurrentCompleted() {
        guard currentIndex < stack.count else { return }
        stack[currentIndex].isCompleted = true
        moveToNext()
    }
    
    func getCurrentMode() -> FocusModeType {
        if isQueueMode, let item = currentItem {
            return item.mode
        }
        return FocusModeManager.shared.currentMode
    }
    
    private func save() {
        if let encoded = try? JSONEncoder().encode(stack) {
            UserDefaults.standard.set(encoded, forKey: "timer_stack")
        }
        UserDefaults.standard.set(currentIndex, forKey: "timer_stack_index")
        UserDefaults.standard.set(isQueueMode, forKey: "timer_stack_active")
    }
    
    func load() {
        if let data = UserDefaults.standard.data(forKey: "timer_stack"),
           let decoded = try? JSONDecoder().decode([TimerStackItem].self, from: data) {
            stack = decoded
        }
        currentIndex = UserDefaults.standard.integer(forKey: "timer_stack_index")
        isQueueMode = UserDefaults.standard.bool(forKey: "timer_stack_active")
    }
}
