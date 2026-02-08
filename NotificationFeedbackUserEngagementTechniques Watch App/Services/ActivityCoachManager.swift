//
//  ActivityCoachManager.swift
//  NotificationFeedbackUserEngagementTechniques
//
//  Created by Nar Rasaily on 2/8/26.
//
import Foundation
import CoreMotion
import UserNotifications
import WatchKit
import Combine

/// Manages activity coaching with smart notifications and feedback
class ActivityCoachManager: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var currentActivity: Activity = .unknown
    @Published var steps: Int = 0
    @Published var stepGoal: Int = 10000
    @Published var inactivityMinutes: Int = 0
    @Published var isMonitoring = false
    @Published var lastMilestone: Int = 0
    @Published var showCelebration = false
    
    // MARK: - Settings
    
    @Published var inactivityAlertMinutes: Int = 30
    @Published var notificationsEnabled = false
    
    // MARK: - Private Properties
    
    private let motionManager = CMMotionManager()
    private let activityManager = CMMotionActivityManager()
    private let pedometer = CMPedometer()
    private var inactivityTimer: Timer?
    private var stationaryStartTime: Date?
    private let milestones = [25, 50, 75, 100]
    
    // MARK: - Computed Properties
    
    var stepProgress: Double {
        Double(steps) / Double(stepGoal)
    }
    
    var stepProgressPercent: Int {
        Int(stepProgress * 100)
    }
    
    var pollInterval: TimeInterval {
        switch currentActivity {
        case .stationary: return 30.0
        case .walking: return 5.0
        case .running: return 1.0
        default: return 10.0
        }
    }
    
    // MARK: - Initialization
    
    init() {
        motionManager.accelerometerUpdateInterval = 10.0
    }
    
    // MARK: - Permissions
    
    func requestPermissions() async {
        // Notification permission
        let center = UNUserNotificationCenter.current()
        do {
            notificationsEnabled = try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            notificationsEnabled = false
        }
    }
    
    // MARK: - Monitoring
    
    func startMonitoring() {
        guard !isMonitoring else { return }
        
        startActivityMonitoring()
        startPedometerUpdates()
        startInactivityTimer()
        
        isMonitoring = true
        WKInterfaceDevice.current().play(.start)
    }
    
    func stopMonitoring() {
        activityManager.stopActivityUpdates()
        pedometer.stopUpdates()
        inactivityTimer?.invalidate()
        motionManager.stopAccelerometerUpdates()
        
        isMonitoring = false
        WKInterfaceDevice.current().play(.stop)
    }
    
    // MARK: - Activity Monitoring
    
    private func startActivityMonitoring() {
        guard CMMotionActivityManager.isActivityAvailable() else { return }
        
        activityManager.startActivityUpdates(to: .main) { [weak self] activity in
            guard let self = self, let activity = activity else { return }
            
            let newActivity: Activity
            if activity.running {
                newActivity = .running
            } else if activity.walking {
                newActivity = .walking
            } else if activity.stationary {
                newActivity = .stationary
            } else {
                newActivity = .unknown
            }
            
            // Check if becoming stationary
            if newActivity == .stationary && self.currentActivity != .stationary {
                self.stationaryStartTime = Date()
            } else if newActivity != .stationary {
                self.stationaryStartTime = nil
                self.inactivityMinutes = 0
            }
            
            self.currentActivity = newActivity
            self.updatePollingRate()
        }
    }
    
    private func startPedometerUpdates() {
        guard CMPedometer.isStepCountingAvailable() else { return }
        
        let startOfDay = Calendar.current.startOfDay(for: Date())
        
        pedometer.startUpdates(from: startOfDay) { [weak self] data, error in
            guard let self = self, let data = data else { return }
            
            DispatchQueue.main.async {
                let newSteps = Int(truncating: data.numberOfSteps)
                let oldProgress = self.stepProgressPercent
                self.steps = newSteps
                let newProgress = self.stepProgressPercent
                
                // Check for milestone
                self.checkMilestones(oldProgress: oldProgress, newProgress: newProgress)
            }
        }
    }
    
    // MARK: - Inactivity Tracking
    
    private func startInactivityTimer() {
        inactivityTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.checkInactivity()
        }
    }
    
    private func checkInactivity() {
        guard let startTime = stationaryStartTime else { return }
        
        let minutes = Int(Date().timeIntervalSince(startTime) / 60)
        inactivityMinutes = minutes
        
        if minutes >= inactivityAlertMinutes && minutes % inactivityAlertMinutes == 0 {
            sendInactivityReminder()
        }
    }
    
    // MARK: - Adaptive Polling
    
    private func updatePollingRate() {
        motionManager.accelerometerUpdateInterval = pollInterval
    }
    
    // MARK: - Milestone Tracking
    
    private func checkMilestones(oldProgress: Int, newProgress: Int) {
        for milestone in milestones {
            if newProgress >= milestone && oldProgress < milestone && lastMilestone < milestone {
                lastMilestone = milestone
                celebrateMilestone(milestone)
                break
            }
        }
    }
    
    private func celebrateMilestone(_ milestone: Int) {
        // Haptic feedback
        let device = WKInterfaceDevice.current()
        
        if milestone == 100 {
            // Big celebration for goal completion
            device.play(.success)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                device.play(.success)
            }
        } else {
            device.play(.notification)
        }
        
        // Visual celebration
        showCelebration = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.showCelebration = false
        }
        
        // Notification
        if notificationsEnabled {
            sendMilestoneNotification(milestone)
        }
    }
    
    // MARK: - Notifications
    
    private func sendMilestoneNotification(_ milestone: Int) {
        let content = UNMutableNotificationContent()
        
        if milestone == 100 {
            content.title = "🎉 Goal Complete!"
            content.body = "Amazing! You've reached your \(stepGoal) step goal!"
        } else {
            content.title = "👟 \(milestone)% Complete!"
            content.body = "You're \(milestone)% to your step goal. Keep going!"
        }
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: "milestone-\(milestone)",
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    private func sendInactivityReminder() {
        guard notificationsEnabled else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "🪑 Time to Move!"
        content.body = "You've been sitting for \(inactivityMinutes) minutes. A short walk would do you good!"
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: "inactivity-\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request)
        WKInterfaceDevice.current().play(.notification)
    }
    
    // MARK: - Reset
    
    func resetDaily() {
        steps = 0
        lastMilestone = 0
        inactivityMinutes = 0
        stationaryStartTime = nil
    }
}

// MARK: - Activity Enum

enum Activity: String {
    case stationary = "Stationary"
    case walking = "Walking"
    case running = "Running"
    case unknown = "Unknown"
    
    var icon: String {
        switch self {
        case .stationary: return "figure.stand"
        case .walking: return "figure.walk"
        case .running: return "figure.run"
        case .unknown: return "questionmark"
        }
    }
    
    var color: String {
        switch self {
        case .stationary: return "blue"
        case .walking: return "green"
        case .running: return "orange"
        case .unknown: return "gray"
        }
    }
}

