//
//  HealthIntegration.swift
//  FocusTimer
//

import Foundation
import Combine
import HealthKit

// MARK: - Health Integration Manager

class HealthIntegration: ObservableObject {
    static let shared = HealthIntegration()
    
    @Published var isAuthorized: Bool = false
    @Published var todaySteps: Int = 0
    @Published var todaySleepHours: Double = 0.0
    @Published var sleepFocusCorrelation: Double = 0.0
    
    private let healthStore = HKHealthStore()
    private let dataManager = FocusDataManager.shared
    
    var isHealthKitAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }
    
    func requestAuthorization() {
        guard isHealthKitAvailable else { return }
        
        let typesToRead: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        ]
        
        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { [weak self] success, error in
            DispatchQueue.main.async {
                self?.isAuthorized = success
                if success {
                    self?.fetchTodayData()
                }
            }
        }
    }
    
    func fetchTodayData() {
        fetchTodaySteps()
        fetchTodaySleep()
    }
    
    private func fetchTodaySteps() {
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let startOfDay = Calendar.current.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: Date(), options: .strictStartDate)
        
        let query = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: predicate, options: .cumulativeSum) { [weak self] _, result, _ in
            guard let result = result, let sum = result.sumQuantity() else { return }
            let steps = Int(sum.doubleValue(for: HKUnit.count()))
            DispatchQueue.main.async {
                self?.todaySteps = steps
            }
        }
        
        healthStore.execute(query)
    }
    
    private func fetchTodaySleep() {
        let sleepType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis)!
        let startOfDay = Calendar.current.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay.addingTimeInterval(-12*3600), end: Date(), options: .strictStartDate)
        
        let query = HKSampleQuery(sampleType: sleepType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { [weak self] _, samples, _ in
            guard let samples = samples as? [HKCategorySample] else { return }
            
            var totalSleepSeconds: Double = 0
            for sample in samples {
                if sample.value == HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue ||
                   sample.value == HKCategoryValueSleepAnalysis.asleepCore.rawValue ||
                   sample.value == HKCategoryValueSleepAnalysis.asleepDeep.rawValue ||
                   sample.value == HKCategoryValueSleepAnalysis.asleepREM.rawValue {
                    totalSleepSeconds += sample.endDate.timeIntervalSince(sample.startDate)
                }
            }
            
            let hours = totalSleepSeconds / 3600
            DispatchQueue.main.async {
                self?.todaySleepHours = hours
            }
        }
        
        healthStore.execute(query)
    }
    
    func logFocusMinutesToHealth(_ minutes: Int) {
        // This would log focus activity to Apple Health
        // Implementation depends on HealthKit permissions
    }
    
    func analyzeCorrelation() -> Double {
        // Simple correlation: if sleep > 7 hours, focus tends to be better
        // Returns correlation factor between -1 and 1
        if todaySleepHours >= 7 {
            return 0.3 // Positive correlation with good sleep
        } else if todaySleepHours < 5 {
            return -0.2 // Negative correlation with poor sleep
        }
        return 0.0
    }
    
    func getHealthTip() -> String? {
        if todaySteps < 5000 {
            return "You've only taken \(todaySteps) steps today. A short walk could improve your focus."
        }
        
        if todaySleepHours < 6 {
            return "Only \(String(format: "%.1f", todaySleepHours)) hours of sleep? That's below recommended - focus may suffer."
        }
        
        if todaySleepHours >= 8 && todaySteps > 10000 {
            return "Great sleep AND movement today! You're set up for excellent focus."
        }
        
        return nil
    }
}
