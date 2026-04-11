//
//  CalendarIntegration.swift
//  FocusTimer
//

import Foundation
import EventKit
import Combine

// MARK: - Calendar Event

struct FocusCalendarEvent: Identifiable {
    let id: String
    let title: String
    let startDate: Date
    let endDate: Date
    let isAllDay: Bool
}

// MARK: - Calendar Integration Manager

class CalendarIntegration: ObservableObject {
    static let shared = CalendarIntegration()
    
    @Published var isAuthorized: Bool = false
    @Published var todayEvents: [FocusCalendarEvent] = []
    @Published var freeWindows: [(start: Date, end: Date)] = []
    
    private let eventStore = EKEventStore()
    
    var authorizationStatus: EKAuthorizationStatus {
        EKEventStore.authorizationStatus(for: .event)
    }
    
    func requestAccess() async -> Bool {
        do {
            if #available(iOSApplicationExtension 17.0, *) {
                let granted = try await eventStore.requestFullAccessToEvents()
                await MainActor.run {
                    isAuthorized = granted
                }
                return granted
            } else {
                let granted = try await eventStore.requestAccess(to: .event)
                await MainActor.run {
                    isAuthorized = granted
                }
                return granted
            }
        } catch {
            print("Calendar access error: \(error)")
            return false
        }
    }
    
    func fetchTodayEvents() {
        guard isAuthorized else { return }
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let predicate = eventStore.predicateForEvents(
            withStart: startOfDay,
            end: endOfDay,
            calendars: nil
        )
        
        let events = eventStore.events(matching: predicate)
        
        todayEvents = events.map { event in
            FocusCalendarEvent(
                id: event.eventIdentifier ?? UUID().uuidString,
                title: event.title ?? "Untitled",
                startDate: event.startDate,
                endDate: event.endDate,
                isAllDay: event.isAllDay
            )
        }
    }
    
    func findFreeWindows(duration: Int = 25 * 60) -> [(start: Date, end: Date)] {
        guard isAuthorized else { return [] }
        
        fetchTodayEvents()
        
        let calendar = Calendar.current
        let now = Date()
        var freeWindows: [(start: Date, end: Date)] = []
        
        let sortedEvents = todayEvents.sorted { $0.startDate < $1.startDate }
        
        var currentTime = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: now)!
        
        // If before 9am, start at 9am
        if currentTime < now {
            currentTime = now
        }
        
        let endOfWorkDay = calendar.date(bySettingHour: 18, minute: 0, second: 0, of: now)!
        
        for event in sortedEvents {
            if event.startDate > currentTime {
                // There's a gap before this event
                let gapStart = currentTime
                let gapEnd = event.startDate
                let gapDuration = gapEnd.timeIntervalSince(gapStart)
                
                if gapDuration >= TimeInterval(duration) && gapStart >= now {
                    freeWindows.append((start: gapStart, end: gapEnd))
                }
            }
            currentTime = max(currentTime, event.endDate)
        }
        
        // Check remaining time until end of work day
        if currentTime < endOfWorkDay {
            let remainingDuration = endOfWorkDay.timeIntervalSince(currentTime)
            if remainingDuration >= TimeInterval(duration) {
                freeWindows.append((start: currentTime, end: endOfWorkDay))
            }
        }
        
        return freeWindows
    }
    
    func createFocusBlock(startTime: Date, endTime: Date, title: String = "Focus Time") {
        guard isAuthorized else { return }
        
        let event = EKEvent(eventStore: eventStore)
        event.title = title
        event.startDate = startTime
        event.endDate = endTime
        event.calendar = eventStore.defaultCalendarForNewEvents
        event.notes = "Created by FocusTimer"
        event.isAllDay = false
        
        // Add alert 5 minutes before
        let alarm = EKAlarm(relativeOffset: -5 * 60)
        event.addAlarm(alarm)
        
        do {
            try eventStore.save(event, span: .thisEvent)
        } catch {
            print("Failed to save calendar event: \(error)")
        }
    }
    
    func deleteEvent(withId id: String) {
        guard isAuthorized else { return }
        
        if let event = eventStore.event(withIdentifier: id) {
            do {
                try eventStore.remove(event, span: .thisEvent)
            } catch {
                print("Failed to delete calendar event: \(error)")
            }
        }
    }
    
    func getNextFreeWindow(duration: Int = 25 * 60) -> (start: Date, end: Date)? {
        let windows = findFreeWindows(duration: duration)
        return windows.first
    }
}
