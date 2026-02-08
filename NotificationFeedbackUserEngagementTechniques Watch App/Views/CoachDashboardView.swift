//
//  CoachDashboardView.swift
//  NotificationFeedbackUserEngagementTechniques
//
//  Created by Nar Rasaily on 2/8/26.
//

import SwiftUI

/// Main coaching dashboard view
struct CoachDashboardView: View {
    @ObservedObject var manager: ActivityCoachManager
    
    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                // Step progress ring
                StepProgressView(
                    steps: manager.steps,
                    goal: manager.stepGoal,
                    progress: manager.stepProgress,
                    showCelebration: manager.showCelebration
                )
                
                // Current activity
                ActivityStatusCard(
                    activity: manager.currentActivity,
                    inactivityMinutes: manager.inactivityMinutes,
                    alertThreshold: manager.inactivityAlertMinutes
                )
                
                // Controls
                MonitoringControls(manager: manager)
            }
            .padding(.horizontal)
        }
        .navigationTitle("Coach")
    }
}

/// Step progress with animated ring
struct StepProgressView: View {
    let steps: Int
    let goal: Int
    let progress: Double
    let showCelebration: Bool
    
    @State private var animatedProgress: Double = 0
    
    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(Color.green.opacity(0.3), lineWidth: 12)
                .frame(width: 100, height: 100)
            
            // Progress ring
            Circle()
                .trim(from: 0, to: min(animatedProgress, 1.0))
                .stroke(Color.green, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                .frame(width: 100, height: 100)
                .rotationEffect(.degrees(-90))
            
            // Content
            VStack(spacing: 2) {
                Text("\(steps)")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.green)
                
                Text("/ \(goal)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            
            // Celebration overlay
            if showCelebration {
                CelebrationOverlay()
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.0)) {
                animatedProgress = progress
            }
        }
        .onChange(of: progress) { _, newValue in
            withAnimation(.easeOut(duration: 0.5)) {
                animatedProgress = newValue
            }
        }
    }
}

/// Celebration animation overlay
struct CelebrationOverlay: View {
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 1.0
    
    var body: some View {
        Text("🎉")
            .font(.system(size: 40))
            .scaleEffect(scale)
            .opacity(opacity)
            .onAppear {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                    scale = 1.5
                }
                withAnimation(.easeOut(duration: 1.5).delay(0.5)) {
                    opacity = 0
                }
            }
    }
}

/// Current activity status card
struct ActivityStatusCard: View {
    let activity: Activity
    let inactivityMinutes: Int
    let alertThreshold: Int
    
    private var activityColor: Color {
        switch activity {
        case .stationary: return .blue
        case .walking: return .green
        case .running: return .orange
        case .unknown: return .gray
        }
    }
    
    private var showInactivityWarning: Bool {
        activity == .stationary && inactivityMinutes >= alertThreshold / 2
    }
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: activity.icon)
                    .font(.title3)
                    .foregroundStyle(activityColor)
                
                Text(activity.rawValue)
                    .font(.caption)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            if activity == .stationary && inactivityMinutes > 0 {
                HStack {
                    Image(systemName: showInactivityWarning ? "exclamationmark.triangle.fill" : "clock")
                        .font(.caption)
                        .foregroundStyle(showInactivityWarning ? .orange : .secondary)
                    
                    Text("Sitting for \(inactivityMinutes) min")
                        .font(.caption2)
                        .foregroundStyle(showInactivityWarning ? .orange : .secondary)
                    
                    Spacer()
                }
            }
        }
        .padding()
        .background(activityColor.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

/// Monitoring control buttons
struct MonitoringControls: View {
    @ObservedObject var manager: ActivityCoachManager
    
    var body: some View {
        Button(action: {
            if manager.isMonitoring {
                manager.stopMonitoring()
            } else {
                manager.startMonitoring()
            }
        }) {
            HStack {
                Image(systemName: manager.isMonitoring ? "stop.fill" : "play.fill")
                Text(manager.isMonitoring ? "Stop" : "Start")
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .tint(manager.isMonitoring ? .red : .green)
    }
}

#Preview {
    CoachDashboardView(manager: ActivityCoachManager())
}

