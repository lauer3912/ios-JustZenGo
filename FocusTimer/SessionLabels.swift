//
//  SessionLabels.swift
//  FocusTimer
//

import Foundation

// MARK: - Session Label

struct SessionLabel: Codable, Identifiable, Hashable {
    let id: UUID
    var name: String
    var color: String
    var usageCount: Int = 0
    
    init(id: UUID = UUID(), name: String, color: String) {
        self.id = id
        self.name = name
        self.color = color
    }
    
    static let defaultLabels: [SessionLabel] = [
        SessionLabel(name: "Deep Work", color: "FF6B6B"),
        SessionLabel(name: "Creative", color: "AF52DE"),
        SessionLabel(name: "Study", color: "5AC8FA"),
        SessionLabel(name: "Writing", color: "FF9500"),
        SessionLabel(name: "Coding", color: "4ECB71"),
        SessionLabel(name: "Reading", color: "FFD60A"),
        SessionLabel(name: "Planning", color: "64D2FF"),
        SessionLabel(name: "Admin", color: "8E8E93")
    ]
}

// MARK: - Session Label Manager

class SessionLabelManager: ObservableObject {
    static let shared = SessionLabelManager()
    
    @Published var labels: [SessionLabel] = SessionLabel.defaultLabels
    @Published var selectedLabel: SessionLabel?
    
    func addLabel(name: String, color: String) {
        let label = SessionLabel(name: name, color: color)
        labels.append(label)
        save()
    }
    
    func removeLabel(_ label: SessionLabel) {
        labels.removeAll { $0.id == label.id }
        if selectedLabel?.id == label.id {
            selectedLabel = nil
        }
        save()
    }
    
    func incrementUsage(for label: SessionLabel) {
        if let index = labels.firstIndex(where: { $0.id == label.id }) {
            labels[index].usageCount += 1
            save()
        }
    }
    
    func selectLabel(_ label: SessionLabel?) {
        selectedLabel = label
        if let label = label {
            incrementUsage(for: label)
        }
    }
    
    func getMostUsed(limit: Int = 5) -> [SessionLabel] {
        labels.sorted { $0.usageCount > $1.usageCount }.prefix(limit).map { $0 }
    }
    
    private func save() {
        if let encoded = try? JSONEncoder().encode(labels) {
            UserDefaults.standard.set(encoded, forKey: "session_labels")
        }
    }
    
    func load() {
        if let data = UserDefaults.standard.data(forKey: "session_labels"),
           let decoded = try? JSONDecoder().decode([SessionLabel].self, from: data) {
            labels = decoded
        }
    }
}
